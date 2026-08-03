import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nltime/router.dart';

import 'common/app_service.dart';
import 'common/theme_manager.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppService.themeIndexNotifier,
      builder: (context, themeIndex, _) {
        final activeTheme = ThemeManager.getTheme(themeIndex);

        return MaterialApp.router(
          title: '极速对时',
          debugShowCheckedModeBanner: false,
          themeMode: activeTheme.brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: activeTheme.bgColor,
            colorSchemeSeed: activeTheme.primaryColor,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: activeTheme.bgColor,
            colorSchemeSeed: activeTheme.primaryColor,
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          routerConfig: router,
        );
      },
    );
  }
}