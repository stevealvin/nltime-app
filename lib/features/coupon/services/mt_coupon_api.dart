import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/coupon_model.dart';
import 'mt_passport.dart';

/// 美团领券接口封装，与 Node 版 issueCoupon / checkLoginStatus 保持一致。
class MtCouponApi {
  static const String _couponUrl =
      'https://media.meituan.com/fulishemini/couponActivity/sendCouponWork';
  static const String _checkLoginUrl =
      'https://click.meituan.com/cps/ai/product/checkLoginMtMiniProgram';

  static String? _aiScene;

  static Future<String> loadAiScene() async {
    if (_aiScene != null) return _aiScene!;
    try {
      final raw = await rootBundle.loadString('assets/config.json');
      final decoded = jsonDecode(raw);
      _aiScene = (decoded is Map && decoded['aiScene'] is String)
          ? decoded['aiScene'] as String
          : '';
    } catch (_) {
      _aiScene = '';
    }
    return _aiScene!;
  }

  /// 校验 token 是否仍然有效
  static Future<bool> checkLogin(String token) async {
    try {
      final body = jsonEncode(<String, dynamic>{
        'clientSource': 'coupon-fusion-workbuddy',
        'userParamDTO': <String, dynamic>{'token': token},
      });
      final headers = await MtPassport.buildHeaders(_checkLoginUrl, body);

      final res = await http
          .post(Uri.parse(_checkLoginUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      final decoded = tryDecodeJson(res.body);
      if (decoded == null) return false;
      return decoded['code'] == 200 &&
          decoded['success'] == true &&
          decoded['data'] != null;
    } catch (_) {
      return false;
    }
  }

  /// 领取优惠券。返回的 IssueResult.coupons 已按金额从大到小排序。
  static Future<IssueResult> issueCoupon(String token) async {
    final aiScene = await loadAiScene();
    if (aiScene.isEmpty) {
      return const IssueResult(
        ok: false,
        error: 'NO_AISCENE',
        message: '缺少 aiScene 配置（assets/config.json）。',
      );
    }

    try {
      final body = jsonEncode(<String, dynamic>{
        'token': token,
        'aiScene': aiScene,
        'version': 2,
      });
      final headers =
          await MtPassport.buildHeaders(_couponUrl, body, token: token);

      final res = await http
          .post(Uri.parse(_couponUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      final decoded = tryDecodeJson(res.body);
      if (decoded == null) {
        return IssueResult(ok: false, error: 'NETWORK', message: '响应解析失败');
      }
      return parseIssueResponse(decoded);
    } on TimeoutException {
      return const IssueResult(ok: false, error: 'TIMEOUT', message: '美团接口请求超时');
    } catch (e) {
      final msg = e.toString();
      return IssueResult(
        ok: false,
        error: msg.contains('TimeoutException') ? 'TIMEOUT' : 'NETWORK',
        message: '请求失败: $msg',
      );
    }
  }
}
