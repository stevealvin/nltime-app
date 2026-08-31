/// 模型分类明细额度结构
class QuotaDetailItem {
  final String name;
  final String providerGroup; // 'Gemini' | 'Claude' | 'OpenAI' | 'Other'
  final double remainingPercentage;
  final int secondsRemaining;
  final String nextResetTime;

  QuotaDetailItem({
    required this.name,
    required this.providerGroup,
    required this.remainingPercentage,
    required this.secondsRemaining,
    required this.nextResetTime,
  });

  factory QuotaDetailItem.fromJson(Map<String, dynamic> json) {
    return QuotaDetailItem(
      name: json['name']?.toString() ?? '',
      providerGroup: json['providerGroup']?.toString() ?? '通用',
      remainingPercentage: (json['remainingPercentage'] as num?)?.toDouble() ?? 0.0,
      secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 0,
      nextResetTime: json['nextResetTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'providerGroup': providerGroup,
        'remainingPercentage': remainingPercentage,
        'secondsRemaining': secondsRemaining,
        'nextResetTime': nextResetTime,
      };
}

/// Token Plane 算力配额结构
class TokenPlaneQuota {
  final double usedPercentage;
  final double remainingPercentage;
  final String status; // 'healthy' | 'warning' | 'exhausted' | 'untested'
  final int resetIntervalHours;
  final int secondsRemaining;
  final String nextResetTime;
  final String? planType;
  final List<QuotaDetailItem> details;

  TokenPlaneQuota({
    required this.usedPercentage,
    required this.remainingPercentage,
    this.status = 'untested',
    required this.resetIntervalHours,
    required this.secondsRemaining,
    required this.nextResetTime,
    this.planType,
    this.details = const [],
  });

  factory TokenPlaneQuota.fromJson(Map<String, dynamic> json) {
    var detailList = <QuotaDetailItem>[];
    if (json['details'] is List) {
      detailList = (json['details'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => QuotaDetailItem.fromJson(e))
          .toList();
    }

    return TokenPlaneQuota(
      usedPercentage: (json['usedPercentage'] as num?)?.toDouble() ?? 0.0,
      remainingPercentage: (json['remainingPercentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'untested',
      resetIntervalHours: (json['resetIntervalHours'] as num?)?.toInt() ?? 5,
      secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 0,
      nextResetTime: json['nextResetTime']?.toString() ?? '',
      planType: json['planType']?.toString(),
      details: detailList,
    );
  }

  Map<String, dynamic> toJson() => {
        'usedPercentage': usedPercentage,
        'remainingPercentage': remainingPercentage,
        'status': status,
        'resetIntervalHours': resetIntervalHours,
        'secondsRemaining': secondsRemaining,
        'nextResetTime': nextResetTime,
        'planType': planType,
        'details': details.map((e) => e.toJson()).toList(),
      };
}

/// API Key 探针与速率限制结构
class ApiKeyQuotaInfo {
  final int? remainingRequests;
  final int? remainingTokens;
  final int? limitRequests;
  final int? limitTokens;
  final String? resetTimeStr;
  final int? latencyMs;
  final String? statusMessage;

  ApiKeyQuotaInfo({
    this.remainingRequests,
    this.remainingTokens,
    this.limitRequests,
    this.limitTokens,
    this.resetTimeStr,
    this.latencyMs,
    this.statusMessage,
  });

  factory ApiKeyQuotaInfo.fromJson(Map<String, dynamic> json) {
    return ApiKeyQuotaInfo(
      remainingRequests: (json['remainingRequests'] as num?)?.toInt(),
      remainingTokens: (json['remainingTokens'] as num?)?.toInt(),
      limitRequests: (json['limitRequests'] as num?)?.toInt(),
      limitTokens: (json['limitTokens'] as num?)?.toInt(),
      resetTimeStr: json['resetTimeStr']?.toString(),
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      statusMessage: json['statusMessage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'remainingRequests': remainingRequests,
        'remainingTokens': remainingTokens,
        'limitRequests': limitRequests,
        'limitTokens': limitTokens,
        'resetTimeStr': resetTimeStr,
        'latencyMs': latencyMs,
        'statusMessage': statusMessage,
      };
}

/// 通用算力资源与 API Key 配置模型
class ApiKeyConfig {
  final String id;
  final String name;
  final String type; // 'token-plane' | 'api-key'
  final String provider; // 'google-antigravity' | 'openai-codex' | 'openai-compatible' | 'google-aistudio' | 'generic'
  final String baseUrl;
  final String? apiKey;
  final String? refreshToken;
  final String? accessToken;
  final String status; // 'active' | 'error' | 'untested'
  final String? lastTestedAt;
  final String? email;
  final TokenPlaneQuota? tokenQuota;
  final ApiKeyQuotaInfo? quotaInfo;
  final dynamic rawQuotaData;

  ApiKeyConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
    required this.baseUrl,
    this.apiKey,
    this.refreshToken,
    this.accessToken,
    this.status = 'untested',
    this.lastTestedAt,
    this.email,
    this.tokenQuota,
    this.quotaInfo,
    this.rawQuotaData,
  });

  factory ApiKeyConfig.fromJson(Map<String, dynamic> json) {
    return ApiKeyConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'token-plane',
      provider: json['provider']?.toString() ?? 'generic',
      baseUrl: json['baseUrl']?.toString() ?? '',
      apiKey: json['apiKey']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      accessToken: json['accessToken']?.toString(),
      status: json['status']?.toString() ?? 'untested',
      lastTestedAt: json['lastTestedAt']?.toString(),
      email: json['email']?.toString(),
      tokenQuota: json['tokenQuota'] != null ? TokenPlaneQuota.fromJson(json['tokenQuota']) : null,
      quotaInfo: json['quotaInfo'] != null ? ApiKeyQuotaInfo.fromJson(json['quotaInfo']) : null,
      rawQuotaData: json['rawQuotaData'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'provider': provider,
        'baseUrl': baseUrl,
        if (apiKey != null) 'apiKey': apiKey,
        if (refreshToken != null) 'refreshToken': refreshToken,
        if (accessToken != null) 'accessToken': accessToken,
        'status': status,
        if (lastTestedAt != null) 'lastTestedAt': lastTestedAt,
        if (email != null) 'email': email,
        if (tokenQuota != null) 'tokenQuota': tokenQuota!.toJson(),
        if (quotaInfo != null) 'quotaInfo': quotaInfo!.toJson(),
        if (rawQuotaData != null) 'rawQuotaData': rawQuotaData,
      };

  ApiKeyConfig copyWith({
    String? id,
    String? name,
    String? type,
    String? provider,
    String? baseUrl,
    String? apiKey,
    String? refreshToken,
    String? accessToken,
    String? status,
    String? lastTestedAt,
    String? email,
    TokenPlaneQuota? tokenQuota,
    ApiKeyQuotaInfo? quotaInfo,
  }) {
    return ApiKeyConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      refreshToken: refreshToken ?? this.refreshToken,
      accessToken: accessToken ?? this.accessToken,
      status: status ?? this.status,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      email: email ?? this.email,
      tokenQuota: tokenQuota ?? this.tokenQuota,
      quotaInfo: quotaInfo ?? this.quotaInfo,
      rawQuotaData: rawQuotaData,
    );
  }
}
