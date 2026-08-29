import 'dart:io';
import 'package:flutter/material.dart';

import '../common/app_service.dart';
import '../common/floating_clock_service.dart';

/// Floating clock control page — pure content widget, no inner Scaffold.
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
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await FloatingClockManager.isPermissionGranted();
    if (mounted) setState(() => _isSystemPermissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildMainToggleCard(context),
        const SizedBox(height: 16),
        if (Platform.isAndroid) ...[
          _buildSystemPermissionCard(context),
          const SizedBox(height: 16),
        ],
        _buildStyleCustomizerCard(context),
        const SizedBox(height: 16),
        _buildDisplayOptionsCard(context),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMainToggleCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: AppService.floatingEnabledNotifier,
      builder: (context, enabled, _) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: enabled ? cs.primary : Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (enabled ? cs.primary : cs.onSurface)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    enabled
                        ? Icons.grid_view_rounded
                        : Icons.power_settings_new_rounded,
                    color: enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enabled
                            ? '悬浮窗已激活，支持在应用内及切出桌面/其他 App 时全局置顶显示'
                            : '点击右侧开关开启系统级高精度悬浮时钟',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (val) async {
                    await AppService.setFloatingEnabled(val);
                    await FloatingClockManager.updateSystemOverlayState(val);
                    _checkPermission();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemPermissionCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final granted = _isSystemPermissionGranted;
    final borderCol = granted
        ? Colors.green.withValues(alpha: 0.4)
        : Colors.orange.withValues(alpha: 0.4);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderCol),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              granted ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: granted ? Colors.greenAccent : Colors.orangeAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    granted ? '系统悬浮窗权限: 已授权' : '系统悬浮窗权限: 未授权',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    granted
                        ? '应用切换到桌面、购物或游戏界面时，时间仍将置顶显示'
                        : '需要授权"显示在其他应用上层"权限，才能实现系统级全局悬浮',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
            if (!granted)
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final ok =
                        await FloatingClockManager.requestSystemOverlayPermission();
                    if (mounted) setState(() => _isSystemPermissionGranted = ok);
                  } catch (_) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                            '请在手机【设置 - 应用管理 - NLTime - 权限管理】中开启"显示悬浮窗"'),
                      ),
                    );
                  }
                },
                child: const Text('去授权', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleCustomizerCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '外观与尺寸调节',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: AppService.floatingOpacityNotifier,
              builder: (context, opacity, _) {
                return _SliderRow(
                  label: '不透明度',
                  value: opacity.clamp(0.2, 1.0),
                  displayText: '${(opacity * 100).round()}%',
                  min: 0.2,
                  max: 1.0,
                  divisions: 16,
                  onChanged: (val) {
                    final stepped = (val * 20).round() / 20.0;
                    AppService.setFloatingOpacity(stepped);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: AppService.floatingScaleNotifier,
              builder: (context, scale, _) {
                return _SliderRow(
                  label: '悬浮窗缩放比例',
                  value: scale.clamp(0.7, 2.5),
                  displayText: '${(scale * 100).round()}%',
                  min: 0.7,
                  max: 2.5,
                  divisions: 18,
                  onChanged: (val) {
                    final stepped = (val * 10).round() / 10.0;
                    AppService.setFloatingScale(stepped);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOptionsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.remove_red_eye_rounded, size: 18, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  '悬浮信息元素显示选项',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: AppService.floatingShowProgressNotifier,
              builder: (ctx, val, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示底部毫秒动态进度条'),
                subtitle: const Text('实时可视化 0~1000ms 毫秒周期进度'),
                value: val,
                onChanged: AppService.setFloatingShowProgress,
              ),
            ),
            const Divider(),
            ValueListenableBuilder<bool>(
              valueListenable: AppService.floatingShowMsNotifier,
              builder: (ctx, val, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示 3 位完整毫秒 (.SSS)'),
                subtitle: Text(val
                    ? '已开启：显示 3 位完整精确毫秒 (.SSS)'
                    : '默认关闭：显示 1 位精简毫秒 (.S)'),
                value: val,
                onChanged: AppService.setFloatingShowMs,
              ),
            ),
            const Divider(),
            ValueListenableBuilder<bool>(
              valueListenable: AppService.floatingShowOffsetNotifier,
              builder: (ctx, val, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示误差 (Offset) 与 RTT 时延'),
                value: val,
                onChanged: AppService.setFloatingShowOffset,
              ),
            ),
            const Divider(),
            ValueListenableBuilder<bool>(
              valueListenable: AppService.floatingShowSourceNotifier,
              builder: (ctx, val, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示授时源名称 (如 淘宝/苏宁)'),
                value: val,
                onChanged: AppService.setFloatingShowSource,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final String displayText;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.displayText,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              displayText,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
