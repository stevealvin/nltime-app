import 'dart:convert';

enum TimeParseType {
  suning,      // {"currentTime": 1700000000000}
  taobao,      // {"api":"mtop.common.gettimestamp","data":{"t":"1700000000000"}}
  jd,          // {"currentTime2":"1700000000000"}
  timestampMs, // 毫秒时间戳: 1700000000000
  timestampSec,// 秒级时间戳: 1700000000
  iso8601,     // ISO 8601/RFC 3339 字符串: "2026-07-28T14:46:20.000Z"
  customKey,   // 自定义 JSON Key 提取
}

class TimeService {
  TimeService({
    required this.id,
    required this.name,
    required this.url,
    required this.isBuiltin,
    this.parseType = TimeParseType.timestampMs,
    this.customKey,
    this.description,
  });

  final String id;
  final String name;
  final String url;
  final bool isBuiltin;
  final TimeParseType parseType;
  final String? customKey;
  final String? description;

  /// Parses server response body into DateTime timestamp in milliseconds
  int? parseTimestampMs(String body) {
    try {
      final trimmed = body.trim();

      // Check ISO 8601 string directly
      if (parseType == TimeParseType.iso8601) {
        final parsedDate = DateTime.tryParse(trimmed);
        if (parsedDate != null) return parsedDate.millisecondsSinceEpoch;
      }

      // Check if raw numeric timestamp
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        final val = int.parse(trimmed);
        return val < 10000000000 ? val * 1000 : val;
      }

      final dynamic json = jsonDecode(trimmed);

      if (parseType == TimeParseType.suning) {
        if (json is Map && json.containsKey('currentTime')) {
          return int.parse(json['currentTime'].toString());
        }
      } else if (parseType == TimeParseType.taobao) {
        if (json is Map && json['data'] != null && json['data']['t'] != null) {
          return int.parse(json['data']['t'].toString());
        }
      } else if (parseType == TimeParseType.jd) {
        if (json is Map) {
          final timeStr = json['currentTime2'] ?? json['time'] ?? json['currentTime'];
          if (timeStr != null) return int.parse(timeStr.toString());
        }
      } else if (parseType == TimeParseType.customKey && customKey != null) {
        if (json is Map && json.containsKey(customKey)) {
          final val = json[customKey];
          if (val is int) return val < 10000000000 ? val * 1000 : val;
          if (val is String) {
            final parsedNum = int.tryParse(val);
            if (parsedNum != null) return parsedNum < 10000000000 ? parsedNum * 1000 : parsedNum;
            final parsedDate = DateTime.tryParse(val);
            if (parsedDate != null) return parsedDate.millisecondsSinceEpoch;
          }
        }
      }

      // Universal fallbacks for JSON objects
      if (json is Map) {
        for (final key in ['currentTime', 'timestamp', 'time', 't', 'sysTime', 'current_time', 'datetime']) {
          if (json.containsKey(key)) {
            final val = json[key];
            if (val is int) return val < 10000000000 ? val * 1000 : val;
            if (val is String) {
              final parsedNum = int.tryParse(val);
              if (parsedNum != null) return parsedNum < 10000000000 ? parsedNum * 1000 : parsedNum;
              final parsedDate = DateTime.tryParse(val);
              if (parsedDate != null) return parsedDate.millisecondsSinceEpoch;
            }
          }
        }
        if (json['data'] is Map) {
          final data = json['data'] as Map;
          for (final key in ['now', 't', 'time', 'timestamp', 'currentTime']) {
            if (data.containsKey(key)) {
              final val = data[key];
              if (val is int) return val < 10000000000 ? val * 1000 : val;
              if (val is String) {
                final parsedNum = int.tryParse(val);
                if (parsedNum != null) return parsedNum < 10000000000 ? parsedNum * 1000 : parsedNum;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'parseType': parseType.name,
        'customKey': customKey,
        'description': description,
      };

  static TimeService fromJson(Map<String, dynamic> json) {
    return TimeService(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      isBuiltin: false,
      parseType: TimeParseType.values.firstWhere(
        (e) => e.name == json['parseType'],
        orElse: () => TimeParseType.timestampMs,
      ),
      customKey: json['customKey'] as String?,
      description: json['description'] as String?,
    );
  }
}
