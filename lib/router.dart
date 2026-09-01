import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'features/clock/pages/clock_page.dart';
import 'features/coupon/pages/coupon_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/shell/pages/app_shell.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const AppPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/clock',
      builder: (BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: const Text('极速对时')),
        body: const HomePage(),
      ),
    ),
    GoRoute(
      path: '/coupon',
      builder: (BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: const Text('美团领券助手')),
        body: const CouponPage(),
      ),
    ),
  ],
);
