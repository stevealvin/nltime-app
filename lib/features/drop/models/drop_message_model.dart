/// 流转空间消息模型
class DropMessageModel {
  final String id;
  final String type; // 'text' | 'link' | 'image' | 'file'
  final String content;
  final String? fileName;
  final num? fileSize;
  final String sender; // 'self' | 'peer'
  final DateTime timestamp;
  final String status; // 'sending' | 'sent' | 'received' | 'error'

  DropMessageModel({
    required this.id,
    required this.type,
    required this.content,
    this.fileName,
    this.fileSize,
    required this.sender,
    required this.timestamp,
    this.status = 'sent',
  });

  factory DropMessageModel.fromJson(Map<String, dynamic> json) {
    return DropMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString() ?? '',
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize'] as num?,
      sender: json['sender']?.toString() ?? 'self',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        'sender': sender,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': status,
      };
}
