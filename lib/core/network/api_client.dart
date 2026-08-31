import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/app_storage.dart';

/// OmniFlow 统一网络请求工具
class ApiClient {
  ApiClient._();

  static const Duration defaultTimeout = Duration(seconds: 15);

  /// 构建完整请求 URL
  static Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = AppStorage.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';
    return Uri.parse(fullUrl).replace(queryParameters: queryParams);
  }

  /// 标准 GET 请求
  static Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络或服务端连接', statusCode: 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('网络请求失败: $e');
    }
  }

  /// 标准 POST 请求
  static Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络或服务端连接', statusCode: 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('网络请求失败: $e');
    }
  }

  /// 标准 PUT 请求
  static Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络或服务端连接', statusCode: 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('网络请求失败: $e');
    }
  }

  /// 标准 DELETE 请求
  static Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 204) {
        return true;
      }
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络或服务端连接', statusCode: 408);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('网络请求失败: $e');
    }
  }

  /// 测试服务端连通性与响应时间
  static Future<int> ping([String? targetUrl]) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final base = targetUrl ?? AppStorage.baseUrl;
      final uri = Uri.parse('$base/api/quota');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode < 500) {
        return DateTime.now().millisecondsSinceEpoch - start;
      }
      throw ApiException('服务端返回异常: ${response.statusCode}');
    } catch (e) {
      throw ApiException('无法连通指定服务器 ($e)');
    }
  }

  /// 统一响应体解析
  static dynamic _handleResponse(http.Response response) {
    final bodyString = utf8.decode(response.bodyBytes);
    dynamic data;
    try {
      data = jsonDecode(bodyString);
    } catch (_) {
      data = bodyString;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      String msg = '请求错误 (${response.statusCode})';
      if (data is Map && data['error'] != null) {
        msg = data['error'].toString();
      } else if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      throw ApiException(msg, statusCode: response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
