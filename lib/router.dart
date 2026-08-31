import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'coupon/coupon_page.dart';
import 'pages/app.dart';
import 'pages/home.dart';
import 'pages/settings.dart';

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
