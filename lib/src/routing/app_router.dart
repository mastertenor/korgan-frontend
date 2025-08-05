// lib/src/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/platform_helper.dart';
import '../utils/app_logger.dart';
import '../features/home/presentation/home_mobile.dart';
import '../features/home/presentation/home_web.dart';
import '../features/mail/presentation/pages/mobile/mail_page_mobile.dart';
import '../features/mail/presentation/pages/web/mail_page_web.dart';
import '../common_widgets/shell/web_app_shell.dart'; // 🆕 WebAppShell import
import 'route_constants.dart';

/// Platform-aware router with Web Shell integration
/// 
/// Web platformunda WebAppShell kullanır, mobile'da geleneksel routing.
/// Temiz ve anlaşılır yapı.
class AppRouter {
  AppRouter._();

  /// Main GoRouter configuration with Shell Route
  static final GoRouter router = GoRouter(
    initialLocation: RouteConstants.home,
    debugLogDiagnostics: true,
    
    routes: [
      // 🆕 SHELL ROUTE - Web için WebAppShell wrapper
      ShellRoute(
        builder: (context, state, child) {
          // Sadece web platformunda shell kullan
          if (PlatformHelper.shouldUseWebExperience) {
            AppLogger.info('🌐 Using WebAppShell for: ${state.uri}');
            return WebAppShell(child: child);
          } else {
            // Mobile için şimdilik shell yok, direkt sayfa döndür
            AppLogger.info('📱 Using direct routing for mobile: ${state.uri}');
            return child;
          }
        },
        routes: [
          // ========== HOME ROUTE ==========
          GoRoute(
            path: RouteConstants.home,
            name: 'home',
            builder: (context, state) => _buildHomePage(context, state),
          ),

          // ========== MAIL ROUTE ==========
          GoRoute(
            path: MailRoutes.userMail,
            name: 'mail',
            builder: (context, state) => _buildMailPage(context, state),
          ),
          
          // 🆕 Future modules can be added here:
          // GoRoute(path: '/crm', name: 'crm', builder: ...),
          // GoRoute(path: '/tasks', name: 'tasks', builder: ...),
        ],
      ),
    ],

    // ========== ERROR HANDLING ==========
    errorBuilder: (context, state) => _buildErrorPage(
      error: state.error.toString(),
      location: state.uri.toString(),
    ),
  );

  // ========== PAGE BUILDERS ==========

  /// Build platform-aware home page
  static Widget _buildHomePage(BuildContext context, GoRouterState state) {
    AppLogger.info('🏠 Building home page');
    
    if (PlatformHelper.shouldUseMobileExperience) {
      return const HomeMobile();
    } else {
      // 🆕 Web home artık WebAppShell içinde çalışır
      return const HomeWeb();
    }
  }

  /// Build platform-aware mail page
  static Widget _buildMailPage(BuildContext context, GoRouterState state) {
    final email = state.pathParameters[RouteParams.email];
    
    // Email validation
    if (email == null || !RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email parameter: $email');
      return _buildErrorPage(
        error: 'Invalid email address',
        location: state.uri.toString(),
      );
    }

    AppLogger.info('📬 Building mail page for: $email');

    if (PlatformHelper.shouldUseMobileExperience) {
      // Mobile: Geleneksel AppBar'lı version (değişiklik yok)
      return MailPageMobile(userEmail: email);
    } else {
      // 🆕 Web: WebAppShell header sağladığı için kendi header'ını kapatmalı
      return MailPageWeb(
        userEmail: email,
        // showHeader: false, // TODO: MailPageWeb'e bu parameter eklenecek
      );
    }
  }

  /// Build error page
  static Widget _buildErrorPage({
    required String error,
    required String location,
  }) {
    // 🆕 Error page'de de platform detection yapabiliriz
    final isWeb = PlatformHelper.shouldUseWebExperience;
    
    return Scaffold(
      // Web'de WebAppShell header sağlar, mobile'da kendi AppBar'ı
      appBar: isWeb ? null : AppBar(
        title: const Text('Sayfa Bulunamadı'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sayfa Bulunamadı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aradığınız sayfa mevcut değil.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: $location',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => goToHome(),
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
    );
  }

  // ========== NAVIGATION HELPERS ==========

  /// Navigate to home
  static void goToHome() {
    router.go(RouteConstants.home);
    AppLogger.info('🏠 Navigating to home');
  }

  /// Navigate to mail for specific user
  static void goToMail(String email) {
    if (!RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for navigation: $email');
      return;
    }
    
    final path = MailRoutes.userMailPath(email);
    router.go(path);
    AppLogger.info('📬 Navigating to mail: $email');
  }

  // 🆕 Additional navigation helpers for future modules
  
  /// Navigate to CRM module (future)
  static void goToCRM() {
    router.go('/crm');
    AppLogger.info('👥 Navigating to CRM');
  }

  /// Navigate to Tasks module (future)
  static void goToTasks() {
    router.go('/tasks');
    AppLogger.info('✓ Navigating to Tasks');
  }

  // ========== UTILITY METHODS ==========

  /// Get current route location
  static String get currentLocation => 
      router.routerDelegate.currentConfiguration.uri.toString();

  /// Check if currently on home page
  static bool get isOnHomePage => currentLocation == RouteConstants.home;

  /// Check if currently on mail page
  static bool get isOnMailPage {
    final segments = currentLocation.split('/');
    return segments.length > 1 && '/${segments[1]}' == RouteConstants.mailPrefix;
  }

  /// 🆕 Get current module from route
  static String get currentModule {
    final segments = currentLocation.split('/');
    if (segments.length > 1 && segments[1].isNotEmpty) {
      return segments[1];
    }
    return '';
  }

  /// 🆕 Check if we're using web shell
  static bool get isUsingWebShell => PlatformHelper.shouldUseWebExperience;
}