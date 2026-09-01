import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_service_model.dart';
import 'floating_clock_service.dart';

class SyncResult {
  final int offsetMs;
  final int rttMs;
  final bool success;
  final String? errorMessage;
  final String serviceName;

  SyncResult({
    required this.offsetMs,
    required this.rttMs,
    required this.success,
    this.errorMessage,
    required this.serviceName,
  });
}

class AppService {
  static late PackageInfo packageInfo;
  static late SharedPreferences prefs;

  static const String _prefsKeyCustomServices = 'custom_time_services';
  static const String _prefsKeyCurrentServiceId = 'current_time_service_id';
  
  // Floating window settings keys
  static const String _prefsKeyFloatingEnabled = 'floating_enabled';
  static const String _prefsKeyFloatingOpacity = 'floating_opacity';
  static const String _prefsKeyFloatingScale = 'floating_scale';
  static const String _prefsKeyFloatingShowMs = 'floating_show_ms';
  static const String _prefsKeyFloatingShowOffset = 'floating_show_offset';
  static const String _prefsKeyFloatingShowSource = 'floating_show_source';
  static const String _prefsKeyFloatingShowProgress = 'floating_show_progress';

  // ValueNotifiers for reactive UI updates
  static final ValueNotifier<String> activeServiceIdNotifier = ValueNotifier<String>('suning');
  
  // Floating window state Notifiers
  static final ValueNotifier<bool> floatingEnabledNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<double> floatingOpacityNotifier = ValueNotifier<double>(0.9);
  static final ValueNotifier<double> floatingScaleNotifier = ValueNotifier<double>(1.2);
  static final ValueNotifier<bool> floatingShowMsNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> floatingShowOffsetNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> floatingShowSourceNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> floatingShowProgressNotifier = ValueNotifier<bool>(true);

  // Time Sync state Notifiers
  static final ValueNotifier<int> serverTimeOffsetNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> rttNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<DateTime?> lastSyncTimeNotifier = ValueNotifier<DateTime?>(null);

  static final List<TimeService> _builtinTimeServices = [
    TimeService(
      id: 'suning',
      name: '苏宁时间',
      url: 'https://f.m.suning.com/api/ct.do',
      isBuiltin: true,
      parseType: TimeParseType.suning,
      description: '苏宁易购开放时间 API',
    ),
    TimeService(
      id: 'bilibili',
      name: '哔哩哔哩授时',
      url: 'https://api.bilibili.com/x/report/click/now',
      isBuiltin: true,
      parseType: TimeParseType.customKey,
      customKey: 'now',
      description: 'B站高频极速 HTTP 授时节点',
    ),
  ];

  static List<TimeService> _customTimeServices = [];

  static List<TimeService> get timeServices => [
        ..._builtinTimeServices,
        ..._customTimeServices,
      ];

  static TimeService get currentTimeService {
    return timeServices.firstWhere(
      (item) => item.id == activeServiceIdNotifier.value,
      orElse: () => _builtinTimeServices.first,
    );
  }

