import 'package:flutter/material.dart';

import '../common/app_service.dart';
import '../common/floating_clock_service.dart';
import '../common/theme_manager.dart';
import 'floating_page.dart';
import 'home.dart';
import 'settings.dart';
import 'stopwatch_page.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    FloatingPage(),
    StopwatchPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppService.themeIndexNotifier,
      builder: (context, themeIdx, _) {
        final theme = ThemeManager.getTheme(themeIdx);

        return Scaffold(
          backgroundColor: theme.bgColor,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: theme.cardColor,
              selectedItemColor: theme.primaryColor,
              unselectedItemColor: theme.subTextColor,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 0,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time_rounded),
                  activeIcon: Icon(Icons.access_time_filled_rounded),
                  label: '极准时钟',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.layers_outlined),
                  activeIcon: Icon(Icons.layers_rounded),
                  label: '悬浮窗',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  activeIcon: Icon(Icons.timer_rounded),
                  label: '毫秒秒表',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: '设置',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}