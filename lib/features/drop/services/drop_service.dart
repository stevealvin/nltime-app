import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peerdart/peerdart.dart';
import '../../../core/storage/app_storage.dart';
import '../models/drop_message_model.dart';

/// WebRTC P2P 流转空间核心服务 (OmniDrop Service)
/// 与 OmniFlow Web 端 PeerJS 100% 同构通信与多模态流转
class DropService {
  DropService._();

  static const String peerPrefix = 'omniflow-p2p-';

  static final ValueNotifier<String> roomCodeNotifier = ValueNotifier<String>('');
  static final ValueNotifier<bool> isHostNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> statusNotifier = ValueNotifier<String>('idle'); // 'idle', 'connecting', 'connected', 'disconnected', 'error'
  static final ValueNotifier<int?> latencyNotifier = ValueNotifier<int?>(null);
  static final ValueNotifier<List<DropMessageModel>> messagesNotifier = ValueNotifier<List<DropMessageModel>>([]);
  static final ValueNotifier<String> statusTipNotifier = ValueNotifier<String>('准备连接');
  static final ValueNotifier<String?> connectedPeerNotifier = ValueNotifier<String?>(null);

  static Peer? _peer;
  static DataConnection? _connection;
  static Timer? _heartbeatTimer;
  static final List<StreamSubscription> _subscriptions = [];

