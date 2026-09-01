import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../apps/pages/apps_page.dart';
import '../../hub/pages/hub_page.dart';
import '../../quota/pages/quota_page.dart';

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
      icon: Icon(LucideIcons.layoutDashboard),
      selectedIcon: Icon(LucideIcons.layoutDashboard),
      label: '控制台',
    ),
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
  ];

  static const _titles = ['星环控制台', 'AI 算力中枢', '应用与产品矩阵'];
  static const _icons = [
    LucideIcons.layoutDashboard,
    LucideIcons.sparkles,
    LucideIcons.layoutGrid,
  ];

  final List<Widget> _pages = const [
    HubPage(),
    QuotaPage(),
    AppsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
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
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.72),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) {
                setState(() => _currentIndex = i);
              },
              destinations: _destinations,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      ),
    );
  }
}