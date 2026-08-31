import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../views/app_webview_page.dart';
import '../models/drop_message_model.dart';
import '../services/drop_service.dart';

/// OmniDrop 流转空间主页面 (Apple AirDrop 风格高颜值流转中枢)
class DropPage extends StatefulWidget {
  const DropPage({super.key});

  @override
  State<DropPage> createState() => _DropPageState();
}

class _DropPageState extends State<DropPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    DropService.init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    DropService.sendText(text);
    _textController.clear();
  }

  Future<void> _handlePasteAndSend() async {
    HapticFeedback.mediumImpact();
    final ok = await DropService.pasteAndSend();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('剪贴板为空或无有效文本')),
      );
    }
  }

  Future<void> _handlePickImage() async {
    HapticFeedback.lightImpact();
    await DropService.pickAndSendImage();
  }

  void _showRoomDialog() {
    final codeCtrl = TextEditingController(text: DropService.roomCodeNotifier.value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('空间房间管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('输入 4 位数字口令加入已有空间，或重新创建空间：', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '如: 8888',
                counterText: '',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newCode = DropService.generateNewRoom();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已随机创建新空间: $newCode')),
              );
            },
            child: const Text('随机新房间'),
          ),
          FilledButton(
            onPressed: () {
              final val = codeCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                DropService.joinRoom(val);
              }
            },
            child: const Text('加入/连接'),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(String roomCode) {
    final joinUrl = 'https://om.nle.lol/drop?room=$roomCode';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text('空间口令: $roomCode')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: joinUrl,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '在电脑浏览器打开 Web 端 OmniDrop 并输入此口令，即可自动 P2P 打洞直连。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: roomCode));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已复制口令: $roomCode')),
              );
            },
            child: const Text('复制口令'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // 1. 顶部空间状态面板
          _buildHeaderStatusCard(context, isDark),

          // 2. 快捷操作工具栏
          _buildQuickActionBar(context, isDark),

          // 3. 流转时间轴与消息列表
          Expanded(
            child: _buildMessageFeed(context, isDark),
          ),

          // 4. 底部发送输入栏
          _buildBottomInputBar(context, isDark),
        ],
      ),
    );
  }

  /// 1. 顶部空间状态面板 (AirDrop 纯净面材质)
  Widget _buildHeaderStatusCard(BuildContext context, bool isDark) {
    return ValueListenableBuilder<String>(
      valueListenable: DropService.roomCodeNotifier,
      builder: (context, roomCode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: DropService.statusNotifier,
          builder: (context, status, _) {
            return ValueListenableBuilder<int?>(
              valueListenable: DropService.latencyNotifier,
              builder: (context, latency, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: DropService.statusTipNotifier,
                  builder: (context, tip, _) {
                    final isConnected = status == 'connected';

                    Color statusColor;
                    String statusBadgeText;
                    if (isConnected) {
                      statusColor = AppColors.success;
                      statusBadgeText = latency != null ? 'P2P 直连 (${latency}ms)' : 'P2P 直连';
                    } else if (status == 'connecting') {
                      statusColor = AppColors.warning;
                      statusBadgeText = '连接中...';
                    } else if (status == 'error') {
                      statusColor = AppColors.danger;
                      statusBadgeText = '连接异常';
                    } else {
                      statusColor = AppColors.accentSky;
                      statusBadgeText = '等待配对';
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        borderRadius: 18,
                        child: Row(
                          children: [
                            // 房间号大徽章
                            GestureDetector(
                              onTap: _showRoomDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.radio, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      roomCode.isEmpty ? '----' : roomCode,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.chevronDown, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 连接状态与提示文案
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: statusColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withValues(alpha: 0.6),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        statusBadgeText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tip,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // 扫码与换房动作
                            IconButton(
                              icon: const Icon(LucideIcons.qrCode, size: 18),
                              tooltip: '查看口令二维码',
                              onPressed: () => _showQrDialog(roomCode),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.refreshCw, size: 16),
                              tooltip: '重连/切换空间',
                              onPressed: _showRoomDialog,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// 2. 快捷操作工具栏
  Widget _buildQuickActionBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // 粘贴剪贴板
          Expanded(
            child: _buildActionPill(
              icon: LucideIcons.clipboardPaste,
              label: '粘贴剪贴板',
              color: AppColors.primary,
              isDark: isDark,
              onTap: _handlePasteAndSend,
            ),
          ),
          const SizedBox(width: 8),

          // 发送图片
          Expanded(
            child: _buildActionPill(
              icon: LucideIcons.image,
              label: '发送图片',
              color: AppColors.accentSky,
              isDark: isDark,
              onTap: _handlePickImage,
            ),
          ),
          const SizedBox(width: 8),

          // 清空记录
          _buildActionIconButton(
            icon: LucideIcons.trash2,
            tooltip: '清空流转记录',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              DropService.clearHistory();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        borderRadius: 14,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        borderRadius: 14,
        child: Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
    );
  }

  /// 3. 流转消息流列表
  Widget _buildMessageFeed(BuildContext context, bool isDark) {
    return ValueListenableBuilder<List<DropMessageModel>>(
      valueListenable: DropService.messagesNotifier,
      builder: (context, messages, _) {
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.radioTower,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '流转空间已就绪',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '在 Web 端与 App 端打开相同房间号\n文字、链接、图片或文件即可毫秒级双向流转',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return _buildMessageItem(context, msg, isDark);
          },
        );
      },
    );
  }

  /// 单条流转气泡
  Widget _buildMessageItem(BuildContext context, DropMessageModel msg, bool isDark) {
    final isSelf = msg.sender == 'self';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.accentSky.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.monitor, size: 14, color: AppColors.accentSky),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 气泡主体
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelf
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSelf ? 16 : 4),
                      bottomRight: Radius.circular(isSelf ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildBubbleContent(context, msg, isSelf, isDark),
                ),
                const SizedBox(height: 3),

                // 时间与发送状态
                Text(
                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}:${msg.timestamp.second.toString().padLeft(2, '0')} · ${isSelf ? '已发出' : '已接收'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.smartphone, size: 14, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  /// 气泡内部内容
  Widget _buildBubbleContent(BuildContext context, DropMessageModel msg, bool isSelf, bool isDark) {
    final textColor = isSelf ? Colors.white : (isDark ? Colors.white : AppColors.lightTextPrimary);

    // 图片类型
    if (msg.type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.content.startsWith('data:image')) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(msg.content.split(',').last),
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          ] else if (msg.content.startsWith('http')) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                msg.content,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          ] else ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.image, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(msg.fileName ?? '图片文件', style: TextStyle(color: textColor, fontSize: 13)),
              ],
            ),
          ],
        ],
      );
    }

    // 链接类型
    if (msg.type == 'link') {
      return GestureDetector(
        onTap: () => AppWebViewPage.open(context, url: msg.content, title: '流转链接'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.externalLink, size: 14, color: textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                msg.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 文件类型
    if (msg.type == 'file') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.file, size: 16, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.fileName ?? '未知文件',
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (msg.fileSize != null)
                  Text(
                    '${(msg.fileSize! / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // 默认纯文本
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: msg.content));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制文本到剪贴板'), duration: Duration(seconds: 1)),
        );
      },
      child: Text(
        msg.content,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  /// 4. 底部输入与发送栏
  Widget _buildBottomInputBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 图片选取按钮
          IconButton(
            icon: const Icon(LucideIcons.imagePlus, size: 20),
            color: AppColors.primary,
            tooltip: '发送图片',
            onPressed: _handlePickImage,
          ),
          const SizedBox(width: 4),

          // 文本输入框
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: '输入要同步流转的内容或链接...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),

          // 发送按钮
          IconButton.filled(
            icon: const Icon(LucideIcons.send, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
