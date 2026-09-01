import 'dart:async';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../services/app_service.dart';
import '../services/floating_clock_service.dart';
import '../widgets/time_service_form_dialog.dart';

abstract class HomePageController {
  static VoidCallback? triggerSync;
}

/// 极速对时与悬浮窗主页面 (Time Sync & Integrated Floating Settings)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  bool _isSyncing = false;
  bool _isSystemPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    HomePageController.triggerSync = _triggerSync;

    _checkPermission();

    // 10ms 高刷定时器以平滑渲染毫秒
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final offset = AppService.serverTimeOffsetNotifier.value;
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now().add(Duration(milliseconds: offset));
        });
      }
    });

    _triggerSync();
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    HomePageController.triggerSync = null;
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

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    AppService.isSyncingNotifier.value = true;

    final res = await AppService.syncWithSelectedService();

    AppService.isSyncingNotifier.value = false;
    if (mounted) {
      setState(() => _isSyncing = false);
      if (res.success) {
        AppDialog.showToast(
          context: context,
          message: '已对齐 ${res.serviceName}：延迟 ${res.rttMs}ms，误差 ${res.offsetMs}ms',
        );
      } else {
        AppDialog.showToast(
          context: context,
          message: '同步失败: ${res.errorMessage}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. 核心高精度时钟看板
        _buildClockHeroCard(context, isDark),
        const SizedBox(height: 12),

        // 2. 压缩紧凑的延迟 (RTT) 与 误差 (Offset) 状态指示条
        _buildCompressedMetricsCard(context, isDark),
        const SizedBox(height: 16),

        // 3. NTP 授时服务源列表 (直接在对时页面切换)
        _buildSectionHeader('NTP 授时服务源', isDark),
        _buildTimeSourcesGroup(context, isDark),
        const SizedBox(height: 16),

        // 4. 悬浮窗时钟设置专区 (整合)
        _buildSectionHeader('全局悬浮时钟', isDark),
        _buildFloatingClockSettingsCard(context, isDark),
        const SizedBox(height: 32),
      ],
    );
  }

  /// 1. 极简时钟主卡片
  Widget _buildClockHeroCard(BuildContext context, bool isDark) {
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final msStr = (_currentTime.millisecond).toString().padLeft(3, '0');
    final dateStr = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(_currentTime);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 日期与星期
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),

          // 主时钟数字 + 毫秒
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '.$msStr',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 毫秒进度条与 0~10 刻度尺 (对应 0~1000ms)
          _buildMillisecondScale(context, isDark, _currentTime.millisecond),
        ],
      ),
    );
  }

  /// 毫秒动态进度条与刻度尺 (从左至右 0~1000ms 平滑扫描)
  Widget _buildMillisecondScale(BuildContext context, bool isDark, int millisecond) {
    final progress = (millisecond / 1000.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 动态进度条轨道 (严格从左侧 0 起点向右推进)
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 填充条 (从左边缘 0 开始向右伸展)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: constraints.maxWidth * progress,
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accentIndigo,
                            AppColors.primary,
                            Color(0xFF10B981),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 5),

        // 0 ~ 10 刻度线与时间标识
        SizedBox(
          height: 18,
          child: CustomPaint(
            size: const Size(double.infinity, 18),
            painter: _MillisecondTickPainter(
              isDark: isDark,
              currentProgress: progress,
            ),
          ),
        ),
      ],
    );
  }

  /// 2. 压缩优化的延迟 (RTT) 与 误差 (Offset) 紧凑指示条
  Widget _buildCompressedMetricsCard(BuildContext context, bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: AppService.rttNotifier,
      builder: (context, rtt, _) {
        return ValueListenableBuilder<int>(
          valueListenable: AppService.serverTimeOffsetNotifier,
          builder: (context, offset, _) {
            final currentSvc = AppService.currentTimeService;

            final rttColor = rtt <= 40
                ? AppColors.success
                : (rtt <= 100 ? AppColors.warning : AppColors.danger);

            return GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 18,
              child: Row(
                children: [
                  // 延迟 Pill
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rttColor,
                            boxShadow: [
                              BoxShadow(color: rttColor.withValues(alpha: 0.5), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '网络时延 (RTT)',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              rtt == 0 ? '--' : '$rtt ms',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: rttColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 分隔线
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                  const SizedBox(width: 12),

                  // 误差 Pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '校准误差 (Offset)',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          offset >= 0 ? '+$offset ms' : '$offset ms',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 立即同步按钮
                  IconButton(
                    tooltip: '即时测速对时 (${currentSvc.name})',
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.primary),
                    onPressed: _isSyncing ? null : _triggerSync,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 3. 整合的悬浮窗时钟设置专区
  Widget _buildFloatingClockSettingsCard(BuildContext context, bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppService.floatingEnabledNotifier,
      builder: (context, enabled, _) {
        return GlassContainer(
          padding: const EdgeInsets.all(18),
          borderRadius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶行：标题与开关
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (enabled ? AppColors.primary : AppColors.accentIndigo)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.layers,
                      size: 18,
                      color: enabled ? AppColors.primary : AppColors.accentIndigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '悬浮窗时钟',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '置顶悬浮在桌面与其他 App 上方，精准秒杀',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (val) async {
                      HapticFeedback.lightImpact();
                      await AppService.setFloatingEnabled(val);
                      await FloatingClockManager.updateSystemOverlayState(val);
                      _checkPermission();
                    },
                  ),
                ],
              ),

              // Android 权限提示
              if (Platform.isAndroid && !_isSystemPermissionGranted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '需要「悬浮窗权限」以支持桌面全局置顶',
                          style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FloatingClockManager.requestSystemOverlayPermission();
                          _checkPermission();
                        },
                        child: const Text('去授权', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
                const SizedBox(height: 14),

                // 缩放大小调节
                ValueListenableBuilder<double>(
                  valueListenable: AppService.floatingScaleNotifier,
                  builder: (context, scale, _) {
                    return Row(
                      children: [
                        const Icon(LucideIcons.scaling, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '悬浮窗大小 (${scale.toStringAsFixed(1)}x)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: scale,
                            min: 0.8,
                            max: 1.8,
                            divisions: 10,
                            onChanged: (val) {
                              AppService.setFloatingScale(val);
                              FloatingClockManager.syncOverlayData();
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // 显示选项：毫秒开关
                ValueListenableBuilder<bool>(
                  valueListenable: AppService.floatingShowMsNotifier,
                  builder: (context, showMs, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '悬浮窗显示毫秒 (.xxx)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Switch(
                          value: showMs,
                          onChanged: (val) {
                            AppService.setFloatingShowMs(val);
                            FloatingClockManager.syncOverlayData();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 分组标题
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// NTP 授时服务源列表分组
  Widget _buildTimeSourcesGroup(BuildContext context, bool isDark) {
    final services = AppService.timeServices;

    return ValueListenableBuilder<String>(
      valueListenable: AppService.activeServiceIdNotifier,
      builder: (context, activeId, _) {
        return GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: 18,
          child: Column(
            children: [
              for (int i = 0; i < services.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: (services[i].id == activeId ? AppColors.primary : AppColors.accentIndigo)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.radio,
                      size: 15,
                      color: services[i].id == activeId ? AppColors.primary : AppColors.accentIndigo,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        services[i].name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: services[i].id == activeId ? FontWeight.w700 : FontWeight.w500,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (!services[i].isBuiltin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('自定义', style: TextStyle(fontSize: 9, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    services[i].parseType.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  trailing: services[i].id == activeId
                      ? const Icon(LucideIcons.check, size: 18, color: AppColors.primary)
                      : null,
                  onTap: () {
                    AppService.setCurrentTimeService(services[i].id);
                    _triggerSync();
                  },
                ),
              ],
              Divider(
                height: 1,
                thickness: 0.5,
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
              InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => const TimeServiceFormDialog(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(LucideIcons.plus, size: 15, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        '添加自定义授时源',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 高精度 0~10 刻度线与时间标识绘制器 (对应 0~1000ms)
class _MillisecondTickPainter extends CustomPainter {
  final bool isDark;
  final double currentProgress;

  _MillisecondTickPainter({
    required this.isDark,
    required this.currentProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()..strokeWidth = 1.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final inactiveTickColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFF94A3B8);

    final activeTickColor = AppColors.primary;

    final labelStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
    );

    // 绘制 0 ~ 10 主刻度 (共 11 个点，对应 0ms, 100ms, 200ms ... 1000ms)
    for (int i = 0; i <= 10; i++) {
      final x = (size.width * i) / 10.0;
      final isPassed = (i / 10.0) <= currentProgress;

      tickPaint.color = isPassed ? activeTickColor : inactiveTickColor;

      // 刻度线 (0, 5, 10 略长，其余等齐)
      final tickHeight = (i == 0 || i == 5 || i == 10) ? 4.5 : 3.0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, tickHeight),
        tickPaint,
      );

      // 绘制 0 ~ 10 刻度数值
      final labelText = '$i';
      textPainter.text = TextSpan(
        text: labelText,
        style: labelStyle.copyWith(
          color: isPassed ? AppColors.primary : null,
          fontWeight: isPassed ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();

      // 居中/边界对齐
      double textX = x - (textPainter.width / 2.0);
      if (i == 0) textX = 0;
      if (i == 10) textX = size.width - textPainter.width;

      textPainter.paint(canvas, Offset(textX, 5));
    }
  }

  @override
  bool shouldRepaint(covariant _MillisecondTickPainter oldDelegate) {
    return oldDelegate.currentProgress != currentProgress ||
        oldDelegate.isDark != isDark;
  }
}

