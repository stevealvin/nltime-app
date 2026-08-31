import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../models/quota_model.dart';

/// 算力配额与 API Key 服务
class QuotaService {
  QuotaService._();

  static final ValueNotifier<List<ApiKeyConfig>> keysNotifier = ValueNotifier<List<ApiKeyConfig>>([]);
  static final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  /// 初始化并加载缓存数据
  static Future<void> init() async {
    final cached = AppStorage.getCachedQuotaJson();
    if (cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        keysNotifier.value = list.map((e) => ApiKeyConfig.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Failed to decode cached quota: $e');
      }
    }
  }

  /// 从服务器拉取最新配额配置列表
  static Future<List<ApiKeyConfig>> fetchQuotas({bool background = false}) async {
    if (!background) {
      isLoadingNotifier.value = true;
      errorNotifier.value = null;
    }

    try {
      final res = await ApiClient.get('/api/quota');
      if (res is List) {
        final items = res.map((e) => ApiKeyConfig.fromJson(e)).toList();
        keysNotifier.value = items;
        // 写入本地持久化缓存
        await AppStorage.setCachedQuotaJson(jsonEncode(items.map((e) => e.toJson()).toList()));
        return items;
      }
      return [];
    } catch (e) {
      if (!background) {
        errorNotifier.value = e.toString();
      }
      rethrow;
    } finally {
      if (!background) {
        isLoadingNotifier.value = false;
      }
    }
  }

  /// 探针检测单个资源配额
  static Future<ApiKeyConfig> probeQuota(String id) async {
    final res = await ApiClient.post('/api/quota/$id/check');
    final updated = ApiKeyConfig.fromJson(res);
    
    // 更新本地列表状态
    final currentList = List<ApiKeyConfig>.from(keysNotifier.value);
    final idx = currentList.indexWhere((k) => k.id == id);
    if (idx != -1) {
      currentList[idx] = updated;
      keysNotifier.value = currentList;
      await AppStorage.setCachedQuotaJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    }
    return updated;
  }

  /// 批量全量探针检测
  static Future<List<ApiKeyConfig>> probeAllQuotas() async {
    isLoadingNotifier.value = true;
    try {
      final res = await ApiClient.post('/api/quota/check-all');
      if (res is List) {
        final items = res.map((e) => ApiKeyConfig.fromJson(e)).toList();
        keysNotifier.value = items;
        await AppStorage.setCachedQuotaJson(jsonEncode(items.map((e) => e.toJson()).toList()));
        return items;
      }
      return keysNotifier.value;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// 添加新算力资源 / Token Plane 托管账号
  static Future<ApiKeyConfig> addQuota(Map<String, dynamic> data) async {
    final res = await ApiClient.post('/api/quota', body: data);
    final item = ApiKeyConfig.fromJson(res);
    final currentList = List<ApiKeyConfig>.from(keysNotifier.value)..insert(0, item);
    keysNotifier.value = currentList;
    await AppStorage.setCachedQuotaJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    return item;
  }

  /// 更新指定算力资源
  static Future<ApiKeyConfig> updateQuota(String id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('/api/quota/$id', body: data);
    final item = ApiKeyConfig.fromJson(res);
    final currentList = List<ApiKeyConfig>.from(keysNotifier.value);
    final idx = currentList.indexWhere((k) => k.id == id);
    if (idx != -1) {
      currentList[idx] = item;
      keysNotifier.value = currentList;
      await AppStorage.setCachedQuotaJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    }
    return item;
  }

  /// 删除指定算力资源
  static Future<bool> deleteQuota(String id) async {
    await ApiClient.delete('/api/quota/$id');
    final currentList = List<ApiKeyConfig>.from(keysNotifier.value)..removeWhere((k) => k.id == id);
    keysNotifier.value = currentList;
    await AppStorage.setCachedQuotaJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    return true;
  }
}
