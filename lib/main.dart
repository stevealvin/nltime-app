import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nltime/router.dart';

import 'common/app_service.dart';
import 'common/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Custom ErrorWidget builder so release mode doesn't swallow errors as blank screens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              'UI 渲染异常:\n${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  };

  try {
    await initializeDateFormatting('zh_CN', null);
  } catch (_) {}

  await AppService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '极速对时',
      debugShowCheckedModeBanner: false,
      theme: ThemeManager.lightTheme.themeData,
      themeMode: ThemeMode.light,
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
  }
}