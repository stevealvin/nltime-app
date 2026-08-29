import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../common/app_service.dart';
import '../common/theme_manager.dart';
import '../views/app_dialog.dart';

class FullscreenClockPage extends StatefulWidget {
  const FullscreenClockPage({super.key});

  @override
  State<FullscreenClockPage> createState() => _FullscreenClockPageState();
}

class _FullscreenClockPageState extends State<FullscreenClockPage> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final offset = AppService.serverTimeOffsetNotifier.value;
      if (mounted) {
        setState(() {
          _now = DateTime.now().add(Duration(milliseconds: offset));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final result = await AppService.syncWithSelectedService();
    if (mounted) {
      final theme = ThemeManager.lightTheme;
      AppDialog.showToast(
        context: context,
        theme: theme,
        isError: !result.success,
        message: result.success
            ? '已完成极速授时校准 (RTT: ${result.rttMs}ms)'
            : '同步失败: ${result.errorMessage ?? "网络连接超时"}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const theme = ThemeManager.lightTheme;

    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final msStr = (_now.millisecond).toString().padLeft(3, '0');
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekdayStr = weekdays[(_now.weekday - 1).clamp(0, 6)];
    final dateStr = '${_now.year}年${_now.month.toString().padLeft(2, '0')}月${_now.day.toString().padLeft(2, '0')}日 $weekdayStr';
    final offset = AppService.serverTimeOffsetNotifier.value;
    final rtt = AppService.rttNotifier.value;
    final progress = _now.millisecond / 1000.0;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.primaryColor,
          backgroundColor: theme.cardColor,
          onRefresh: _handleRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      // Centered content
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Date & Week
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Giant Clock
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 90,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        color: theme.textColor,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      msStr,
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Millisecond Progress Bar
                              Container(
                                constraints: const BoxConstraints(maxWidth: 600),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.cardColor.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '0 ms',
                                          style: TextStyle(
                                            color: theme.subTextColor,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '当前进度: ',
                                              style: TextStyle(
                                                color: theme.subTextColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '$msStr ms / 1000 ms',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '1000 ms',
                                          style: TextStyle(
                                            color: theme.subTextColor,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    LayoutBuilder(
                                      builder: (context, barConstraints) {
                                        return Stack(
                                          children: [
                                            Container(
                                              height: 8,
                                              width: barConstraints.maxWidth,
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 16),
                                              width: barConstraints.maxWidth * progress,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    // Scale ticks & numbers (0 - 10)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(11, (i) {
                                        final isMajor = i == 0 || i == 5 || i == 10;
                                        return Container(
                                          width: isMajor ? 2 : 1,
                                          height: isMajor ? 6 : 4,
                                          decoration: BoxDecoration(
                                            color: isMajor
                                                ? theme.subTextColor.withValues(alpha: 0.6)
                                                : theme.subTextColor.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(11, (i) {
                                        final isMajor = i == 0 || i == 5 || i == 10;
                                        return SizedBox(
                                          width: 14,
                                          child: Text(
                                            '$i',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isMajor
                                                  ? theme.subTextColor.withValues(alpha: 0.8)
                                                  : theme.subTextColor.withValues(alpha: 0.4),
                                              fontSize: 10,
                                              fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Metric info badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Text(
                                  '往返延迟 RTT: ${rtt}ms  |  授时偏差: ${(offset / 1000).toStringAsFixed(3)}s',
                                  style: TextStyle(
                                    color: theme.subTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '💡 下拉可重新发起极速授时同步校准',
                                style: TextStyle(
                                  color: theme.subTextColor.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Exit button top-left
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(Icons.arrow_back_rounded, color: theme.subTextColor),
                          tooltip: '返回',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
