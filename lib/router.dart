import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/app.dart';
import 'pages/fullscreen_clock_page.dart';
import 'pages/settings.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AppPage();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsPage();
      },
    ),
    GoRoute(
      path: '/fullscreen',
      builder: (BuildContext context, GoRouterState state) {
        return const FullscreenClockPage();
      },
    ),
  ],
);
