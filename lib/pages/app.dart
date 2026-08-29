import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/app_service.dart';
import 'floating_page.dart';
import 'home.dart';
import 'settings.dart';
import 'stopwatch_page.dart';

/// Root shell page. Contains the ONLY Scaffold in the navigation stack.
/// Child pages (HomePage, FloatingPage, etc.) are plain widgets — NO inner Scaffold.
class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  int _currentIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.access_time_outlined),
      selectedIcon: Icon(Icons.access_time_filled_rounded),
      label: '极准时钟',
    ),
    NavigationDestination(
      icon: Icon(Icons.layers_outlined),
      selectedIcon: Icon(Icons.layers_rounded),
      label: '悬浮窗',
    ),
    NavigationDestination(
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer_rounded),
      label: '毫秒秒表',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: '设置',
    ),
  ];

  static const _titles = ['极速对时', '悬浮窗时钟', '毫秒秒表', '设置中心'];
  static const _icons = [
    Icons.schedule_rounded,
    Icons.layers_rounded,
    Icons.timer_rounded,
    Icons.settings_rounded,
  ];

  // Pages are kept alive via IndexedStack — no Scaffold inside each.
  final List<Widget> _pages = const [
    HomePage(),
    FloatingPage(),
    StopwatchPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icons[_currentIndex], color: cs.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: _buildActions(context, cs),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _destinations,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, ColorScheme cs) {
    if (_currentIndex == 0) {
      // Home page actions: fullscreen + sync
      return [
        IconButton(
          tooltip: '全屏桌面时钟',
          icon: Icon(Icons.fullscreen_rounded, color: cs.onSurface),
          onPressed: () => context.push('/fullscreen'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: AppService.isSyncingNotifier,
          builder: (context, isSyncing, _) {
            return AnimatedRotation(
              turns: isSyncing ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: IconButton(
                tooltip: '即时测速与同步',
                icon: Icon(Icons.refresh_rounded, color: cs.primary),
                onPressed: isSyncing
                    ? null
                    : () {
                        // Notify HomePage to trigger sync via GlobalKey or callback
                        HomePageController.triggerSync?.call();
                      },
              ),
            );
          },
        ),
        const SizedBox(width: 6),
      ];
    }
    return [];
  }
}

/// Simple static callback so AppPage can trigger a sync action inside HomePage.
abstract class HomePageController {
  static VoidCallback? triggerSync;
}