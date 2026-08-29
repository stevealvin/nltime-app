import 'package:flutter/material.dart';

import '../common/app_service.dart';
import '../views/app_dialog.dart';
import '../views/time_service_form_dialog.dart';

/// Settings page — pure content widget, no inner Scaffold.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final packageInfo = AppService.packageInfo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildTimeSourcesCard(context),
        const SizedBox(height: 16),
        _buildAboutCard(context),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Theme selector ─────────────────────────────────────────────────────────

  // ── Time sources manager ───────────────────────────────────────────────────

  Widget _buildTimeSourcesCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final services = AppService.timeServices;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.language_rounded, size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '授时服务器列表',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_rounded, color: cs.primary),
                  tooltip: '添加自定义接口',
                  onPressed: () async {
                    final data = await TimeServiceFormDialog.show(context);
                    if (data == null) return;
                    final newSvc = await AppService.addCustomTimeService(
                      name: data.name,
                      url: data.url,
                      parseType: data.parseType,
                      customKey: data.customKey,
                    );
                    await AppService.setCurrentTimeService(newSvc.id);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: AppService.activeServiceIdNotifier,
              builder: (context, activeId, _) {
                return RadioGroup<String>(
                  groupValue: activeId,
                  onChanged: (val) {
                    if (val != null) AppService.setCurrentTimeService(val);
                  },
                  child: Column(
                    children: [
                      for (int i = 0; i < services.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ServiceTile(
                          item: services[i],
                          isSelected: services[i].id == activeId,
                          onEdit: () async {
                            final data = await TimeServiceFormDialog.show(
                              context,
                              service: services[i],
                            );
                            if (data == null) return;
                            await AppService.updateCustomTimeService(
                              id: services[i].id,
                              name: data.name,
                              url: data.url,
                              parseType: data.parseType,
                              customKey: data.customKey,
                            );
                            setState(() {});
                          },
                          onDelete: () async {
                            final item = services[i];
                            final confirmed = await AppDialog.confirm(
                              context: context,
                              title: '删除授时接口',
                              message: '确定要删除自定义接口 [${item.name}] 吗？',
                              confirmText: '删除',
                              confirmColor: Colors.redAccent,
                              icon: Icons.delete_forever_rounded,
                            );
                            if (confirmed == true) {
                              await AppService.deleteCustomTimeService(item.id);
                              if (context.mounted) {
                                AppDialog.showToast(
                                  context: context,
                                  message: '已成功删除接口 ${item.name}',
                                );
                              }
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── About card ─────────────────────────────────────────────────────────────

  Widget _buildAboutCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 54,
                height: 54,
                errorBuilder: (_, _, _) => Container(
                  width: 54,
                  height: 54,
                  color: cs.primary,
                  child: Icon(Icons.access_time_filled_rounded,
                      color: cs.onPrimary, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '极速对时',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '版本 v${packageInfo.version} (${packageInfo.buildNumber})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  Text(
                    '网络 RTT 时延补偿算法与毫秒悬浮',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service list tile ─────────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final dynamic item; // TimeService
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceTile({
    required this.item,
    required this.isSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      value: item.id as String,
      title: Row(
        children: [
          Text(
            item.name as String,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          if (item.isBuiltin as bool) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '内置',
                style: TextStyle(color: cs.primary, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        item.url as String,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
      secondary: (item.isBuiltin as bool)
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              ],
            ),
    );
  }
}