  // 文件接收缓冲区: fileId -> Chunks
  static final Map<String, _FileBuffer> _fileBuffers = {};

  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.qq.com:3478'},
      {'urls': 'stun:stun.miwifi.com:3478'},
      {'urls': 'stun:stun.chat.bilibili.com:3478'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  /// 初始化空间
  static void init() {
    final lastCode = AppStorage.getLastRoomCode();
    if (lastCode != null && lastCode.isNotEmpty) {
      roomCodeNotifier.value = lastCode;
      createRoom(lastCode);
    } else {
      generateNewRoom();
    }
  }

  /// 随机生成 4 位房间号并作为 Host 创建空间
  static String generateNewRoom() {
    final code = (1000 + Random().nextInt(9000)).toString();
    createRoom(code);
    return code;
  }

  /// 创建/成为 Host 空间
  static void createRoom(String code) {
    final clean = code.trim();
    if (clean.isEmpty) return;

    _cleanup();
    roomCodeNotifier.value = clean;
    isHostNotifier.value = true;
    statusNotifier.value = 'connecting';
    statusTipNotifier.value = '正在注册空间信令...';
    AppStorage.setLastRoomCode(clean);

    try {
      final hostPeerId = '$peerPrefix$clean';
      _peer = Peer(
        id: hostPeerId,
        options: PeerOptions(
          config: _iceConfig,
          debug: LogLevel.Errors,
        ),
      );

      final openSub = _peer!.on('open').listen(
        (id) {
          statusNotifier.value = 'connecting';
          statusTipNotifier.value = '空间就绪，等待对端加入...';
        },
        onError: (err) {
          statusNotifier.value = 'error';
          statusTipNotifier.value = '信令异常: $err';
        },
      );
      _subscriptions.add(openSub);

      final connSub = _peer!.on('connection').listen(
        (conn) {
          if (conn is DataConnection) {
            statusTipNotifier.value = '检测到对端连入，正在建立直连...';
            _setupConnectionHandlers(conn);
          }
        },
        onError: (err) {
          if (kDebugMode) print('OmniDrop connection event error: $err');
        },
      );
      _subscriptions.add(connSub);

      final errSub = _peer!.on('error').listen(
        (err) {
          final errStr = err.toString();
          if (errStr.contains('unavailable-id')) {
            // 空间已被注册，平滑降级作为 Client 加入
            joinRoom(clean);
          } else {
            statusNotifier.value = 'error';
            statusTipNotifier.value = '连接异常: $errStr';
          }
        },
        onError: (err) {
          statusNotifier.value = 'error';
          statusTipNotifier.value = '错误事件异常: $err';
        },
      );
      _subscriptions.add(errSub);
    } catch (e) {
      statusNotifier.value = 'error';
      statusTipNotifier.value = '初始化失败: $e';
    }
  }

  /// 加入已有空间 (Client)
  static void joinRoom(String code) {
    final clean = code.trim();
    if (clean.isEmpty) return;

    _cleanup();
    roomCodeNotifier.value = clean;
    isHostNotifier.value = false;
    statusNotifier.value = 'connecting';
    statusTipNotifier.value = '正在连入空间 $clean...';
    AppStorage.setLastRoomCode(clean);

    try {
      final randomSuffix = (1000 + Random().nextInt(9000)).toString();
      final clientPeerId = '${peerPrefix}client-$randomSuffix-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

      _peer = Peer(
        id: clientPeerId,
        options: PeerOptions(
          config: _iceConfig,
          debug: LogLevel.Errors,
        ),
      );

      final openSub = _peer!.on('open').listen(
        (id) {
          final targetPeerId = '$peerPrefix$clean';
          statusTipNotifier.value = '信令已连接，正在进行 P2P 打洞握手...';
          try {
            final conn = _peer!.connect(targetPeerId);
            _setupConnectionHandlers(conn);
          } catch (e) {
            statusNotifier.value = 'error';
            statusTipNotifier.value = '握手发起失败: $e';
          }
        },
        onError: (err) {
          statusNotifier.value = 'error';
          statusTipNotifier.value = '信令连接失败: $err';
        },
      );
      _subscriptions.add(openSub);

      final errSub = _peer!.on('error').listen(
        (err) {
          statusNotifier.value = 'error';
          statusTipNotifier.value = '加入失败: $err';
        },
        onError: (err) {
          statusNotifier.value = 'error';
          statusTipNotifier.value = '网络异常: $err';
        },
      );
      _subscriptions.add(errSub);
    } catch (e) {
      statusNotifier.value = 'error';
      statusTipNotifier.value = '客户端初始化失败: $e';
    }
  }

  /// 配置 P2P 数据连接监听
  static void _setupConnectionHandlers(DataConnection conn) {
    _connection = conn;
    connectedPeerNotifier.value = conn.peer;

    final openSub = conn.on('open').listen(
      (_) {
        statusNotifier.value = 'connected';
        statusTipNotifier.value = 'P2P 直连已建立';

        // 发送原生 Map 握手问候包 (与 Web 端对象严格匹配)
        _sendMap({
          'type': 'hello',
          'sender': isHostNotifier.value ? 'host' : 'client',
        });

        _startHeartbeat();
      },
      onError: (err) {
        statusNotifier.value = 'disconnected';
        statusTipNotifier.value = '握手失败: $err';
        _stopHeartbeat();
      },
    );
    _subscriptions.add(openSub);

    final dataSub = conn.on('data').listen(
      (raw) {
        _handleIncomingData(raw);
      },
      onError: (err) {
        if (kDebugMode) print('OmniDrop data stream error: $err');
      },
    );
    _subscriptions.add(dataSub);

    final closeSub = conn.on('close').listen(
      (_) {
        statusNotifier.value = isHostNotifier.value ? 'connecting' : 'disconnected';
        statusTipNotifier.value = isHostNotifier.value ? '对端已离开，等待新连接...' : '与对端连接已断开';
        connectedPeerNotifier.value = null;
        _stopHeartbeat();
      },
      onError: (err) {
        statusNotifier.value = 'disconnected';
        connectedPeerNotifier.value = null;
        _stopHeartbeat();
      },
    );
    _subscriptions.add(closeSub);

    final errSub = conn.on('error').listen(
      (err) {
        statusNotifier.value = 'disconnected';
        statusTipNotifier.value = '通道错误: $err';
        _stopHeartbeat();
      },
      onError: (err) {
        statusNotifier.value = 'disconnected';
        _stopHeartbeat();
      },
    );
    _subscriptions.add(errSub);
  }

  /// 启动心跳测速
  static void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_connection != null) {
        _sendMap({
          'type': 'ping',
          'time': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  /// 停止心跳
  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    latencyNotifier.value = null;
  }

  /// 统一原生发送 Map 数据
  static void _sendMap(Map<String, dynamic> payload) {
    if (_connection == null) return;
    try {
      // 1. 发送标准 JSON 字符串 (跨端无损兼容性最高)
      _connection!.send(jsonEncode(payload));
    } catch (e) {
      if (kDebugMode) print('OmniDrop send json string error: $e');
    }
  }

  /// 接收并解析数据 (全兼容 Map, JSON String 及二进制字节流)
  static void _handleIncomingData(dynamic raw) {
    try {
      Map<String, dynamic>? data;
      if (raw is Map) {
        data = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            data = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      } else if (raw is List<int>) {
        try {
          final decoded = jsonDecode(utf8.decode(raw));
          if (decoded is Map) {
            data = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      if (data == null) return;

      final type = data['type'] as String?;

      if (type == 'hello') {
        statusNotifier.value = 'connected';
        statusTipNotifier.value = 'P2P 直连已建立';
        return;
      }

      if (type == 'ping') {
        final time = data['time'];
        _sendMap({'type': 'pong', 'time': time});
        return;
      }

      if (type == 'pong') {
        final sendTime = data['time'] as num?;
        if (sendTime != null) {
          latencyNotifier.value = max(1, DateTime.now().millisecondsSinceEpoch - sendTime.toInt());
        }
        return;
      }

      // 剪贴板文本 / 图片 / 链接流转
      if (type == 'clipboard') {
        final msgId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        // 幂等防重
        if (messagesNotifier.value.any((m) => m.id == msgId)) {
          return;
        }

        final content = data['content']?.toString() ?? '';
        final contentType = data['contentType']?.toString() ?? 'text';
        final fileName = data['fileName']?.toString();
        final fileSize = data['size'] as num?;
        final timestampMs = data['timestamp'] as num?;
        final time = timestampMs != null
            ? DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt())
            : DateTime.now();

        final msg = DropMessageModel(
          id: msgId,
          type: contentType,
          content: content,
          fileName: fileName,
          fileSize: fileSize,
          sender: 'peer',
          timestamp: time,
          status: 'received',
        );

        messagesNotifier.value = [msg, ...messagesNotifier.value];
        return;
      }

      // 文件分片接收
      if (type == 'file-start') {
        final fileId = data['fileId']?.toString() ?? '';
        final fileName = data['fileName']?.toString() ?? 'unknown_file';
        final fileSize = data['fileSize'] as num? ?? 0;
        final totalChunks = data['totalChunks'] as int? ?? 1;
        final mimeType = data['mimeType']?.toString() ?? 'application/octet-stream';

        _fileBuffers[fileId] = _FileBuffer(
          fileId: fileId,
          fileName: fileName,
          fileSize: fileSize,
          totalChunks: totalChunks,
          mimeType: mimeType,
        );
        return;
      }

      if (type == 'file-chunk') {
        final fileId = data['fileId']?.toString() ?? '';
        final chunkIndex = data['chunkIndex'] as int? ?? 0;
        final chunkData = data['chunkData'];
        final buffer = _fileBuffers[fileId];
        if (buffer != null && chunkData != null) {
          buffer.chunks[chunkIndex] = chunkData;
        }
        return;
      }

      if (type == 'file-end') {
        final fileId = data['fileId']?.toString() ?? '';
        final buffer = _fileBuffers.remove(fileId);
        if (buffer != null) {
          final isImage = buffer.mimeType.startsWith('image/');
          final msg = DropMessageModel(
            id: fileId,
            type: isImage ? 'image' : 'file',
            content: isImage ? '' : buffer.fileName,
            fileName: buffer.fileName,
            fileSize: buffer.fileSize,
            sender: 'peer',
            timestamp: DateTime.now(),
            status: 'received',
          );
          messagesNotifier.value = [msg, ...messagesNotifier.value];
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) print('OmniDrop handleIncomingData error: $e');
    }
  }

  /// 发送文本或链接
  static Future<void> sendText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final isUrl = clean.startsWith('http://') || clean.startsWith('https://');
    final msg = DropMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: isUrl ? 'link' : 'text',
      content: clean,
      sender: 'self',
      timestamp: DateTime.now(),
      status: 'sent',
    );

    messagesNotifier.value = [msg, ...messagesNotifier.value];

    _sendMap({
      'type': 'clipboard',
      'id': msg.id,
      'contentType': msg.type,
      'content': msg.content,
      'sender': 'peer',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 一键读取系统剪贴板并发送
  static Future<bool> pasteAndSend() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.trim().isNotEmpty) {
      await sendText(text);
      return true;
    }
    return false;
  }

  /// 选取本地图片并发送 (Base64 DataURL)
  static Future<bool> pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return false;

      final bytes = await image.readAsBytes();
      final base64Str = base64Encode(bytes);
      final mimeType = image.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Str';

      final msg = DropMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'image',
        content: dataUrl,
        fileName: image.name,
        fileSize: bytes.length,
        sender: 'self',
        timestamp: DateTime.now(),
        status: 'sent',
      );

      messagesNotifier.value = [msg, ...messagesNotifier.value];

      _sendMap({
        'type': 'clipboard',
        'id': msg.id,
        'contentType': 'image',
        'content': dataUrl,
        'fileName': image.name,
        'size': bytes.length,
        'sender': 'peer',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('OmniDrop pick image error: $e');
      return false;
    }
  }

  /// 清空当前流转历史
  static void clearHistory() {
    messagesNotifier.value = [];
  }

  /// 清理并释放资源
  static void _cleanup() {
    _stopHeartbeat();
    for (final sub in _subscriptions) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _subscriptions.clear();

    if (_connection != null) {
      try {
        _connection!.close();
      } catch (_) {}
      _connection = null;
    }
    if (_peer != null) {
      try {
        _peer!.dispose();
      } catch (_) {}
      _peer = null;
    }
    connectedPeerNotifier.value = null;
    statusNotifier.value = 'idle';
  }

  /// 释放服务资源
  static void dispose() {
    _cleanup();
  }
}

class _FileBuffer {
  final String fileId;
  final String fileName;
  final num fileSize;
  final int totalChunks;
  final String mimeType;
  final Map<int, dynamic> chunks = {};

  _FileBuffer({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.mimeType,
  });
}
