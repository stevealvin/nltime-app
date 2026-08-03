import 'dart:async';
import 'package:flutter/material.dart';

import '../common/app_service.dart';
import '../common/theme_manager.dart';

class LapRecord {
  final int lapIndex;
  final int lapTimeMs;
  final int totalTimeMs;

  LapRecord({
    required this.lapIndex,
    required this.lapTimeMs,
    required this.totalTimeMs,
  });
}

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  Timer? _timer;
  bool _isRunning = false;
  int _elapsedMs = 0;
  int _lastLapTotalMs = 0;
  final List<LapRecord> _laps = [];

  void _startStopwatch() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    final startTime = DateTime.now().millisecondsSinceEpoch - _elapsedMs;

    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (mounted) {
        setState(() {
          _elapsedMs = DateTime.now().millisecondsSinceEpoch - startTime;
        });
      }
    });
  }

  void _pauseStopwatch() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetStopwatch() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedMs = 0;
      _lastLapTotalMs = 0;
      _laps.clear();
    });
  }

  void _addLap() {
    if (!_isRunning) return;
    final lapTime = _elapsedMs - _lastLapTotalMs;
    _lastLapTotalMs = _elapsedMs;
    setState(() {
      _laps.insert(
        0,
        LapRecord(
          lapIndex: _laps.length + 1,
          lapTimeMs: lapTime,
          totalTimeMs: _elapsedMs,
        ),
      );
    });
  }

  String _formatMs(int ms) {
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  String _formatLapMs(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$millis';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                Icon(Icons.timer_outlined, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '高精度毫秒秒表',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _buildDisplayCard(theme),
                const SizedBox(height: 20),
                _buildControlButtons(theme),
                const SizedBox(height: 20),
                Expanded(child: _buildLapsList(theme)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisplayCard(AppThemeData theme) {
    final duration = Duration(milliseconds: _elapsedMs);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$hours:$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: theme.textColor,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '.',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  millis,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Lap / Reset Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.cardColor,
            foregroundColor: theme.textColor,
            minimumSize: const Size(100, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor),
            ),
          ),
          onPressed: _isRunning ? _addLap : _resetStopwatch,
          child: Row(
            children: [
              Icon(_isRunning ? Icons.flag_rounded : Icons.rotate_left_rounded, size: 18),
              const SizedBox(width: 6),
              Text(_isRunning ? '计圈' : '重置'),
            ],
          ),
        ),
        // Start / Pause Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRunning ? Colors.amber[700] : theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(140, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          onPressed: _isRunning ? _pauseStopwatch : _startStopwatch,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                _isRunning ? '暂停' : '开始计时',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLapsList(AppThemeData theme) {
    if (_laps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.format_list_numbered_rounded, size: 40, color: theme.subTextColor.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              '点击“计圈”添加分段记录',
              style: TextStyle(color: theme.subTextColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Find fastest & slowest laps if > 1 lap
    int? minLap;
    int? maxLap;
    if (_laps.length > 1) {
      final lapTimes = _laps.map((e) => e.lapTimeMs).toList();
      minLap = lapTimes.reduce((a, b) => a < b ? a : b);
      maxLap = lapTimes.reduce((a, b) => a > b ? a : b);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _laps.length,
        separatorBuilder: (_, __) => Divider(color: theme.dividerColor, height: 1),
        itemBuilder: (context, index) {
          final lap = _laps[index];
          final isFastest = minLap != null && lap.lapTimeMs == minLap;
          final isSlowest = maxLap != null && lap.lapTimeMs == maxLap;

          Color itemColor = theme.textColor;
          if (isFastest) itemColor = Colors.greenAccent;
          if (isSlowest) itemColor = Colors.redAccent;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '计圈 ${lap.lapIndex.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: theme.subTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isFastest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('最快', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      ),
                    ],
                    if (isSlowest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('最慢', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '+${_formatLapMs(lap.lapTimeMs)}',
                  style: TextStyle(
                    color: itemColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatMs(lap.totalTimeMs),
                  style: TextStyle(
                    color: theme.subTextColor,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
