import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_service.dart';

class FloatingClockManager {
  static const MethodChannel _channel = MethodChannel('com.nl.omniflow/overlay');
  static bool _isSystemWindowActive = false;

  /// Request system overlay permission using permission_handler & native intent
  static Future<bool> requestSystemOverlayPermission() async {
    if (Platform.isAndroid) {
      try {
        final bool? granted = await _channel.invokeMethod<bool>('checkOverlayPermission');
        if (granted == true) return true;

        await _channel.invokeMethod('requestOverlayPermission');
        await openAppSettings();
        final bool? recheck = await _channel.invokeMethod<bool>('checkOverlayPermission');
        return recheck ?? false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Check if system overlay permission is granted
  static Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      try {
        final bool? granted = await _channel.invokeMethod<bool>('checkOverlayPermission');
        return granted ?? false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// Toggle System-Level Overlay Window Mode
  static Future<void> updateSystemOverlayState(bool enabled) async {
    if (enabled) {
      if (Platform.isAndroid) {
        final isGranted = await isPermissionGranted();
        if (!isGranted) {
          await requestSystemOverlayPermission();
        }
        try {
          await _channel.invokeMethod('startNativeFloatWindow', {
            'offsetMs': AppService.serverTimeOffsetNotifier.value,
            'rttMs': AppService.rttNotifier.value,
            'source': AppService.currentTimeService.name,
            'themeIdx': 0,
            'opacity': AppService.floatingOpacityNotifier.value,
            'scale': AppService.floatingScaleNotifier.value,
            'showMs': AppService.floatingShowMsNotifier.value,
            'showOffset': AppService.floatingShowOffsetNotifier.value,
            'showSource': AppService.floatingShowSourceNotifier.value,
            'showProgress': AppService.floatingShowProgressNotifier.value,
          });
          _isSystemWindowActive = true;
        } catch (_) {}
      }
    } else {
      if (Platform.isAndroid) {
        try {
          await _channel.invokeMethod('stopNativeFloatWindow');
        } catch (_) {}
        _isSystemWindowActive = false;
      }
    }
  }

  /// Sync active parameters with native FloatClockService
  static Future<void> syncOverlayData() async {
    if (Platform.isAndroid && _isSystemWindowActive) {
      try {
        await _channel.invokeMethod('updateFloatParams', {
          'offsetMs': AppService.serverTimeOffsetNotifier.value,
          'rttMs': AppService.rttNotifier.value,
          'source': AppService.currentTimeService.name,
          'themeIdx': 0,
          'opacity': AppService.floatingOpacityNotifier.value,
          'scale': AppService.floatingScaleNotifier.value,
          'showMs': AppService.floatingShowMsNotifier.value,
          'showOffset': AppService.floatingShowOffsetNotifier.value,
          'showSource': AppService.floatingShowSourceNotifier.value,
          'showProgress': AppService.floatingShowProgressNotifier.value,
        });
      } catch (_) {}
    }
  }
}
