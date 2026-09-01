import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../../shared/views/app_webview_page.dart';

/// 极客工作台主页面 (Workbench Hub)
class HubPage extends StatelessWidget {
  const HubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 顶部欢迎与工作台 Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 22,
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.primaryDark.withValues(alpha: 0.3),
                          AppColors.accentIndigo.withValues(alpha: 0.15),
                        ]
                      : [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.accentSky.withValues(alpha: 0.06),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.sparkles, color: AppColors.primary, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OmniFlow 控制台',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '毫秒授时 · 跨端流转 · 自动化领券 · 扩展工具箱',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 核心实用工具分类标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '核心实用工具',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // 工具卡片网格 (4 卡片响应式 2 列)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildToolCard(
                  context,
                  title: '极速对时',
                  subtitle: '毫秒 NTP 授时与悬浮时钟',
                  icon: LucideIcons.clock,
                  iconColor: AppColors.primary,
                  onTap: () => context.push('/clock'),
                ),
                _buildToolCard(
                  context,
                  title: '流转空间 OmniDrop',
                  subtitle: '跨设备点对点极速流转',
                  icon: LucideIcons.radio,
                  iconColor: AppColors.accentSky,
                  onTap: () => AppWebViewPage.open(
                    context,
                    url: '${AppStorage.baseUrl}/drop',
                    title: '流转空间 OmniDrop',
                  ),
                ),
                _buildToolCard(
                  context,
                  title: '美团领券助手',
                  subtitle: '神券秒杀与自动化任务',
                  icon: LucideIcons.ticket,
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () => context.push('/coupon'),
                ),
                _buildToolCard(
                  context,
                  title: '系统与服务端配置',
                  subtitle: 'API 设置与深浅主题',
                  icon: LucideIcons.settings,
                  iconColor: AppColors.accentPurple,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 84)),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
