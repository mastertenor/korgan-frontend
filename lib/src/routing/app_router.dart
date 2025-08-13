// lib/src/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/platform_helper.dart';
import '../utils/app_logger.dart';
import '../features/home/presentation/home_mobile.dart';
import '../features/home/presentation/home_web.dart';
import '../features/mail/presentation/pages/mobile/mail_page_mobile.dart';
import '../features/mail/presentation/pages/web/mail_page_web.dart';
import '../features/mail/presentation/pages/web/mail_page_detail_web.dart'; // 🆕 YENİ IMPORT
import '../common_widgets/shell/app_shell.dart';
import 'route_constants.dart';

/// Platform-aware router with Web Shell integration
/// 
/// ✅ UPDATED: Folder-based routing support added
/// - /mail/email → inbox redirect
/// - /mail/email/folder → folder page  
/// - /mail/email/folder/mailId → mail detail page
class AppRouter {
  AppRouter._();

  /// Main GoRouter configuration with Shell Route
  static final GoRouter router = GoRouter(
    initialLocation: RouteConstants.home,
    debugLogDiagnostics: true,
    
    routes: [
      // SHELL ROUTE - Web için WebAppShell wrapper
      ShellRoute(
        builder: (context, state, child) {
          if (PlatformHelper.shouldUseWebExperience) {
            AppLogger.info('🌐 Using WebAppShell for: ${state.uri}');
            return AppShell(child: child);
          } else {
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

          // ========== MAIL ROUTES (UPDATED) ==========
          
          // 🆕 MAIL USER ROUTE - Inbox'a redirect
          GoRoute(
            path: MailRoutes.userMail,
            name: 'mail_user',
            redirect: (context, state) {
              final email = state.pathParameters[RouteParams.email];
              if (email == null || !RouteConstants.isValidEmail(email)) {
                AppLogger.warning('❌ Invalid email for redirect: $email');
                return null; // Let builder handle error
              }
              
              final redirectPath = MailRoutes.folderPath(email, MailFolderNames.inbox);
              AppLogger.info('🔀 Redirecting /mail/$email → $redirectPath');
              return redirectPath;
            },
            builder: (context, state) {
              // This shouldn't be reached due to redirect, but handle error case
              return _buildErrorPage(
                error: 'Mail route requires folder specification',
                location: state.uri.toString(),
              );
            },
          ),

          // 🆕 MAIL FOLDER ROUTE - Main folder view
          GoRoute(
            path: MailRoutes.userMailFolder,
            name: 'mail_folder',
            builder: (context, state) => _buildMailFolderPage(context, state),
          ),

          // 🆕 MAIL DETAIL ROUTE - Individual mail view
          GoRoute(
            path: MailRoutes.userMailDetail,
            name: 'mail_detail',
            builder: (context, state) => _buildMailDetailPage(context, state),
          ),
          
          // Future modules can be added here:
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
      return const HomeWeb();
    }
  }

  /// 🆕 Build mail folder page
  static Widget _buildMailFolderPage(BuildContext context, GoRouterState state) {
    final email = state.pathParameters[RouteParams.email];
    final folder = state.pathParameters[RouteParams.folder];
    
    // Email validation
    if (email == null || !RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email parameter: $email');
      return _buildErrorPage(
        error: 'Invalid email address',
        location: state.uri.toString(),
      );
    }

    // Folder validation
    if (folder == null || !MailFolderNames.isValid(folder)) {
      AppLogger.warning('❌ Invalid folder parameter: $folder');
      return _buildErrorPage(
        error: 'Folder "$folder" not found',
        location: state.uri.toString(),
      );
    }

    AppLogger.info('📁 Building mail folder page: $email/$folder');

    if (PlatformHelper.shouldUseMobileExperience) {
      // Mobile: Use existing MailPageMobile (no folder param needed for now)
      return MailPageMobile(userEmail: email);
    } else {
      // Web: Use MailPageWeb with folder context
      return MailPageWeb(
        userEmail: email,
        initialFolder: folder, // 🆕 Folder parameter will be added
      );
    }
  }

  /// 🆕 Build mail detail page
  static Widget _buildMailDetailPage(BuildContext context, GoRouterState state) {
    final email = state.pathParameters[RouteParams.email];
    final folder = state.pathParameters[RouteParams.folder];
    final mailId = state.pathParameters[RouteParams.mailId];
    
    // Email validation
    if (email == null || !RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email parameter: $email');
      return _buildErrorPage(
        error: 'Invalid email address',
        location: state.uri.toString(),
      );
    }

    // Folder validation
    if (folder == null || !MailFolderNames.isValid(folder)) {
      AppLogger.warning('❌ Invalid folder parameter: $folder');
      return _buildErrorPage(
        error: 'Folder "$folder" not found',
        location: state.uri.toString(),
      );
    }

    // Mail ID validation
    if (mailId == null || mailId.isEmpty) {
      AppLogger.warning('❌ Invalid mail ID parameter: $mailId');
      return _buildErrorPage(
        error: 'Mail not found',
        location: state.uri.toString(),
      );
    }

    AppLogger.info('📧 Building mail detail page: $email/$folder/$mailId');

    if (PlatformHelper.shouldUseMobileExperience) {
      // Mobile: Navigate to existing detail page (if available)
      // For now, fallback to folder view
      return MailPageMobile(userEmail: email);
    } else {
      // Web: Use new MailPageDetailWeb
      return MailPageDetailWeb(
        userEmail: email,
        folder: folder,
        mailId: mailId,
      );
    }
  }

  /// Build error page
  static Widget _buildErrorPage({
    required String error,
    required String location,
  }) {
    final isWeb = PlatformHelper.shouldUseWebExperience;
    
    return Scaffold(
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
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
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

  // ========== NAVIGATION HELPERS (UPDATED) ==========

  /// Navigate to home
  static void goToHome() {
    router.go(RouteConstants.home);
    AppLogger.info('🏠 Navigating to home');
  }

  /// Navigate to mail for specific user (redirects to inbox)
  static void goToMail(String email) {
    if (!RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for navigation: $email');
      return;
    }
    
    final path = MailRoutes.userMailPath(email);
    router.go(path); // Will redirect to inbox
    AppLogger.info('📬 Navigating to mail: $email (will redirect to inbox)');
  }

  /// 🆕 Navigate to specific folder
  static void goToFolder(String email, String folder) {
    if (!RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for folder navigation: $email');
      return;
    }
    
    if (!MailFolderNames.isValid(folder)) {
      AppLogger.warning('❌ Invalid folder for navigation: $folder');
      return;
    }
    
    final path = MailRoutes.folderPath(email, folder);
    router.go(path);
    AppLogger.info('📁 Navigating to folder: $email/$folder');
  }

  /// 🆕 Navigate to mail detail
  static void goToMailDetail(String email, String folder, String mailId) {
    if (!RouteConstants.isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for mail detail navigation: $email');
      return;
    }
    
    if (!MailFolderNames.isValid(folder)) {
      AppLogger.warning('❌ Invalid folder for mail detail navigation: $folder');
      return;
    }
    
    if (mailId.isEmpty) {
      AppLogger.warning('❌ Invalid mail ID for navigation: $mailId');
      return;
    }
    
    final path = MailRoutes.mailDetailPath(email, folder, mailId);
    router.go(path);
    AppLogger.info('📧 Navigating to mail detail: $email/$folder/$mailId');
  }

  // Additional navigation helpers for future modules
  
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

  // ========== UTILITY METHODS (UPDATED) ==========

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

  /// 🆕 Get current email from route
  static String? get currentEmail {
    final uri = router.routerDelegate.currentConfiguration.uri;
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'mail') {
      final email = segments[1];
      return RouteConstants.isValidEmail(email) ? email : null;
    }
    return null;
  }

  /// 🆕 Get current folder from route
  static String? get currentFolder {
    final uri = router.routerDelegate.currentConfiguration.uri;
    final segments = uri.pathSegments;
    if (segments.length >= 3 && segments[0] == 'mail') {
      final folder = segments[2];
      return MailFolderNames.isValid(folder) ? folder : null;
    }
    return null;
  }

  /// 🆕 Get current mail ID from route
  static String? get currentMailId {
    final uri = router.routerDelegate.currentConfiguration.uri;
    final segments = uri.pathSegments;
    if (segments.length >= 4 && segments[0] == 'mail') {
      return segments[3].isNotEmpty ? segments[3] : null;
    }
    return null;
  }

  /// Get current module from route
  static String get currentModule {
    final segments = currentLocation.split('/');
    if (segments.length > 1 && segments[1].isNotEmpty) {
      return segments[1];
    }
    return '';
  }

  /// Check if we're using web shell
  static bool get isUsingWebShell => PlatformHelper.shouldUseWebExperience;
}