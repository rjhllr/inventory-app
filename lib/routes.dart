import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/product_db_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/scan_results_screen.dart';
import 'screens/scanning_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/upgrades_screen.dart';
import 'screens/reset_stocks_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'scan',
          name: 'scan',
          builder: (context, state) => const ScanningScreen(),
        ),
        GoRoute(
          path: 'reset-stocks',
          name: 'reset-stocks',
          builder: (context, state) => const ResetStocksScreen(),
        ),
        GoRoute(
          path: 'settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'products',
          name: 'products',
          builder: (context, state) => const ProductDbScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'productDetail',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ProductDetailScreen(productId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'results',
          name: 'results',
          builder: (context, state) => const ScanResultsScreen(),
        ),
        GoRoute(
          path: 'upgrades',
          name: 'upgrades',
          builder: (context, state) => const UpgradesScreen(),
        ),
      ],
    ),
  ],
); 