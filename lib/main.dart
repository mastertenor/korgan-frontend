// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:korgan/src/utils/app_logger.dart';
import 'src/features/user/presentation/providers/auth_providers.dart';
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
/// 2. Interceptor'ın kurulmasını garanti eder
/// 3. Tüm hazırlıklar bitene kadar splash gösterir
/// 4. Soğuk başlangıç yarışını (cold-start race) önler
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

    // 3) Splash bekçisi: Hazırlıklar bitene kadar router'ı gösterme
    if (authInit.isLoading) {
      AppLogger.debug('🚀 Bootstrap: Auth loading, showing splash...');
      return MaterialApp(
        title: 'Flash Test App',
        debugShowCheckedModeBanner: false,
        home: _SplashScreen(),
      );
    }

    // 4) Hata olsa bile (örn: offline), app açılmalı
    // authInit.hasError olabilir ama app çalışmaya devam etmeli
    AppLogger.info(
      '🚀 Bootstrap complete - Auth ready, Interceptor: $interceptorReady',
    );

    // 5) Ana uygulamayı başlat
    return MinimalApp();
  }
}

/// Ana uygulama widget'ı - Artık bootstrap sonrası çalışıyor
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

/// Splash ekranı - Auth kontrolü sırasında gösterilir
/// Yaklaşık 300-600ms görünür
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo veya app icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.flash_on, // Flash icon for "Flash Test App"
                  size: 60,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // App title
              Text(
                'Flash Test App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),

              // Loading text
              Text(
                'Başlatılıyor...',
                style: TextStyle(fontSize: 16, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 24),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Debug info (sadece development'ta göster)
              if (const bool.fromEnvironment('dart.vm.product') == false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auth durumu kontrol ediliyor...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
