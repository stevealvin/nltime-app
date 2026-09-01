import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../shared/views/app_webview_page.dart';
import '../models/app_item_model.dart';

/// 应用卡片组件
class AppCard extends StatelessWidget {
  final AppItemModel app;

  const AppCard({
    super.key,
    required this.app,
  });

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return LucideIcons.smartphone;
      case 'ios':
        return LucideIcons.apple;
      case 'web':
        return LucideIcons.globe;
      default:
        return LucideIcons.package;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return const Color(0xFF10B981);
      case 'ios':
        return const Color(0xFF64748B);
      case 'web':
        return AppColors.accentSky;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _handleOpenUrl(BuildContext context, String url, {bool forceExternal = false}) async {
    if (!forceExternal && (url.startsWith('http://') || url.startsWith('https://')) && !url.endsWith('.apk') && !url.endsWith('.zip')) {
      // 使用应用内 WebView 打开
      AppWebViewPage.open(context, url: url, title: app.name);
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw '无法打开链接';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platformColor = _getPlatformColor(app.platform);
    final hasUrl = app.url != null && app.url!.isNotEmpty;
    final hasFile = app.fileUrl != null && app.fileUrl!.isNotEmpty;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：应用图标 + 名称/版本 + 平台Badge + 更多菜单
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 应用图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: platformColor.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: app.icon != null && app.icon!.startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            app.icon!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              _getPlatformIcon(app.platform),
                              color: platformColor,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          _getPlatformIcon(app.platform),
                          color: platformColor,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // 应用名称与版本
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            app.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (app.version != null && app.version!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${app.version}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 平台 Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: platformColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getPlatformIcon(app.platform), size: 10, color: platformColor),
                          const SizedBox(width: 4),
                          Text(
                            app.platform,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: platformColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 描述内容
          if (app.description != null && app.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              app.description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // 底部：左侧水平滑动标签栏 + 右侧操作按钮（下载 / 打开应用）
          if (app.tags.isNotEmpty || hasFile || hasUrl) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧标签栏（过多时支持左右水平滑动）
                Expanded(
                  child: app.tags.isNotEmpty
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: app.tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(width: 8),

                // 右侧操作按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 安装包下载
                    if (hasFile) ...[
                      TextButton.icon(
                        onPressed: () => _handleOpenUrl(context, app.fileUrl!, forceExternal: true),
                        icon: const Icon(LucideIcons.download, size: 13),
                        label: Text(
                          app.fileSize != null ? '下载 (${app.fileSize})' : '下载',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // 网址直达 (文字按钮「打开应用」)
                    if (hasUrl)
                      TextButton.icon(
                        onPressed: () => _handleOpenUrl(context, app.url!),
                        icon: const Icon(LucideIcons.arrowUpRight, size: 14, color: AppColors.primary),
                        label: const Text(
                          '打开应用',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
