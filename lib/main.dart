// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:korgan/src/utils/app_logger.dart';
import 'src/routing/app_router.dart';

void main() {
  AppLogger.init();
  // Use path-based URLs instead of hash URLs
  // /#/dashboard -> /dashboard
  usePathUrlStrategy();

  runApp(const ProviderScope(child: MinimalApp()));
}

class MinimalApp extends ConsumerWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Flash Test App',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.getRouter(ref),
    );
  }
}
