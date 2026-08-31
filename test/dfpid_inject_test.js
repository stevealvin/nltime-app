// dfpid 注入逻辑验证 v2
// Node vm 无法泵送 async IIFE 的 Promise 链（跨上下文微任务卡死），
// 因此改为：1) 全文件语法检查  2) 提取 fs 包装段（纯同步逻辑）在 vm 中执行验证
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shimPath = path.join(__dirname, '..', 'assets', 'js', 'cjs_shim.js');
const shimSrc = fs.readFileSync(shimPath, 'utf-8');

// 1. 语法检查
try {
  new vm.Script(shimSrc, { filename: 'cjs_shim.js' });
  console.log('[1] cjs_shim.js 语法检查: OK');
} catch (e) {
  console.log('[1] cjs_shim.js 语法错误:', e.message);
  process.exit(1);
}

// 2. 提取 fs 包装段（从设备指纹注释到文件末尾的 return 之前）
const startMark = '// ── 设备指纹（dfpid）注入与持久化';
const startIdx = shimSrc.indexOf(startMark);
const endIdx = shimSrc.indexOf('return JSON.stringify({', startIdx);
if (startIdx < 0 || endIdx < 0) {
  console.log('[2] 无法定位 fs 包装段:', { startIdx, endIdx });
  process.exit(1);
}
const fsWrapSection = shimSrc.slice(startIdx, endIdx);
console.log('[2] 提取 fs 包装段: OK (' + fsWrapSection.length + ' chars)');

// 3. 在 vm 中模拟 fjs 环境执行 fs 包装段
const memFs = {};
const fakeFs = {
  readFileSync(p) { if (memFs[p]) return memFs[p]; throw new Error('ENOENT: ' + p); },
  writeFileSync(p, d) { memFs[p] = String(d); },
  existsSync(p) { return !!memFs[p]; },
};
const sandbox = {
  globalThis: null,
  console: { log() {}, error() {} },
  process: { stdout: { write() { return true; } } },
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
// 预置 shim 会创建的全局
vm.runInContext('globalThis.__mods = Object.create(null); globalThis.__mods["fs"] = ' + 'fakeFs;'.replace('fakeFs', 'globalThis.__fakeFs'), sandbox);
vm.runInContext('globalThis.__fakeFs = ' + '{};', sandbox);
// 直接把 fakeFs 注入
vm.runInContext('globalThis.__mods["fs"] = { readFileSync: function(p){ if (globalThis.__mem[p]) return globalThis.__mem[p]; throw new Error("ENOENT:"+p); }, writeFileSync: function(p,d){ globalThis.__mem[p]=String(d); }, existsSync: function(p){ return !!globalThis.__mem[p]; } }; globalThis.__mem = {};', sandbox);

// 执行 fs 包装段
try {
  vm.runInContext(fsWrapSection, sandbox, { timeout: 5000 });
  console.log('[3] fs 包装段执行: OK');
} catch (e) {
  console.log('[3] fs 包装段执行失败:', e.message);
  process.exit(1);
}

// 4. 场景测试
const run = (code) => vm.runInContext(code, sandbox);

// 场景1：无注入 → 写被拦截到 __dfpidPersisted
run("globalThis.__mods['fs'].writeFileSync('/f/.cliguard/cliguard-info.json', JSON.stringify({localid:'A',dfpid:'A',timestamp:1},null,2),'utf8');");
const p1 = run('globalThis.__dfpidPersisted');
const notWritten = run('!globalThis.__mem["/f/.cliguard/cliguard-info.json"]');
console.log('[4] 场景1 无注入:');
console.log('    写拦截 → __dfpidPersisted:', JSON.stringify(p1));
console.log('    真实 fs 未落盘:', notWritten);

// 场景2：注入电脑 dfpid → 读回注入值
run("globalThis.__dfpidOverride = {localid:'PC_LOCALID', dfpid:'618wPCDFPIDxxx', timestamp:1700000000000};");
const p2 = run("JSON.parse(globalThis.__mods['fs'].readFileSync('/f/.cliguard/cliguard-info.json','utf8')).dfpid");
const exists = run("globalThis.__mods['fs'].existsSync('/f/.cliguard/cliguard-info.json')");
console.log('[5] 场景2 注入 dfpid:');
console.log('    读回 dfpid:', p2, '| 存在检查:', exists);

// 场景3：无注入时读取不存在文件 → 应抛 ENOENT（不影响其他文件读写）
const otherRead = run("(function(){ try { globalThis.__mods['fs'].readFileSync('/f/other.txt','utf8'); return 'no-error'; } catch(e){ return e.message.slice(0,20); } })()");
console.log('[6] 场景3 其他文件不受影响:', otherRead);

console.log('');
const ok = JSON.stringify(p1).includes('dfpid') && p2 === '618wPCDFPIDxxx' && notWritten && otherRead.includes('ENOENT');
console.log(ok ? '✅ dfpid 注入逻辑全部验证通过' : '❌ 部分验证失败');
process.exit(ok ? 0 : 1);