  static Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
    prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  static void _loadSettings() {
    // Custom services
    final rawList = prefs.getString(_prefsKeyCustomServices);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        final data = jsonDecode(rawList) as List<dynamic>;
        _customTimeServices = data
            .whereType<Map<String, dynamic>>()
            .map(TimeService.fromJson)
            .toList();
      } catch (_) {
        _customTimeServices = [];
      }
    }

    // Current service
    final currentId = prefs.getString(_prefsKeyCurrentServiceId) ?? 'suning';
    if (timeServices.any((item) => item.id == currentId)) {
      activeServiceIdNotifier.value = currentId;
    }

    // Floating window settings
    floatingEnabledNotifier.value = prefs.getBool(_prefsKeyFloatingEnabled) ?? false;
    floatingOpacityNotifier.value = prefs.getDouble(_prefsKeyFloatingOpacity) ?? 0.9;
    floatingScaleNotifier.value = prefs.getDouble(_prefsKeyFloatingScale) ?? 1.2;
    floatingShowMsNotifier.value = prefs.getBool(_prefsKeyFloatingShowMs) ?? false;
    floatingShowOffsetNotifier.value = prefs.getBool(_prefsKeyFloatingShowOffset) ?? true;
    floatingShowSourceNotifier.value = prefs.getBool(_prefsKeyFloatingShowSource) ?? true;
    floatingShowProgressNotifier.value = prefs.getBool(_prefsKeyFloatingShowProgress) ?? true;

    if (floatingEnabledNotifier.value) {
      FloatingClockManager.updateSystemOverlayState(true);
    }
  }

  /// Manually select active time service
  static Future<void> setCurrentTimeService(String id) async {
    activeServiceIdNotifier.value = id;
    await prefs.setString(_prefsKeyCurrentServiceId, id);
    // Auto sync upon switching source manually
    await syncWithSelectedService();
  }

  /// Floating window settings updates
  static Future<void> setFloatingEnabled(bool val) async {
    floatingEnabledNotifier.value = val;
    await prefs.setBool(_prefsKeyFloatingEnabled, val);
    await FloatingClockManager.updateSystemOverlayState(val);
  }

  static Future<void> setFloatingOpacity(double val) async {
    floatingOpacityNotifier.value = val;
    await prefs.setDouble(_prefsKeyFloatingOpacity, val);
    await FloatingClockManager.syncOverlayData();
  }

  static Future<void> setFloatingScale(double val) async {
    floatingScaleNotifier.value = val;
    await prefs.setDouble(_prefsKeyFloatingScale, val);
    await FloatingClockManager.syncOverlayData();
  }

  static Future<void> setFloatingShowMs(bool val) async {
    floatingShowMsNotifier.value = val;
    await prefs.setBool(_prefsKeyFloatingShowMs, val);
    await FloatingClockManager.syncOverlayData();
  }

  static Future<void> setFloatingShowOffset(bool val) async {
    floatingShowOffsetNotifier.value = val;
    await prefs.setBool(_prefsKeyFloatingShowOffset, val);
    await FloatingClockManager.syncOverlayData();
  }

  static Future<void> setFloatingShowSource(bool val) async {
    floatingShowSourceNotifier.value = val;
    await prefs.setBool(_prefsKeyFloatingShowSource, val);
    await FloatingClockManager.syncOverlayData();
  }

  static Future<void> setFloatingShowProgress(bool val) async {
    floatingShowProgressNotifier.value = val;
    await prefs.setBool(_prefsKeyFloatingShowProgress, val);
    await FloatingClockManager.syncOverlayData();
  }

  /// Execute Precision Time Sync with active time service & RTT Compensation
  static Future<SyncResult> syncWithSelectedService([TimeService? targetService]) async {
    final service = targetService ?? currentTimeService;
    isSyncingNotifier.value = true;

    final sendTime = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await http.get(
        Uri.parse(service.url),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'User-Agent': 'NLTime/1.0',
        },
      ).timeout(const Duration(seconds: 4));

      final recvTime = DateTime.now().millisecondsSinceEpoch;
      final rtt = recvTime - sendTime;

      if (response.statusCode == 200) {
        final serverTimeMs = service.parseTimestampMs(response.body);

        if (serverTimeMs != null) {
          // RTT Compensation Algorithm:
          // Estimated server time at recvTime = serverTimeMs + (rtt / 2)
          final estimatedServerTimeAtRecv = serverTimeMs + (rtt ~/ 2);
          final offset = estimatedServerTimeAtRecv - recvTime;

          serverTimeOffsetNotifier.value = offset;
          rttNotifier.value = rtt;
          lastSyncTimeNotifier.value = DateTime.now();

          isSyncingNotifier.value = false;
          return SyncResult(
            offsetMs: offset,
            rttMs: rtt,
            success: true,
            serviceName: service.name,
          );
        }
      }
      isSyncingNotifier.value = false;
      return SyncResult(
        offsetMs: serverTimeOffsetNotifier.value,
        rttMs: rtt,
        success: false,
        errorMessage: '解析服务器时间失败',
        serviceName: service.name,
      );
    } catch (e) {
      isSyncingNotifier.value = false;
      return SyncResult(
        offsetMs: serverTimeOffsetNotifier.value,
        rttMs: 0,
        success: false,
        errorMessage: '网络连接超时或无法访问: $e',
        serviceName: service.name,
      );
    }
  }

  /// Custom Time Service CRUD
  static Future<TimeService> addCustomTimeService({
    required String name,
    required String url,
    TimeParseType parseType = TimeParseType.timestampMs,
    String? customKey,
  }) async {
    final service = TimeService(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: url,
      isBuiltin: false,
      parseType: parseType,
      customKey: customKey,
    );
    _customTimeServices.add(service);
    await _saveCustomServices();
    return service;
  }

  static Future<void> updateCustomTimeService({
    required String id,
    required String name,
    required String url,
    TimeParseType parseType = TimeParseType.timestampMs,
    String? customKey,
  }) async {
    final index = _customTimeServices.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _customTimeServices[index] = TimeService(
      id: id,
      name: name,
      url: url,
      isBuiltin: false,
      parseType: parseType,
      customKey: customKey,
    );
    await _saveCustomServices();
  }

  static Future<void> deleteCustomTimeService(String id) async {
    _customTimeServices.removeWhere((item) => item.id == id);
    if (!timeServices.any((item) => item.id == activeServiceIdNotifier.value)) {
      activeServiceIdNotifier.value = _builtinTimeServices.first.id;
      await prefs.setString(_prefsKeyCurrentServiceId, activeServiceIdNotifier.value);
    }
    await _saveCustomServices();
  }

  static Future<void> _saveCustomServices() async {
    final data = _customTimeServices.map((item) => item.toJson()).toList();
    await prefs.setString(_prefsKeyCustomServices, jsonEncode(data));
  }
}
