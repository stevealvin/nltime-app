import 'package:intl/intl.dart';

/// OmniFlow 倒计时与格式化通用工具类
class CountdownHelper {
  CountdownHelper._();

  /// 从 nextResetTime 字符串 (如 "2026-08-31 22:30:00" 或 ISO 字符串) 动态计算剩余秒数
  static int getRemainingSeconds(String? nextResetTime, [int? fallbackSeconds]) {
    if (nextResetTime == null || nextResetTime.isEmpty || nextResetTime == '无需重置') {
      return (fallbackSeconds != null && fallbackSeconds > 0) ? fallbackSeconds : 0;
    }

    try {
      final target = DateTime.parse(nextResetTime.replaceAll(' ', 'T'));
      final diff = target.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return (fallbackSeconds != null && fallbackSeconds > 0) ? fallbackSeconds : 0;
    }
  }

  /// 格式化倒计时显示 (如 "4时 23分 15秒" 或 "2日 5时 10分")
  static String formatCountdown(int totalSeconds) {
    if (totalSeconds <= 0) return '已重置 / 就绪';

    final days = totalSeconds ~/ 86400;
    final hrs = (totalSeconds % 86400) ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days日');
    if (hrs > 0 || days > 0) parts.add('$hrs时');
    if (mins > 0 || hrs > 0 || days > 0) parts.add('$mins分');
    parts.add('$secs秒');

    return parts.join(' ');
  }

  /// 脱敏 API Key (如 "sk-ab••••••••xyz")
  static String maskApiKey(String? key) {
    if (key == null || key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    final start = key.length > 6 ? key.substring(0, 4) : key.substring(0, 2);
    final end = key.substring(key.length - 4);
    return '$start••••••••$end';
  }

  /// 脱敏邮箱 (如 "ste••••@example.com")
  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) {
      return '$name***@$domain';
    }
    return '${name.substring(0, 3)}***@$domain';
  }

  /// 格式化文件大小
  static String formatFileSize(num? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${suffixes[i]}';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}
