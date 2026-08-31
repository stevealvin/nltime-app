import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OmniFlow 本地存储与配置中心
class AppStorage {
  AppStorage._();

  static late SharedPreferences _prefs;

  // Keys
  static const String _keyBaseUrl = 'omniflow_base_url';
  static const String _keyThemeMode = 'omniflow_theme_mode'; // 'system', 'light', 'dark'
  static const String _keyLastRoomCode = 'omniflow_last_room_code';
  static const String _keyCachedQuota = 'omniflow_cached_quota_json';
  static const String _keyCachedApps = 'omniflow_cached_apps_json';

  // Notifiers for reactive UI
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final ValueNotifier<String> baseUrlNotifier = ValueNotifier<String>('https://om.nle.lol');

  /// 初始化 SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 加载主题模式
    final savedMode = _prefs.getString(_keyThemeMode) ?? 'system';
    switch (savedMode) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
    }

    // 加载 BaseUrl (默认为 https://om.nle.lol，或局域网/线上地址)
    final savedUrl = _prefs.getString(_keyBaseUrl);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      baseUrlNotifier.value = savedUrl.trim();
    } else {
      baseUrlNotifier.value = 'https://om.nle.lol';
    }
  }

  // --- Base URL ---
  static String get baseUrl => baseUrlNotifier.value;

  static Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    baseUrlNotifier.value = cleanUrl;
    await _prefs.setString(_keyBaseUrl, cleanUrl);
  }

  // --- Theme Mode ---
  static ThemeMode get themeMode => themeModeNotifier.value;

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setString(_keyThemeMode, modeStr);
  }

  // --- Room Code ---
  static String? getLastRoomCode() => _prefs.getString(_keyLastRoomCode);

  static Future<void> setLastRoomCode(String code) async {
    await _prefs.setString(_keyLastRoomCode, code);
  }

  // --- Quota Cache ---
  static String? getCachedQuotaJson() => _prefs.getString(_keyCachedQuota);

  static Future<void> setCachedQuotaJson(String jsonStr) async {
    await _prefs.setString(_keyCachedQuota, jsonStr);
  }

  // --- Apps Cache ---
  static String? getCachedAppsJson() => _prefs.getString(_keyCachedApps);

  static Future<void> setCachedAppsJson(String jsonStr) async {
    await _prefs.setString(_keyCachedApps, jsonStr);
  }
}
