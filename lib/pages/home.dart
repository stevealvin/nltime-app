import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../common/app_service.dart';
import '../common/theme_manager.dart';
import '../views/app_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _syncAnimController;

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // High precision tick every 10ms for smooth millisecond rendering
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final offset = AppService.serverTimeOffsetNotifier.value;
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now().add(Duration(milliseconds: offset));
        });
      }
    });

    // Sync network time on launch
    _triggerSync();
  }

  @override
  void dispose() {
    _timer.cancel();
    _syncAnimController.dispose();
    super.dispose();
  }

  Future<void> _triggerSync() async {
    _syncAnimController.repeat();
    final res = await AppService.syncWithSelectedService();
    if (mounted) {
      _syncAnimController.stop();
      _syncAnimController.reset();
      final theme = ThemeManager.getTheme(AppService.themeIndexNotifier.value);
      AppDialog.showToast(
        context: context,
        theme: theme,
        isError: !res.success,
        message: res.success
            ? '已与 [${res.serviceName}] 完成精准同步 (RTT: ${res.rttMs}ms)'
            : '同步失败: ${res.errorMessage ?? "网络连接超时"}',
      );
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.schedule_rounded, color: theme.primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  '极速对时',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: '全屏桌面时钟',
                icon: Icon(Icons.fullscreen_rounded, color: theme.textColor),
                onPressed: () => context.push('/fullscreen'),
              ),
              RotationTransition(
                turns: _syncAnimController,
                child: IconButton(
                  tooltip: '即时测速与同步',
                  icon: Icon(Icons.refresh_rounded, color: theme.primaryColor),
                  onPressed: _triggerSync,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            color: theme.primaryColor,
            backgroundColor: theme.cardColor,
            onRefresh: _triggerSync,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _buildTimeDisplayCard(theme),
                const SizedBox(height: 16),
                _buildMetricsCards(theme),
                const SizedBox(height: 16),
                _buildMsProgressCard(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Big Millisecond Digital Clock Card
  Widget _buildTimeDisplayCard(AppThemeData theme) {
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final msStr = (_currentTime.millisecond).toString().padLeft(3, '0');
    final dateStr = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(_currentTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Date & Weekday Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dateStr,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Large Digital Clock (HH:mm:ss . SSS)
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
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: theme.textColor,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '.',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  msStr,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sync status indicator text
          ValueListenableBuilder<DateTime?>(
            valueListenable: AppService.lastSyncTimeNotifier,
            builder: (context, lastSync, _) {
              final lastSyncStr = lastSync != null
                  ? DateFormat('HH:mm:ss').format(lastSync)
                  : '未同步';
              return Text(
                '上次授时同步: $lastSyncStr',
                style: TextStyle(fontSize: 12, color: theme.subTextColor),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Manual Source Selection Bar
  Widget _buildSourceSelectorCard(AppThemeData theme) {
    return ValueListenableBuilder<String>(
      valueListenable: AppService.activeServiceIdNotifier,
      builder: (context, activeId, _) {
        final services = AppService.timeServices;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radio_button_checked_rounded, size: 16, color: theme.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        '选择授时服务器源 (手动切换)',
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${services.length} 个可用源',
                    style: TextStyle(color: theme.subTextColor, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: services.map((service) {
                    final isSelected = service.id == activeId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: isSelected
                            ? Icon(Icons.check_rounded, size: 14, color: theme.bgColor)
                            : null,
                        label: Text(service.name),
                        labelStyle: TextStyle(
                          color: isSelected ? theme.bgColor : theme.textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selectedColor: theme.primaryColor,
                        backgroundColor: theme.bgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? theme.primaryColor
                                : theme.dividerColor,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            AppService.setCurrentTimeService(service.id);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Metrics Cards: RTT & Offset (Clean 2-column layout, precision rating removed)
  Widget _buildMetricsCards(AppThemeData theme) {
    return ValueListenableBuilder<int>(
      valueListenable: AppService.serverTimeOffsetNotifier,
      builder: (context, offset, _) {
        return ValueListenableBuilder<int>(
          valueListenable: AppService.rttNotifier,
          builder: (context, rtt, _) {
            final offsetSec = (offset / 1000).toStringAsFixed(3);

            return Row(
              children: [
                // RTT Card
                Expanded(
                  child: _buildMetricTile(
                    theme: theme,
                    title: '往返延迟 (RTT)',
                    value: '$rtt ms',
                    icon: Icons.wifi_rounded,
                    iconColor: rtt < 80 ? Colors.green : Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                // Offset Card
                Expanded(
                  child: _buildMetricTile(
                    theme: theme,
                    title: '时间误差 (Offset)',
                    value: '$offsetSec s',
                    icon: Icons.balance_rounded,
                    iconColor: theme.primaryColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricTile({
    required AppThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Millisecond Smooth Progress Bar Card (0 to 1000ms Tracker)
  Widget _buildMsProgressCard(AppThemeData theme) {
    final msValue = _currentTime.millisecond;
    final progress = msValue / 1000.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 ms',
                style: TextStyle(color: theme.subTextColor, fontSize: 11, fontFamily: 'monospace'),
              ),
              Row(
                children: [
                  Text(
                    '当前进度: ',
                    style: TextStyle(color: theme.subTextColor, fontSize: 12),
                  ),
                  Text(
                    '${msValue.toString().padLeft(3, '0')} ms / 1000 ms',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '1000 ms',
                style: TextStyle(color: theme.subTextColor, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: theme.bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
