import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../models/app_item_model.dart';

/// 应用工坊与微服务服务层
class AppsService {
  AppsService._();

  static final ValueNotifier<List<AppItemModel>> appsNotifier = ValueNotifier<List<AppItemModel>>([]);
  static final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  /// 初始化并加载本地缓存
  static Future<void> init() async {
    final cached = AppStorage.getCachedAppsJson();
    if (cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        appsNotifier.value = list.map((e) => AppItemModel.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Failed to decode cached apps: $e');
      }
    }
  }

  /// 拉取应用列表
  static Future<List<AppItemModel>> fetchApps({bool background = false}) async {
    if (!background) {
      isLoadingNotifier.value = true;
      errorNotifier.value = null;
    }

    try {
      final res = await ApiClient.get('/api/apps');
      if (res is List) {
        final items = res.map((e) => AppItemModel.fromJson(e)).toList();
        appsNotifier.value = items;
        await AppStorage.setCachedAppsJson(jsonEncode(items.map((e) => e.toJson()).toList()));
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

  /// 创建应用
  static Future<AppItemModel> createApp(Map<String, dynamic> data) async {
    final res = await ApiClient.post('/api/apps', body: data);
    final item = AppItemModel.fromJson(res);
    final currentList = List<AppItemModel>.from(appsNotifier.value)..insert(0, item);
    appsNotifier.value = currentList;
    await AppStorage.setCachedAppsJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    return item;
  }

  /// 更新应用
  static Future<AppItemModel> updateApp(String id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('/api/apps/$id', body: data);
    final item = AppItemModel.fromJson(res);
    final currentList = List<AppItemModel>.from(appsNotifier.value);
    final idx = currentList.indexWhere((a) => a.id == id);
    if (idx != -1) {
      currentList[idx] = item;
      appsNotifier.value = currentList;
      await AppStorage.setCachedAppsJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    }
    return item;
  }

  /// 删除应用
  static Future<bool> deleteApp(String id) async {
    await ApiClient.delete('/api/apps/$id');
    final currentList = List<AppItemModel>.from(appsNotifier.value)..removeWhere((a) => a.id == id);
    appsNotifier.value = currentList;
    await AppStorage.setCachedAppsJson(jsonEncode(currentList.map((e) => e.toJson()).toList()));
    return true;
  }
}
