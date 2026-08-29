import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../common/app_service.dart';
import '../views/app_dialog.dart';
import 'app.dart';

/// Home page — pure content widget. No Scaffold, no AppBar.
/// Mounted inside AppPage's IndexedStack which provides the single root Scaffold.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();

    // Register the sync callback so AppPage's AppBar button can trigger it
    HomePageController.triggerSync = _triggerSync;

    // High-precision 10ms tick for smooth millisecond display
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
    HomePageController.triggerSync = null;
    super.dispose();
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    AppService.isSyncingNotifier.value = true;

    final res = await AppService.syncWithSelectedService();

    AppService.isSyncingNotifier.value = false;
    if (mounted) {
      setState(() => _isSyncing = false);
      AppDialog.showToast(
        context: context,
        theme: null,
        isError: !res.success,
        message: res.success
            ? '已与 [${res.serviceName}] 完成精准同步 (RTT: ${res.rttMs}ms)'
            : '同步失败: ${res.errorMessage ?? "网络连接超时"}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _triggerSync,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _TimeDisplayCard(currentTime: _currentTime),
          const SizedBox(height: 16),
          const _MetricsRow(),
          const SizedBox(height: 16),
          _MsProgressCard(currentTime: _currentTime),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _TimeDisplayCard extends StatelessWidget {
  final DateTime currentTime;
  const _TimeDisplayCard({required this.currentTime});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeStr = DateFormat('HH:mm:ss').format(currentTime);
    final msStr = currentTime.millisecond.toString().padLeft(3, '0');
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekdayStr = weekdays[(currentTime.weekday - 1).clamp(0, 6)];
    final dateStr = '${currentTime.year}年${currentTime.month.toString().padLeft(2, '0')}月${currentTime.day.toString().padLeft(2, '0')}日 $weekdayStr';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Large digital clock
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: cs.onSurface,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '.',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    msStr,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Last sync time
            ValueListenableBuilder<DateTime?>(
              valueListenable: AppService.lastSyncTimeNotifier,
              builder: (context, lastSync, _) {
                final label = lastSync != null
                    ? '上次授时同步: ${DateFormat('HH:mm:ss').format(lastSync)}'
                    : '尚未同步 · 下拉刷新立即校时';
                return Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppService.serverTimeOffsetNotifier,
        AppService.rttNotifier,
      ]),
      builder: (context, _) {
        final rtt = AppService.rttNotifier.value;
        final offset = AppService.serverTimeOffsetNotifier.value;
        final offsetSec = (offset / 1000).toStringAsFixed(3);
        final rttColor = rtt < 80 ? Colors.green : Colors.amber;

        return Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: '往返延迟 (RTT)',
                value: '$rtt ms',
                icon: Icons.wifi_rounded,
                iconColor: rttColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: '时间误差 (Offset)',
                value: '$offsetSec s',
                icon: Icons.balance_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      color: cs.onSurface.withValues(alpha: 0.55),
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
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MsProgressCard extends StatelessWidget {
  final DateTime currentTime;
  const _MsProgressCard({required this.currentTime});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msValue = currentTime.millisecond;
    final progress = msValue / 1000.0;
    final msStr = msValue.toString().padLeft(3, '0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 ms',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '当前进度: ',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: '$msStr ms / 1000 ms',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '1000 ms',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 6),
            _ProgressScale(color: cs.onSurface),
          ],
        ),
      ),
    );
  }
}

class _ProgressScale extends StatelessWidget {
  final Color color;
  const _ProgressScale({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scale tick marks (0 to 10)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(11, (i) {
            final isMajor = i == 0 || i == 5 || i == 10;
            return Container(
              width: isMajor ? 2 : 1,
              height: isMajor ? 6 : 4,
              decoration: BoxDecoration(
                color: isMajor
                    ? color.withValues(alpha: 0.6)
                    : color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        // Scale numbers (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
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
                      ? color.withValues(alpha: 0.75)
                      : color.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: isMajor ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
