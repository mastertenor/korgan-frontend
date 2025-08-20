// lib/main.dart - Production Ready Platform-Aware Entry Point

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'src/routing/app_router.dart';
import 'src/utils/app_logger.dart';
import 'src/utils/platform_helper.dart';
import 'src/constants/app_constants.dart';
export 'package:flutter/material.dart' show GlobalKey, ScaffoldMessengerState;

final GlobalKey<ScaffoldMessengerState> globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Ensure Flutter binding is initialized
  AppLogger.init();
  WidgetsFlutterBinding.ensureInitialized();



  // Log app startup with platform info
  AppLogger.info('🚀 Korgan Platform Starting...');
  AppLogger.info('🌐 Platform: ${PlatformHelper.platformName}');
  AppLogger.info('📱 Experience: ${PlatformHelper.recommendedExperience}');
  AppLogger.info('🔧 Debug Mode: $kDebugMode');

  // Platform-specific initializations
  await _initializePlatformSpecific();

  // Start the app
  runApp(const ProviderScope(child: KorganApp()));
}

/// Platform-specific initialization
Future<void> _initializePlatformSpecific() async {
  if (PlatformHelper.shouldUseWebExperience) {
    AppLogger.info('🌐 Initializing web-specific features...');
    // Web-specific initializations (URL handling, etc.)
  } else if (PlatformHelper.shouldUseMobileExperience) {
    AppLogger.info('📱 Initializing mobile-specific features...');
    // Mobile-specific initializations (permissions, etc.)
  } else if (PlatformHelper.shouldUseDesktopExperience) {
    AppLogger.info('🖥️ Initializing desktop-specific features...');
    // Desktop-specific initializations (window management, etc.)
  }
}

/// Main Korgan Application Widget
///
/// This is the root widget that configures the entire application.
/// It uses platform-aware routing and theming to provide optimal
/// experience across all platforms.
class KorganApp extends StatelessWidget {
  const KorganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ========== APP METADATA ==========
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      scaffoldMessengerKey: globalMessengerKey,

      // ========== THEME CONFIGURATION ==========
     

      // ========== SIMPLIFIED ROUTING CONFIGURATION ==========
      routerConfig: AppRouter.router,
      /*
      // ========== LOCALIZATION ==========
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
*/
      // ========== PLATFORM-AWARE BUILDER ==========
      builder: (context, child) {
        return _PlatformAppWrapper(
          child: child ?? const _AppErrorWidget(),
        );
      },
    );
  }
}

/// Platform-aware app wrapper
///
/// This wrapper provides platform-specific configurations and
/// global error boundaries for the entire application.
class _PlatformAppWrapper extends StatelessWidget {
  final Widget child;

  const _PlatformAppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Log platform detection
    AppLogger.debug('🎯 Platform wrapper: ${PlatformHelper.recommendedExperience}');

    // Platform-specific wrapping
    Widget wrappedChild = child;

    if (PlatformHelper.shouldUseWebExperience) {
      // Web-specific wrapper (e.g., right-click handling, web shortcuts)
      wrappedChild = _WebAppWrapper(child: wrappedChild);
    } else if (PlatformHelper.shouldUseMobileExperience) {
      // Mobile-specific wrapper (e.g., system UI, orientation)
      wrappedChild = _MobileAppWrapper(child: wrappedChild);
    } else if (PlatformHelper.shouldUseDesktopExperience) {
      // Desktop-specific wrapper (e.g., window controls, menu bar)
      wrappedChild = _DesktopAppWrapper(child: wrappedChild);
    }

    return _GlobalErrorBoundary(child: wrappedChild);
  }
}

/// Web-specific app wrapper
class _WebAppWrapper extends StatelessWidget {
  final Widget child;

  const _WebAppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Add web-specific features like:
    // - Right-click context menu handling
    // - Keyboard shortcuts
    // - Browser-specific optimizations
    return child;
  }
}

/// Mobile-specific app wrapper
class _MobileAppWrapper extends StatelessWidget {
  final Widget child;

  const _MobileAppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Add mobile-specific features like:
    // - System UI overlay style
    // - Orientation handling
    // - Safe area management
    return child;
  }
}

/// Desktop-specific app wrapper
class _DesktopAppWrapper extends StatelessWidget {
  final Widget child;

  const _DesktopAppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Add desktop-specific features like:
    // - Window management
    // - Menu bar
    // - Native desktop integrations
    return child;
  }
}

/// Global error boundary for the entire application
class _GlobalErrorBoundary extends StatelessWidget {
  final Widget child;

  const _GlobalErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd wrap this with proper error handling
    // For now, just return the child
    return child;
  }
}

/// Error widget for catastrophic failures
class _AppErrorWidget extends StatelessWidget {
  const _AppErrorWidget();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red[600],
                ),
                const SizedBox(height: 24),
                Text(
                  'Korgan Platform',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulama başlatılamadı',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lütfen uygulamayı yeniden başlatın.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // In a real app, you might trigger app restart
                    AppLogger.error('User requested app restart from error screen');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






