import 'dart:async';
import 'package:flutter/material.dart';

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

/// Stopwatch page — pure content widget, no inner Scaffold.
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
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

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
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
    final d = Duration(milliseconds: ms);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms3 = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s.$ms3';
  }

  String _formatLapMs(int ms) {
    final d = Duration(milliseconds: ms);
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms3 = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$m:$s.$ms3';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          _buildDisplayCard(context),
          const SizedBox(height: 20),
          _buildControlButtons(context),
          const SizedBox(height: 20),
          Expanded(child: _buildLapsList(context)),
        ],
      ),
    );
  }

  Widget _buildDisplayCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = Duration(milliseconds: _elapsedMs);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$h:$m:$s',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: cs.onSurface,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '.',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: cs.primary,
                ),
              ),
              Text(
                ms,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(110, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          onPressed: _isRunning ? _addLap : _reset,
          icon: Icon(_isRunning ? Icons.flag_rounded : Icons.rotate_left_rounded,
              size: 18),
          label: Text(_isRunning ? '计圈' : '重置'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(150, 52),
            backgroundColor: _isRunning ? Colors.amber[700] : cs.primary,
            foregroundColor: _isRunning ? Colors.white : cs.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          onPressed: _isRunning ? _pause : _start,
          icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20),
          label: Text(
            _isRunning ? '暂停' : '开始计时',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLapsList(BuildContext context) {
    if (_laps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_list_numbered_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 10),
            Text(
              '点击"计圈"添加分段记录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
    }

    int? minLap, maxLap;
    if (_laps.length > 1) {
      final times = _laps.map((e) => e.lapTimeMs).toList();
      minLap = times.reduce((a, b) => a < b ? a : b);
      maxLap = times.reduce((a, b) => a > b ? a : b);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _laps.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final lap = _laps[index];
          final isFastest = minLap != null && lap.lapTimeMs == minLap;
          final isSlowest = maxLap != null && lap.lapTimeMs == maxLap;
          final lapColor = isFastest
              ? Colors.greenAccent
              : isSlowest
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.onSurface;

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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isFastest) ...[
                      const SizedBox(width: 8),
                      _LapBadge(label: '最快', color: Colors.green),
                    ],
                    if (isSlowest) ...[
                      const SizedBox(width: 8),
                      _LapBadge(label: '最慢', color: Colors.red),
                    ],
                  ],
                ),
                Text(
                  '+${_formatLapMs(lap.lapTimeMs)}',
                  style: TextStyle(
                    color: lapColor,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatMs(lap.totalTimeMs),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
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

class _LapBadge extends StatelessWidget {
  final String label;
  final MaterialColor color;
  const _LapBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color.shade300, fontSize: 10),
      ),
    );
  }
}
