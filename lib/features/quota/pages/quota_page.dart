import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/quota_model.dart';
import '../services/quota_service.dart';
import '../widgets/quota_card.dart';
import '../widgets/quota_stats_banner.dart';

/// 算力配额中枢主页面 (Quota Hub Page - 纯净巡检与展示)
class QuotaPage extends StatefulWidget {
  const QuotaPage({super.key});

  @override
  State<QuotaPage> createState() => _QuotaPageState();
}

class _QuotaPageState extends State<QuotaPage> {
  @override
  void initState() {
    super.initState();
    QuotaService.init();
    _refreshData(background: true);
  }

  Future<void> _refreshData({bool background = false}) async {
    try {
      await QuotaService.fetchQuotas(background: background);
    } catch (_) {}
  }

  Future<void> _handleProbeAll() async {
    HapticFeedback.mediumImpact();
    try {
      await QuotaService.probeAllQuotas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已完成全部算力资产探针巡检')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量巡检失败: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<List<ApiKeyConfig>>(
      valueListenable: QuotaService.keysNotifier,
      builder: (context, keys, _) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _refreshData(background: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // 1. 顶部统计大盘与一键探针 Banner
                SliverToBoxAdapter(
                  child: QuotaStatsBanner(
                    keys: keys,
                    onProbeAll: _handleProbeAll,
                  ),
                ),

                // 2. 列表间距
                const SliverToBoxAdapter(
                  child: SizedBox(height: 6),
                ),

                // 3. 配额资产列表
                if (keys.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
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
                                LucideIcons.inbox,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无算力配置，请先连接服务端',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _refreshData(background: false),
                              icon: const Icon(LucideIcons.refreshCw, size: 14),
                              label: const Text('从服务端重新拉取'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = keys[index];
                        return QuotaCard(
                          item: item,
                        );
                      },
                      childCount: keys.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 84)),
              ],
            ),
          ),
        );
      },
    );
  }
}
