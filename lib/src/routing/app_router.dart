// lib/src/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/simple_token_storage.dart';
import '../features/auth/presentation/pages/platform/web/login_page_web.dart';
import '../features/home/presentation/home_web.dart';
import '../features/home/presentation/home_mobile.dart';
import '../features/mail/presentation/pages/mobile/mail_page_mobile.dart';
import '../features/mail/presentation/pages/web/mail_page_web.dart';
import '../features/mail/presentation/pages/web/mail_page_detail_web.dart';
import '../utils/app_logger.dart';
import '../utils/platform_helper.dart';

/// Router with auth check, home page integration and email routing
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isLoginPage = state.uri.path == '/login';

      // Check if user has valid tokens
      final hasValidTokens = await SimpleTokenStorage.hasValidTokens();

      if (!hasValidTokens && !isLoginPage) {
        // No valid tokens -> redirect to login
        return '/login';
      }

      if (hasValidTokens && isLoginPage) {
        // Has valid tokens but on login page -> redirect to home
        return '/home';
      }

      return null; // Stay on current page
    },

    // Error handling
    errorBuilder: (context, state) => _buildErrorPage(
      error: state.error.toString(),
      location: state.uri.toString(),
    ),

    routes: [
      // Root redirect to home
      GoRoute(path: '/', redirect: (context, state) => '/home'),

      // Login page
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPageWeb(),
      ),

      // Home page - platform aware
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => _buildHomePage(context, state),
      ),

      // ========== MAIL ROUTES ==========

      // MAIL USER ROUTE - Inbox'a redirect
      GoRoute(
        path: '/mail/:email',
        name: 'mail_user',
        redirect: (context, state) {
          final email = state.pathParameters['email'];
          if (email == null || !_isValidEmail(email)) {
            AppLogger.warning('❌ Invalid email for redirect: $email');
            return null; // Let builder handle error
          }

          final redirectPath = '/mail/$email/inbox';
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

      // MAIL FOLDER ROUTE - Main folder view
      GoRoute(
        path: '/mail/:email/:folder',
        name: 'mail_folder',
        builder: (context, state) => _buildMailFolderPage(context, state),
      ),

      // MAIL DETAIL ROUTE - Individual mail view
      GoRoute(
        path: '/mail/:email/:folder/:mailId',
        name: 'mail_detail',
        builder: (context, state) => _buildMailDetailPage(context, state),
      ),
    ],
  );
});

/// Build platform-aware home page
Widget _buildHomePage(BuildContext context, GoRouterState state) {
  AppLogger.info('🏠 Building home page');

  if (PlatformHelper.shouldUseMobileExperience) {
    return const HomeMobile();
  } else {
    return const HomeWeb();
  }
}

/// Build mail folder page
Widget _buildMailFolderPage(BuildContext context, GoRouterState state) {
  final email = state.pathParameters['email'];
  final folder = state.pathParameters['folder'];

  // Email validation
  if (email == null || !_isValidEmail(email)) {
    AppLogger.warning('❌ Invalid email parameter: $email');
    return _buildErrorPage(
      error: 'Invalid email address',
      location: state.uri.toString(),
    );
  }

  // Folder validation
  if (folder == null || !_isValidFolder(folder)) {
    AppLogger.warning('❌ Invalid folder parameter: $folder');
    return _buildErrorPage(
      error: 'Folder "$folder" not found',
      location: state.uri.toString(),
    );
  }

  AppLogger.info('📁 Building mail folder page: $email/$folder');

  if (PlatformHelper.shouldUseMobileExperience) {
    // Mobile: Use existing MailPageMobile
    return MailPageMobile(userEmail: email);
  } else {
    // Web: Use MailPageWeb with folder context
    return MailPageWeb(userEmail: email, initialFolder: folder);
  }
}

/// Build mail detail page
Widget _buildMailDetailPage(BuildContext context, GoRouterState state) {
  final email = state.pathParameters['email'];
  final folder = state.pathParameters['folder'];
  final mailId = state.pathParameters['mailId'];

  // Email validation
  if (email == null || !_isValidEmail(email)) {
    AppLogger.warning('❌ Invalid email parameter: $email');
    return _buildErrorPage(
      error: 'Invalid email address',
      location: state.uri.toString(),
    );
  }

  // Folder validation
  if (folder == null || !_isValidFolder(folder)) {
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
    // Web: Use MailPageDetailWeb
    return MailPageDetailWeb(userEmail: email, folder: folder, mailId: mailId);
  }
}

/// Build error page
Widget _buildErrorPage({required String error, required String location}) {
  final isWeb = PlatformHelper.shouldUseWebExperience;

  return Scaffold(
    appBar: isWeb
        ? null
        : AppBar(
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
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Sayfa Bulunamadı',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              onPressed: () => AppRouter.goToHome(),
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

// ========== VALIDATION HELPERS ==========

/// Email validation helper
bool _isValidEmail(String email) {
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

/// Valid folder names
final _validFolders = {'inbox', 'sent', 'drafts', 'trash', 'spam'};

/// Folder validation helper
bool _isValidFolder(String folder) {
  return _validFolders.contains(folder.toLowerCase());
}

class AppRouter {
  static GoRouter getRouter(WidgetRef ref) {
    return ref.watch(routerProvider);
  }

  // ========== NAVIGATION HELPERS ==========

  /// Navigate to home
  static void goToHome() {
    final router = _getCurrentRouter();
    router?.go('/home');
    AppLogger.info('🏠 Navigating to home');
  }

  /// Navigate to mail for specific user (redirects to inbox)
  static void goToMail(String email) {
    if (!_isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for navigation: $email');
      return;
    }

    final router = _getCurrentRouter();
    final path = '/mail/$email'; // Will redirect to inbox
    router?.go(path);
    AppLogger.info('📬 Navigating to mail: $email (will redirect to inbox)');
  }

  /// Navigate to specific folder
  static void goToFolder(String email, String folder) {
    if (!_isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for folder navigation: $email');
      return;
    }

    if (!_isValidFolder(folder)) {
      AppLogger.warning('❌ Invalid folder for navigation: $folder');
      return;
    }

    final router = _getCurrentRouter();
    final path = '/mail/$email/$folder';
    router?.go(path);
    AppLogger.info('📁 Navigating to folder: $email/$folder');
  }

  /// Navigate to mail detail
  static void goToMailDetail(String email, String folder, String mailId) {
    if (!_isValidEmail(email)) {
      AppLogger.warning('❌ Invalid email for mail detail navigation: $email');
      return;
    }

    if (!_isValidFolder(folder)) {
      AppLogger.warning('❌ Invalid folder for mail detail navigation: $folder');
      return;
    }

    if (mailId.isEmpty) {
      AppLogger.warning('❌ Invalid mail ID for navigation: $mailId');
      return;
    }

    final router = _getCurrentRouter();
    final path = '/mail/$email/$folder/$mailId';
    router?.go(path);
    AppLogger.info('📧 Navigating to mail detail: $email/$folder/$mailId');
  }

  /// Navigate to login page
  static void goToLogin() {
    final router = _getCurrentRouter();
    router?.go('/login');
    AppLogger.info('🔑 Navigating to login');
  }

  // Helper to get current router instance
  static GoRouter? _getCurrentRouter() {
    // This is a simplified approach. In production, you might want to
    // pass the router instance or use a different approach.
    return null; // You'll need to implement this based on your app structure
  }
}
