import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../models/app_item_model.dart';

/// 应用分享二维码弹窗
class AppQrDialog extends StatelessWidget {
  final AppItemModel app;

  const AppQrDialog({super.key, required this.app});

  static void show(BuildContext context, AppItemModel app) {
    showDialog(
      context: context,
      builder: (context) => AppQrDialog(app: app),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrData = app.url ?? app.fileUrl ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(LucideIcons.qrCode, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (qrData.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('该应用暂无有效直达链接或下载地址'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightCardBorder),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '使用手机或其他设备扫码直达',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              qrData,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.primary,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
      actions: [
        if (qrData.isNotEmpty)
          TextButton.icon(
            icon: const Icon(LucideIcons.copy, size: 16),
            label: const Text('复制链接'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrData));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制链接到剪贴板')),
              );
            },
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
