/// 应用产品与微服务矩阵模型
class AppItemModel {
  final String id;
  final String name;
  final String? version;
  final String platform; // 'Android' | 'iOS' | 'Windows' | 'macOS' | 'Web' | '通用'
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final String? url;
  final String? description;
  final String? icon;
  final List<String> tags;
  final String? createdAt;
  final String? updatedAt;

  AppItemModel({
    required this.id,
    required this.name,
    this.version,
    this.platform = '通用',
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.url,
    this.description,
    this.icon,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AppItemModel.fromJson(Map<String, dynamic> json) {
    return AppItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      version: json['version']?.toString(),
      platform: json['platform']?.toString() ?? '通用',
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize']?.toString(),
      url: json['url']?.toString(),
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (version != null) 'version': version,
        'platform': platform,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (url != null) 'url': url,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        'tags': tags,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
