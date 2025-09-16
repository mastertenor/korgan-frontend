// lib/main.dart - Updated Bootstrap with Organization Integration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:korgan/src/utils/app_logger.dart';
import 'src/features/user/presentation/providers/auth_providers.dart';
import 'src/features/organization/presentation/providers/organization_providers.dart';
import 'src/routing/app_router.dart';

void main() {
  AppLogger.init();
  // Use path-based URLs instead of hash URLs
  // /#/dashboard -> /dashboard
  usePathUrlStrategy();

  runApp(const ProviderScope(child: AppBootstrap()));
}

/// Bootstrap Gate - Uygulama başlamadan önce kritik sistemleri hazırlar
///
/// Bu widget:
/// 1. Auth durumunu kontrol eder (token var mı?)
/// 2. Organization'ları yükler (authenticated user için)
/// 3. Interceptor'ın kurulmasını garanti eder
/// 4. Tüm hazırlıklar bitene kadar splash gösterir
/// 5. Soğuk başlangıç yarışını (cold-start race) önler
class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug('🚀 Bootstrap: Starting initialization...');

    // 1) Auth durumunu başlat ve bekle
    final authInit = ref.watch(authInitProvider);

    // 2) Interceptor'ı garanti et
    // watch ederek provider'ın çalışmasını tetikliyoruz
    final interceptorReady = ref.watch(authInterceptorManagerProvider);

    // 3) Auth tamamlanmışsa Organization init'i başlat
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (authInit.hasValue && isAuthenticated) {
      // User authenticated - trigger organization initialization
      // Using microtask to avoid provider modification during build
      Future.microtask(() async {
        try {
          final organizationNotifier = ref.read(
            organizationNotifierProvider.notifier,
          );
          final currentState = ref.read(organizationNotifierProvider);

          // Only initialize if not already initialized
          if (!currentState.isInitialized) {
            AppLogger.debug(
              '🏢 Bootstrap: Triggering organization initialization...',
            );
            await organizationNotifier.initialize();
          }
        } catch (e) {
          AppLogger.warning('⚠️ Bootstrap: Organization init failed - $e');
          // Continue anyway - app should work without organizations
        }
      });
    }

    // 4) Splash bekçisi: Sadece auth loading sırasında göster
    if (authInit.isLoading) {
      AppLogger.debug('🚀 Bootstrap: Auth loading, showing splash...');
      return MaterialApp(
        title: 'Korgan Platform',
        debugShowCheckedModeBanner: false,
        home: _SplashScreen(message: 'Authenticating...'),
      );
    }

    // 5) Hata olsa bile (örn: offline), app açılmalı
    AppLogger.info(
      '🚀 Bootstrap complete - Auth ready, Interceptor: $interceptorReady',
    );

    // 6) Ana uygulamayı başlat
    return MinimalApp();
  }
}

/// Ana uygulama widget'ı - Artık bootstrap sonrası çalışıyor
class MinimalApp extends ConsumerWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Korgan Platform',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.getRouter(ref),
    );
  }
}

/// Splash ekranı - Auth/Organization kontrolü sırasında gösterilir
/// Yaklaşık 300-1000ms görünür
class _SplashScreen extends StatelessWidget {
  final String message;

  const _SplashScreen({this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'Korgan Platform',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(height: 16),

            // Loading message
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.blue[600]),
            ),
          ],
        ),
      ),
    );
  }
}
