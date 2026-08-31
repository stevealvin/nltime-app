// 生成 assets/js/node_shim.js v2：内联标准 buffer polyfill + blueimp-md5
const fs = require('fs');
const path = require('path');

const base = 'C:/zz/z-custom/app/nltime/assets/js';
const read = (f) => fs.readFileSync(path.join(base, f), 'utf-8');

const base64Src = read('base64-js.min.js');
const ieeeSrc = read('ieee754.min.js');
const bufferSrc = read('buffer.min.js');
const cryptoJsSrc = read('crypto-js.min.js');

// md5 源码是 UMD：找它导出 md5 的方式
// blueimp-md5: (function (factory) { if (typeof define === 'function' && define.amd) {...} else if (typeof module === 'object') { module.exports = factory(); } else { ... } }(function () { return md5; }));

const shim = `/* ============================================================
 * node_shim.js v2 — 生成文件（勿手改）
 * cliguard 签名所需 Node API 的纯 JS 实现（flutter_js/QuickJS）
 * 内联：base64-js / ieee754 / buffer(6.0.3) / blueimp-md5
 * 依赖：globalThis.__pako（Dart 侧先加载 pako 后设置）
 * ============================================================ */
(function () {
  'use strict';
  var G = typeof globalThis !== 'undefined' ? globalThis : this;
  var __mods = (G.__mods = G.__mods || {});

  G.require = function (name) {
    var m = __mods[String(name).replace(/^node:/, '')];
    if (m === undefined || m === null) throw new Error("Cannot find module '" + name + "'");
    return m;
  };
  G.module = { exports: {} };
  G.exports = G.module.exports;

  // ==================== base64-js ====================
  (function (exports) {
    /*__BASE64_SRC__*/
  })(__mods['base64-js'] = {});

  // ==================== ieee754 ====================
  (function (exports) {
    /*__IEEE754_SRC__*/
  })(__mods['ieee754'] = {});

  // ==================== buffer polyfill (6.0.3) ====================
  (function () {
    /*__BUFFER_SRC__*/
    __mods['buffer'] = G.exports;
  })();
  G.Buffer = __mods['buffer'] && __mods['buffer'].Buffer ? __mods['buffer'].Buffer : __mods['buffer'];
  // 兼容：concat 允许 Uint8Array / 字符串混合
  (function () {
    var origConcat = G.Buffer.concat;
    if (typeof origConcat === 'function') {
      G.Buffer.concat = function (list) {
        var arr = [], i, it;
        for (i = 0; i < list.length; i++) {
          it = list[i];
          if (it instanceof G.Buffer) arr.push(it);
          else if (it instanceof Uint8Array) arr.push(G.Buffer.from(it));
          else arr.push(G.Buffer.from(String(it)));
        }
        return origConcat.call(this, arr);
      };
    }
  })();

  // ==================== crypto-js ====================
  (function () {
    /*__CRYPTOJS_SRC__*/
    __mods['crypto-js'] = G.module.exports || G.exports;
  })();

  // ==================== crypto（基于 crypto-js） ====================
  function _bytesToU8(v) { return v instanceof Uint8Array ? v : G.Buffer.from(v); }
  function _u8ToBytesWA(u8) { return _CJ().lib.WordArray.create(u8); }
  function _waToU8(wa) {
    var words = wa.words, sig = wa.sigBytes, out = new Uint8Array(sig);
    for (var i = 0; i < sig; i++) out[i] = (words[i >>> 2] >>> ((3 - (i % 4)) * 8)) & 0xff;
    return out;
  }
  var _cjCached = null;
  function _CJ() {
    if (!_cjCached) _cjCached = __mods['crypto-js'];
    return _cjCached;
  }
  var crypto = {
    createHash: function (algo) {
      var parts = [];
      var alg = String(algo).toLowerCase();
      return {
        update: function (d) {
          if (d instanceof Uint8Array) parts.push(_u8ToStr(d));
          else parts.push(String(d));
          return this;
        },
        digest: function (enc) {
          var str = parts.join('');
          var CJ = _CJ();
          var hex;
          if (alg === 'md5') hex = CJ.MD5(str).toString();
          else if (alg === 'sha1') hex = CJ.SHA1(str).toString();
          else if (alg === 'sha256') hex = CJ.SHA256(str).toString();
          else throw new Error('Unsupported hash: ' + algo);
          if (enc === 'hex') return hex;
          return G.Buffer.from(hex, 'hex');
        }
      };
    },
    createHmac: function (algo, key) {
      var parts = [];
      var alg = String(algo).toLowerCase();
      var keyBytes = _bytesToU8(key);
      return {
        update: function (d) { parts.push(d instanceof Uint8Array ? _u8ToStr(d) : String(d)); return this; },
        digest: function (enc) {
          var CJ = _CJ();
          var hex;
          if (alg === 'md5') hex = CJ.HmacMD5(parts.join(''), _u8ToStr(keyBytes)).toString();
          else if (alg === 'sha1') hex = CJ.HmacSHA1(parts.join(''), _u8ToStr(keyBytes)).toString();
          else if (alg === 'sha256') hex = CJ.HmacSHA256(parts.join(''), _u8ToStr(keyBytes)).toString();
          else throw new Error('Unsupported hmac: ' + algo);
          if (enc === 'hex') return hex;
          return G.Buffer.from(hex, 'hex');
        }
      };
    },
    createCipheriv: function (algo, key, iv) {
      var parts = [];
      var alg = String(algo).toLowerCase();
      return {
        update: function (d) { parts.push(_bytesToU8(d)); return this; },
        final: function () {
          var total = 0, i;
          for (i = 0; i < parts.length; i++) total += parts[i].length;
          var plain = new Uint8Array(total), pos = 0;
          for (i = 0; i < parts.length; i++) { plain.set(parts[i], pos); pos += parts[i].length; }
          var CJ = _CJ();
          var enc;
          if (alg === 'aes-128-cbc') {
            enc = CJ.AES.encrypt(_u8ToBytesWA(plain), _u8ToBytesWA(key), {
              iv: _u8ToBytesWA(iv), mode: CJ.mode.CBC, padding: CJ.pad.Pkcs7
            });
          } else {
            throw new Error('Unsupported cipher: ' + algo);
          }
          return G.Buffer.from(_waToU8(enc.ciphertext));
        }
      };
    },
    randomBytes: function (n) {
      var out = new Uint8Array(n);
      for (var i = 0; i < n; i++) out[i] = Math.floor(Math.random() * 256);
      return G.Buffer.from(out);
    }
  };

  // ==================== 工具（供 update 用） ====================
  function _u8ToStr(u8) {
    var s = '';
    for (var i = 0; i < u8.length; i++) s += String.fromCharCode(u8[i]);
    try { return decodeURIComponent(escape(s)); } catch (e) { return s; }
  }

  // ==================== zlib（pako） ====================
  var zlib = {
    gzipSync: function (data) {
      var pakoLib = G.__pako;
      var u8 = data instanceof Uint8Array ? data : G.Buffer.from(data);
      return G.Buffer.from(pakoLib.gzip(u8));
    }
  };

  // ==================== fs（内存版） ====================
  var __mem = G.__mem || (G.__mem = {});
  var fs = {
    readFileSync: function (p) { if (__mem[p] !== undefined) return __mem[p]; throw new Error('ENOENT: ' + p); },
    writeFileSync: function (p, d) { __mem[p] = String(d); },
    existsSync: function (p) { return __mem[p] !== undefined; },
    mkdirSync: function () {},
    readdirSync: function () { return []; },
    statSync: function () { return { isFile: function () { return true; }, size: 1 }; },
    openSync: function () { return 1; },
    writeSync: function () {},
    closeSync: function () {},
    renameSync: function (a, b) { if (__mem[a] !== undefined) { __mem[b] = __mem[a]; delete __mem[a]; } },
    unlinkSync: function (p) { delete __mem[p]; }
  };

  // ==================== os ====================
  var __HOMEDIR = G.__homedir || '/data/user/0/com.nl.omniflow';
  var os = {
    homedir: function () { return __HOMEDIR; },
    hostname: function () { return 'android'; },
    platform: function () { return 'android'; },
    arch: function () { return 'arm64'; },
    release: function () { return '14'; },
    cpus: function () { var r = []; for (var i = 0; i < 8; i++) r.push({ model: 'ARMv8', speed: 2000 }); return r; },
    totalmem: function () { return 8000000000; },
    uptime: function () { return 3600; },
    userInfo: function () { return { username: 'u0_a1', uid: 10101, gid: 10101, shell: null, homedir: __HOMEDIR }; },
    networkInterfaces: function () { return { wlan0: [{ address: '192.168.1.100', family: 'IPv4' }] }; }
  };

  // ==================== path ====================
  var path = {
    join: function () { var a = []; for (var i = 0; i < arguments.length; i++) if (arguments[i]) a.push(String(arguments[i])); return a.join('/').replace(/\\/+/g, '/'); },
    dirname: function (p) { p = String(p); var i = p.lastIndexOf('/'); return i < 0 ? '.' : (i === 0 ? '/' : p.substring(0, i)); },
    resolve: function () { var a = []; for (var i = 0; i < arguments.length; i++) a.push(String(arguments[i])); return a.join('/').replace(/\\/+/g, '/'); },
    basename: function (p) { p = String(p); return p.substring(p.lastIndexOf('/') + 1); }
  };

  // ==================== child_process ====================
  var child_process = {
    execSync: function () { throw new Error('ENOENT: child_process not available on mobile'); },
    exec: function () { throw new Error('ENOENT: child_process not available on mobile'); },
    spawn: function () { throw new Error('ENOENT: child_process not available on mobile'); }
  };

  // ==================== process ====================
  if (!G.process) {
    G.process = {
      platform: 'android',
      arch: 'arm64',
      version: 'v20.0.0',
      versions: { node: '20.0.0' },
      argv: ['node', 'pt-passport'],
      env: {},
      cwd: function () { return '/'; },
      hrtime: (function () {
        var f = function () { return [0, Date.now() * 1000]; };
        f.bigint = function () { return BigInt(Date.now()) * 1000000n; };
        return f;
      })(),
      uptime: function () { return 3600; },
      pid: 10001,
      title: 'nltime',
      exit: function () {},
      nextTick: function (fn) { setTimeout(fn, 0); },
      stdout: { write: function () { return true; }, isTTY: false },
      stderr: { write: function () { return true; } }
    };
  }

  // ==================== URL / URLSearchParams ====================
  if (typeof G.URL === 'undefined') {
    function URLSearchParamsP(init) {
      this._map = {};
      if (typeof init === 'string') {
        var q = init.replace(/^\\?/, '');
        if (q) { var pairs = q.split('&'); for (var i = 0; i < pairs.length; i++) { var kv = pairs[i].split('='); var k = decodeURIComponent(kv[0]); var v = kv.length > 1 ? decodeURIComponent(kv[1]) : ''; (this._map[k] = this._map[k] || []).push(v); } }
      }
    }
    URLSearchParamsP.prototype = {
      get: function (k) { return this._map[k] ? this._map[k][0] : null; },
      getAll: function (k) { return this._map[k] || []; },
      has: function (k) { return !!this._map[k]; },
      append: function (k, v) { (this._map[k] = this._map[k] || []).push(String(v)); },
      set: function (k, v) { this._map[k] = [String(v)]; },
      toString: function () { var parts = []; for (var k in this._map) for (var i = 0; i < this._map[k].length; i++) parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(this._map[k][i])); return parts.join('&'); }
    };
    G.URLSearchParams = URLSearchParamsP;
    function URLP(url) {
      url = String(url);
      var m = url.match(/^(https?):\\/\\/([^/?#]+)([^?#]*)(\\?[^#]*)?(#.*)?$/);
      if (!m) throw new TypeError('Invalid URL');
      this.protocol = m[1] + ':';
      this.host = m[2];
      this.hostname = m[2].split(':')[0];
      this.port = m[2].includes(':') ? m[2].split(':')[1] : '';
      this.pathname = m[3] || '/';
      this.search = m[4] || '';
      this.hash = m[5] || '';
      this.searchParams = new URLSearchParamsP(this.search);
      Object.defineProperty(this, 'href', { get: function () { return this.protocol + '//' + this.host + this.pathname + this.search + this.hash; } });
    }
    G.URL = URLP;
  }

  // ==================== 注册模块 ====================
  __mods['crypto'] = crypto;
  __mods['zlib'] = zlib;
  __mods['fs'] = fs;
  __mods['os'] = os;
  __mods['path'] = path;
  __mods['child_process'] = child_process;

  G.module = { exports: {} };
  G.exports = G.module.exports;
  G.__shimReady = true;
})();
`;

// 内联依赖源码
function inline(target, marker, src) {
  return target.replace(marker, src);
}
let out = shim;
out = inline(out, '/*__BASE64_SRC__*/', base64Src);
out = inline(out, '/*__IEEE754_SRC__*/', ieeeSrc);
out = inline(out, '/*__BUFFER_SRC__*/', bufferSrc);
out = inline(out, '/*__CRYPTOJS_SRC__*/', cryptoJsSrc);

fs.writeFileSync(path.join(base, 'node_shim.js'), out, 'utf-8');
console.log('node_shim.js v2 生成完成:', out.length, '字节');
