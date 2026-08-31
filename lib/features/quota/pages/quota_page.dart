import 'package:flutter/material.dart';
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
  String _searchQuery = '';
  String _filterProvider = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _providerFilters = const [
    {'label': '全部', 'value': 'all'},
    {'label': 'Antigravity', 'value': 'google-antigravity'},
    {'label': 'Codex', 'value': 'openai-codex'},
    {'label': 'OpenAI', 'value': 'openai-compatible'},
    {'label': 'AI Studio', 'value': 'google-aistudio'},
    {'label': 'Generic', 'value': 'generic'},
  ];

  @override
  void initState() {
    super.initState();
    QuotaService.init();
    _refreshData(background: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final filtered = keys.where((item) {
          if (_filterProvider != 'all' && item.provider != _filterProvider) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final nameMatch = item.name.toLowerCase().contains(q);
            final providerMatch = item.provider.toLowerCase().contains(q);
            final emailMatch = (item.email ?? '').toLowerCase().contains(q);
            return nameMatch || providerMatch || emailMatch;
          }
          return true;
        }).toList();

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

                // 2. 搜索与筛选工具栏
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 搜索框
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '搜索资产名称、Provider 或 邮箱...',
                            prefixIcon: const Icon(LucideIcons.search, size: 16),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                        const SizedBox(height: 10),

                        // Provider 标签栏
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _providerFilters.map((filter) {
                              final isSelected = _filterProvider == filter['value'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(filter['label']!),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _filterProvider = filter['value']!);
                                  },
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. 配额资产列表
                if (filtered.isEmpty)
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
                              keys.isEmpty ? '暂无算力配置，请先连接服务端' : '没有符合筛选条件的配置',
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
                        final item = filtered[index];
                        return QuotaCard(
                          item: item,
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}
