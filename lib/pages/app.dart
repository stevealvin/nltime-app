import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/storage/app_storage.dart';
import '../core/theme/app_colors.dart';
import '../features/apps/pages/apps_page.dart';
import '../features/drop/pages/drop_page.dart';
import '../features/hub/pages/hub_page.dart';
import '../features/quota/pages/quota_page.dart';

/// OmniFlow 移动端伴侣应用主框架页 (AppShell)
class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  int _currentIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(LucideIcons.sparkles),
      selectedIcon: Icon(LucideIcons.sparkle),
      label: '算力配额',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.layoutGrid),
      selectedIcon: Icon(LucideIcons.grid),
      label: '应用工坊',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.radio),
      selectedIcon: Icon(LucideIcons.radioTower),
      label: '流转空间',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.box),
      selectedIcon: Icon(LucideIcons.boxes),
      label: '极客工作台',
    ),
  ];

  static const _titles = ['AI 算力中枢', '应用与产品矩阵', 'OmniDrop 流转空间', '极客工作台'];
  static const _icons = [
    LucideIcons.sparkles,
    LucideIcons.layoutGrid,
    LucideIcons.radio,
    LucideIcons.box,
  ];

  final List<Widget> _pages = const [
    QuotaPage(),
    AppsPage(),
    DropPage(),
    HubPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icons[_currentIndex], color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentIndex],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          // 主题快速切换
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppStorage.themeModeNotifier,
            builder: (context, mode, _) {
              final isCurrentDark = mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                tooltip: isCurrentDark ? '切换浅色模式' : '切换深色模式',
                icon: Icon(
                  isCurrentDark ? LucideIcons.sun : LucideIcons.moon,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  AppStorage.setThemeMode(isCurrentDark ? ThemeMode.light : ThemeMode.dark);
                },
              );
            },
          ),

          // 设置入口
          IconButton(
            tooltip: '系统与偏好设置',
            icon: Icon(
              LucideIcons.settings,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = i);
          },
          destinations: _destinations,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }
}