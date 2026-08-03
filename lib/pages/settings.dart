import 'package:flutter/material.dart';

import '../common/app_service.dart';
import '../common/theme_manager.dart';
import '../models/time_service_model.dart';
import '../views/app_dialog.dart';
import '../views/time_service_form_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final packageInfo = AppService.packageInfo;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppService.themeIndexNotifier,
      builder: (context, themeIndex, _) {
        final theme = ThemeManager.getTheme(themeIndex);

        return Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            backgroundColor: theme.bgColor,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.settings_rounded, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '设置中心',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildThemeSelectorCard(theme),
              const SizedBox(height: 16),
              _buildTimeSourcesManagerCard(theme),
              const SizedBox(height: 16),
              _buildAboutCard(theme),
            ],
          ),
        );
      },
    );
  }

  /// Theme Palette Picker
  Widget _buildThemeSelectorCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '炫彩主题风格',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ThemeManager.themes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final t = ThemeManager.themes[index];
              final isSelected = index == AppService.themeIndexNotifier.value;

              return GestureDetector(
                onTap: () => AppService.setThemeIndex(index),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? t.primaryColor : t.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: t.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.name,
                          style: TextStyle(
                            color: t.textColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Time Sources Manager
  Widget _buildTimeSourcesManagerCard(AppThemeData theme) {
    final services = AppService.timeServices;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.language_rounded, size: 18, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    '授时服务器列表 (手动选择)',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.add_rounded, size: 18, color: theme.primaryColor),
                onPressed: () async {
                  final data = await TimeServiceFormDialog.show(
                    context,
                    theme: theme,
                  );
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
          const SizedBox(height: 10),
          ValueListenableBuilder<String>(
            valueListenable: AppService.activeServiceIdNotifier,
            builder: (context, activeId, _) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (context, index) => Divider(color: theme.dividerColor, height: 1),
                itemBuilder: (context, index) {
                  final item = services[index];
                  final isSelected = item.id == activeId;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: item.id,
                      groupValue: activeId,
                      activeColor: theme.primaryColor,
                      onChanged: (val) {
                        if (val != null) {
                          AppService.setCurrentTimeService(val);
                        }
                      },
                    ),
                    title: Row(
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (item.isBuiltin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '内置',
                              style: TextStyle(color: theme.primaryColor, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      item.url,
                      style: TextStyle(color: theme.subTextColor, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item.isBuiltin
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_rounded, size: 16, color: theme.subTextColor),
                                onPressed: () async {
                                  final data = await TimeServiceFormDialog.show(
                                    context,
                                    service: item,
                                    theme: theme,
                                  );
                                  if (data == null) return;
                                  await AppService.updateCustomTimeService(
                                    id: item.id,
                                    name: data.name,
                                    url: data.url,
                                    parseType: data.parseType,
                                    customKey: data.customKey,
                                  );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirmed = await AppDialog.confirm(
                                    context: context,
                                    theme: theme,
                                    title: '删除授时接口',
                                    message: '确定要删除自定义接口 [${item.name}] 吗？删除后可随时重新添加。',
                                    confirmText: '删除',
                                    confirmColor: Colors.redAccent,
                                    icon: Icons.delete_forever_rounded,
                                  );
                                  if (confirmed == true) {
                                    await AppService.deleteCustomTimeService(item.id);
                                    if (mounted) {
                                      AppDialog.showToast(
                                        context: context,
                                        theme: theme,
                                        message: '已成功删除接口 ${item.name}',
                                      );
                                    }
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                    onTap: () {
                      AppService.setCurrentTimeService(item.id);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// About Card with App Icon
  Widget _buildAboutCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/icon/icon.png',
              width: 54,
              height: 54,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 54,
                height: 54,
                color: theme.primaryColor,
                child: Icon(Icons.access_time_filled_rounded, color: theme.bgColor, size: 30),
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
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '版本 v${packageInfo.version} (${packageInfo.buildNumber})',
                  style: TextStyle(color: theme.subTextColor, fontSize: 12),
                ),
                Text(
                  '网络 RTT 时延补偿算法与毫秒悬浮',
                  style: TextStyle(color: theme.subTextColor.withValues(alpha: 0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
