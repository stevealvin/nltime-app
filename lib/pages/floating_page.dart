import 'dart:io';
import 'package:flutter/material.dart';

import '../common/app_service.dart';
import '../common/floating_clock_service.dart';
import '../common/theme_manager.dart';

class FloatingPage extends StatefulWidget {
  const FloatingPage({super.key});

  @override
  State<FloatingPage> createState() => _FloatingPageState();
}

class _FloatingPageState extends State<FloatingPage> with WidgetsBindingObserver {
  bool _isSystemPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await FloatingClockManager.isPermissionGranted();
    if (mounted) {
      setState(() {
        _isSystemPermissionGranted = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppService.themeIndexNotifier,
      builder: (context, themeIndex, _) {
        final theme = ThemeManager.getTheme(themeIndex);

        return Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            backgroundColor: theme.bgColor,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.layers_rounded, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '悬浮窗时钟控制中心',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildMainToggleCard(theme),
              const SizedBox(height: 16),
              if (Platform.isAndroid) ...[
                _buildSystemPermissionCard(theme),
                const SizedBox(height: 16),
              ],
              _buildStyleCustomizerCard(theme),
              const SizedBox(height: 16),
              _buildDisplayOptionsCard(theme),
            ],
          ),
        );
      },
    );
  }

  /// Enable / Disable Switch Card
  Widget _buildMainToggleCard(AppThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppService.floatingEnabledNotifier,
      builder: (context, enabled, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: enabled ? theme.primaryColor : theme.dividerColor,
              width: 1.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (enabled ? theme.primaryColor : theme.subTextColor)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  enabled ? Icons.grid_view_rounded : Icons.power_settings_new_rounded,
                  color: enabled ? theme.primaryColor : theme.subTextColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开启悬浮窗时钟',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled
                          ? '悬浮窗已激活，支持在应用内及切出桌面/其他 App 时全局置顶显示'
                          : '点击右侧开关开启系统级高精度悬浮时钟',
                      style: TextStyle(color: theme.subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: theme.primaryColor,
                onChanged: (val) async {
                  await AppService.setFloatingEnabled(val);
                  await FloatingClockManager.updateSystemOverlayState(val);
                  _checkPermission();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// System Overlay Permission Status & Request Card
  Widget _buildSystemPermissionCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSystemPermissionGranted ? Colors.green.withValues(alpha: 0.4) : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSystemPermissionGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: _isSystemPermissionGranted ? Colors.greenAccent : Colors.orangeAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSystemPermissionGranted ? '系统悬浮窗权限: 已授权' : '系统悬浮窗权限: 未授权',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSystemPermissionGranted
                      ? '应用切换到桌面、购物或游戏界面时，时间仍将置顶显示'
                      : '需要授权“显示在其他应用上层”权限，才能实现切出应用后的系统级全局悬浮',
                  style: TextStyle(color: theme.subTextColor, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!_isSystemPermissionGranted)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                try {
                  final granted = await FloatingClockManager.requestSystemOverlayPermission();
                  if (mounted) {
                    setState(() => _isSystemPermissionGranted = granted);
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('提示：请在手机【系统设置 - 应用管理 - NLTime - 权限管理】中开启“显示悬浮窗”权限'),
                      ),
                    );
                  }
                }
              },
              child: const Text('去授权', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// Style & Size Sliders
  Widget _buildStyleCustomizerCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '外观与尺寸调节',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Opacity Slider (5% step precision)
          ValueListenableBuilder<double>(
            valueListenable: AppService.floatingOpacityNotifier,
            builder: (context, opacity, _) {
              final percentage = (opacity * 100).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '不透明度',
                        style: TextStyle(color: theme.textColor, fontSize: 13),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: opacity.clamp(0.2, 1.0),
                    min: 0.2,
                    max: 1.0,
                    divisions: 16,
                    activeColor: theme.primaryColor,
                    inactiveColor: theme.bgColor,
                    onChanged: (val) {
                      final stepped = (val * 20).round() / 20.0;
                      AppService.setFloatingOpacity(stepped);
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Scale Slider (5% step precision)
          ValueListenableBuilder<double>(
            valueListenable: AppService.floatingScaleNotifier,
            builder: (context, scale, _) {
              final percentage = (scale * 100).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '悬浮窗缩放比例',
                        style: TextStyle(color: theme.textColor, fontSize: 13),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: scale.clamp(0.5, 1.5),
                    min: 0.5,
                    max: 1.5,
                    divisions: 20,
                    activeColor: theme.primaryColor,
                    inactiveColor: theme.bgColor,
                    onChanged: (val) {
                      final stepped = (val * 20).round() / 20.0;
                      AppService.setFloatingScale(stepped);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Display Options Switches
  Widget _buildDisplayOptionsCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_rounded, size: 18, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                '悬浮信息元素显示选项',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: AppService.floatingShowMsNotifier,
            builder: (context, val, _) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('显示 3 位完整毫秒 (.SSS)', style: TextStyle(color: theme.textColor, fontSize: 13)),
                subtitle: Text(
                  val ? '已开启：显示 3 位完整精确毫秒 (.SSS)' : '默认关闭：显示 1 位精简毫秒 (.S)',
                  style: TextStyle(color: theme.subTextColor, fontSize: 11),
                ),
                value: val,
                activeColor: theme.primaryColor,
                onChanged: (v) => AppService.setFloatingShowMs(v),
              );
            },
          ),
          Divider(color: theme.dividerColor, height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppService.floatingShowOffsetNotifier,
            builder: (context, val, _) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('显示误差 (Offset) 与 RTT 时延', style: TextStyle(color: theme.textColor, fontSize: 13)),
                value: val,
                activeColor: theme.primaryColor,
                onChanged: (v) => AppService.setFloatingShowOffset(v),
              );
            },
          ),
          Divider(color: theme.dividerColor, height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: AppService.floatingShowSourceNotifier,
            builder: (context, val, _) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('显示授时源名称 (如 淘宝/苏宁)', style: TextStyle(color: theme.textColor, fontSize: 13)),
                value: val,
                activeColor: theme.primaryColor,
                onChanged: (v) => AppService.setFloatingShowSource(v),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Tips Card
  Widget _buildTipsCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: theme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '开启系统级悬浮窗后，即使返回手机桌面或切换到其他任意 App (如浏览器、电商、游戏)，极准毫秒时间仍将悬浮置顶显示。在 Windows 桌面端支持全屏窗口置顶。',
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
