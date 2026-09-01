import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/app_item_model.dart';
import '../services/apps_service.dart';
import '../widgets/app_card.dart';

/// 应用工坊主页面 (App Hub Page - 纯净产品矩阵浏览)
class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppsService.init();
    _refreshData(background: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData({bool background = false}) async {
    try {
      await AppsService.fetchApps(background: background);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<List<AppItemModel>>(
      valueListenable: AppsService.appsNotifier,
      builder: (context, apps, _) {
        final filtered = apps.where((app) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final nameMatch = app.name.toLowerCase().contains(q);
            final descMatch = (app.description ?? '').toLowerCase().contains(q);
            final tagsMatch = app.tags.any((t) => t.toLowerCase().contains(q));
            return nameMatch || descMatch || tagsMatch;
          }
          return true;
        }).toList();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _refreshData(background: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // 1. 顶部搜索栏
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '搜索应用名称、描述或标签...',
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
                  ),
                ),

                // 2. 应用列表
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.packageOpen,
                              size: 48,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              apps.isEmpty ? '应用工坊暂无应用数据，请先连接服务端' : '未找到符合条件的应用',
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
                        final app = filtered[index];
                        return AppCard(
                          app: app,
                        );
                      },
                      childCount: filtered.length,
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
