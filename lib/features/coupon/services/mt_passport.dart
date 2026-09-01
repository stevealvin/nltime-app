import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as dcrypto;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coupon_model.dart';

/// 美团登录/领券的 flutter_js 实现。
///
/// 架构（无需 Rust / 无需服务器）：
/// - 登录：Dart http 直连 passport.meituan.com 两个接口（get-code / check）
/// - 签名：flutter_js 跑 cliguard 1.4.2（node_shim 提供 Node API 纯 JS 实现）
/// - 领券：Dart http 直连 sendCouponWork + mtgsig
class MtPassport {
  static JavascriptRuntime? _runtime;
  static bool _initialized = false;

  static String? _cliguardInfoPath;
  static String _resolvedPackageName = 'com.nl.omniflow';

  static const String clientId = 'c6f50b5a1e2f4e2bb00a3e2f58df3ced';
  static const String csecPlatform = '7';
  static const String csecVersion = '1.4.2';

  /// 与 Node 版保持一致
  static const String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const String _codeApi = 'https://passport.meituan.com/api/account/userauth/code';
  static const String _checkApi = 'https://passport.meituan.com/api/account/userauth/check';

  /// 设备指纹（dfpid）持久化 key
  static const String prefsKeyDfpid = 'mt_dfpid_info';

  // 登录中间状态（get-code → poll-token 之间）
  static String _pkceVerifier = '';
  static String _authCode = '';

  static bool get isReady => _initialized && _runtime != null;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final info = await PackageInfo.fromPlatform();
      if (info.packageName.isNotEmpty) {
        _resolvedPackageName = info.packageName;
      }
    } catch (_) {}

    _runtime = getJavascriptRuntime();

    final home = '/data/user/0/$_resolvedPackageName';
    _runtime!.evaluate('globalThis.__packageName = ${jsonEncode(_resolvedPackageName)}; globalThis.__homedir = ${jsonEncode(home)};');

    // 1. node_shim（Node API 纯 JS 实现 + Buffer/MD5/AES 内联）
    _runtime!.evaluate(await rootBundle.loadString('assets/js/node_shim.js'));

    // 2. pako（gzip）
    _evalCjs(await rootBundle.loadString('assets/js/pako.min.js'));
    _runtime!.evaluate('globalThis.__pako = globalThis.exports;');

    // 3. 注入已保存的设备指纹（dfpid），实现设备身份继承
    await _injectDeviceFingerprint();

    // 4. cliguard 1.4.2（签名核心）
    _evalCjs(await rootBundle.loadString('assets/js/cliguard.js'));
    _runtime!.evaluate('globalThis.__cliguard = globalThis.module.exports;');
    _runtime!.evaluate('globalThis.module={exports:{}};globalThis.exports=globalThis.module.exports;');

    _initialized = true;
  }

  static void _evalCjs(String src) {
    _runtime!.evaluate('globalThis.module={exports:{}};globalThis.exports=globalThis.module.exports;');
    _runtime!.evaluate(src);
  }

  // ── 签名 ─────────────────────────────────────────────────

  /// 生成带签名的请求头（含 mtgsig）
  static Future<Map<String, String>> buildHeaders(
    String url,
    String bodyStr, {
    String? token,
  }) async {
    final bytes = utf8.encode(bodyStr);
    final slice = bytes.length > 16200 ? bytes.sublist(0, 16200) : bytes;
    final bodyHash = dcrypto.md5.convert(slice).toString();

    final signedUrl = await _addCommonParams(url);
    final sigHeaders = await _signRequest('GET', signedUrl, bodyHash);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Content-Length': '${bytes.length}',
      'User-Agent': userAgent,
      'Cache-Control': 'no-cache',
      'Accept': 'application/json, */*',
    };
    headers.addAll(sigHeaders);
    if (token != null && token.isNotEmpty) {
      headers['token'] = token;
    }
    return headers;
  }

  /// cliguard.addCommonParams：追加 csecplatform / csecversion
  static Future<String> _addCommonParams(String url) async {
    final r = _runtime;
    if (r == null) return url;
    try {
      final res = r.evaluate('''
        (function(){
          try {
            var cg = globalThis.__cliguard;
            var rr = cg.addCommonParams(${jsonEncode(url)});
            return (rr && rr.url) ? rr.url : '';
          } catch(e) { return ''; }
        })()
      ''');
      final v = res.stringResult.trim();
      return v.isEmpty ? url : v;
    } catch (_) {
      return url;
    }
  }

  /// cliguard.signRequest：生成 mtgsig 等签名头
  static Future<Map<String, String>> _signRequest(
    String method,
    String url,
    String bodyHash,
  ) async {
    final r = _runtime;
    if (r == null) return const {};
    try {
      final res = r.evaluate('''
        (function(){
          try {
            var cg = globalThis.__cliguard;
            var rr = cg.signRequest(${jsonEncode(method)}, ${jsonEncode(url)}, ${jsonEncode(bodyHash)});
            return JSON.stringify(rr || {});
          } catch(e) { return '{}'; }
        })()
      ''');
      final decoded = tryDecodeJson(res.stringResult);
      if (decoded == null) return const {};
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return const {};
    }
  }

  // ── 登录（Dart 直连） ────────────────────────────────────

  /// 第一步：获取登录二维码
  static Future<AuthCodeResult> getAuthCode() async {
    try {
      await init();
      _pkceVerifier = _randomHex(32); // 64 hex
      final challenge =
          dcrypto.sha256.convert(utf8.encode(_pkceVerifier)).toString();

      final url = '$_codeApi'
          '?client_id=$clientId'
          '&code_challenge=$challenge'
          '&csecplatform=$csecPlatform'
          '&csecversion=$csecVersion';
      final headers = await buildHeaders(url, '');

      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 20));

      final decoded = tryDecodeJson(res.body);
      final data = decoded?['data'];
      if (data is Map) {
        _authCode = (data['authCode'] as String?) ?? '';
        final link = (data['shortLink'] as String?) ?? '';
        if (link.isNotEmpty) {
          return AuthCodeResult(ok: true, qrCodeUrl: link);
        }
      }
      return AuthCodeResult(
        ok: false,
        message: decoded?['message'] as String? ?? '获取二维码失败',
      );
    } catch (e) {
      return AuthCodeResult(ok: false, message: '获取二维码失败：$e');
    }
  }

  /// 第二步：轮询扫码结果，返回 token
  static Future<PollResult> pollToken({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final url = '$_checkApi'
            '?client_id=$clientId'
            '&auth_code=$_authCode'
            '&code_verifier=$_pkceVerifier'
            '&csecplatform=$csecPlatform'
            '&csecversion=$csecVersion';
        final headers = await buildHeaders(url, '');

        final res = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 15));

        final decoded = tryDecodeJson(res.body);
        final data = decoded?['data'];
        if (data is Map) {
          final status = data['authStatus'];
          final token = data['token'] as String?;
          if (token != null && token.isNotEmpty) {
            await _persistDeviceFingerprint();
            return PollResult(ok: true, token: token);
          }
          // authStatus: 1=等待扫码；其他=进行中或成功
          if (status != 1) {
            // 尝试从 authCode 之外的字段找 token
            final token2 = data['accessToken'] as String? ??
                data['userToken'] as String?;
            if (token2 != null && token2.isNotEmpty) {
              return PollResult(ok: true, token: token2);
            }
          }
        }
      } catch (_) {
        // 网络抖动继续轮询
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return const PollResult(ok: false, message: '等待扫码超时，请重新生成二维码');
  }

  // ── 设备指纹（dfpid） ────────────────────────────────────

  static String get _infoPath {
    if (_cliguardInfoPath != null) return _cliguardInfoPath!;
    final home = '/data/user/0/$_resolvedPackageName';
    _cliguardInfoPath = '$home/.cliguard/cliguard-info.json';
    return _cliguardInfoPath!;
  }

  /// 注入已保存的设备指纹，让 cliguard 读到预设 dfpid
  static Future<void> _injectDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKeyDfpid);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      _runtime!.evaluate(
          'globalThis.__mem[${jsonEncode(_infoPath)}] = ${jsonEncode(raw)};');
      // ignore: avoid_print
      print('[MtPassport] dfpid 注入: ${decoded.containsKey('dfpid')}');
    } catch (_) {
      // 注入失败不阻断，退化为首次生成
    }
  }

  /// 读取 cliguard 生成的设备指纹并持久化
  static Future<void> _persistDeviceFingerprint() async {
    try {
      final res = _runtime!.evaluate(
          'globalThis.__mem[${jsonEncode(_infoPath)}] || null');
      final raw = res.stringResult.trim();
      if (raw.isEmpty || raw == 'null') return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKeyDfpid, raw);
    } catch (_) {
      // 忽略
    }
  }

  /// 手动导入设备指纹 JSON（如从电脑 cliguard-info.json 复制）
  static Future<void> setDeviceFingerprintFromJson(String jsonSource) async {
    try {
      final decoded = jsonDecode(jsonSource);
      if (decoded is! Map<String, dynamic>) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKeyDfpid, jsonSource);
    } catch (e) {
      // ignore: avoid_print
      print('[MtPassport] dfpid 导入失败: $e');
    }
  }

  // ── 工具 ────────────────────────────────────────────────

  static String _randomHex(int bytes) {
    final rnd = Random.secure();
    final b = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<void> dispose() async {
    _runtime?.dispose();
    _runtime = null;
    _initialized = false;
  }
}
