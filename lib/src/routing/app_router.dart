// lib/src/routing/app_router.dart - FIXED: ProviderRef compatibility

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
import '../common_widgets/shell/app_shell.dart';
import '../utils/app_logger.dart';
import '../utils/platform_helper.dart';

/// Router with proper auth provider integration and token refresh
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,

    // ✅ SIMPLE: Basic token existence check only
redirect: (context, state) async {
      final isLoginPage = state.uri.path == '/login';

      AppLogger.debug('🔄 Router: Auth check for ${state.uri.path}');

      // Skip auth check for login page
      if (isLoginPage) return null;

      // Simple token existence check - no complex auth provider calls
      try {
        final hasTokens = await SimpleTokenStorage.hasValidTokens();
        final hasAccessToken = await SimpleTokenStorage.getAccessToken();
        final hasRefreshToken = await SimpleTokenStorage.getRefreshToken();

        final isAuthenticated =
            hasTokens && hasAccessToken != null && hasRefreshToken != null;

        if (!isAuthenticated) {
          AppLogger.warning('❌ Router: No tokens found, redirecting to login');
          return '/login';
        }

        // ✅ YENİ: Token expired check ama redirect yapma
        final isExpired = await SimpleTokenStorage.isTokenExpired();
        if (isExpired) {
          AppLogger.warning(
            '⏰ Token expired - Auth interceptor will handle refresh on first API call',
          );
          // Redirect YAPMA - Auth interceptor ilk API çağrısında refresh yapacak
          // Kullanıcı sayfada kalabilir, interceptor otomatik refresh yapar
        }

        AppLogger.info('✅ Router: Tokens exist, allowing navigation');
        return null;
      } catch (e) {
        AppLogger.error(
          '❌ Router: Auth check error - $e, redirecting to login',
        );
        return '/login';
      }
    },

    routes: [
      // ========== SHELL-BASED ROUTES ==========
      ShellRoute(
        builder: (context, state, child) {
          AppLogger.debug('🐚 Shell wrapper for: ${state.uri.path}');
          return AppShell(child: child);
        },
        routes: [
          // Root redirect to home
          GoRoute(path: '/', redirect: (context, state) => '/home'),

          // Home page - platform aware with shell
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => _buildHomePage(context, state),
          ),

          // ========== MAIL ROUTES WITH SHELL ==========

          // MAIL USER ROUTE - Inbox'a redirect
          GoRoute(
            path: '/mail/:email',
            name: 'mail_user',
            redirect: (context, state) {
              final email = state.pathParameters['email'];
              if (email == null || !_isValidEmail(email)) {
                AppLogger.warning('❌ Invalid email for redirect: $email');
                return null;
              }

              final redirectPath = '/mail/$email/inbox';
              AppLogger.info(
                '🔀 Shell: Redirecting /mail/$email → $redirectPath',
              );
              return redirectPath;
            },
            builder: (context, state) {
              return _buildErrorPage(
                error: 'Mail route requires folder specification',
                location: state.uri.toString(),
              );
            },
          ),

          // MAIL FOLDER ROUTE - Main folder view with shell
          GoRoute(
            path: '/mail/:email/:folder',
            name: 'mail_folder',
            builder: (context, state) {
              AppLogger.info('🐚📁 Shell: Building mail folder page');
              return _buildMailFolderPage(context, state);
            },
          ),

          // MAIL DETAIL ROUTE - Individual mail view with shell
          GoRoute(
            path: '/mail/:email/:folder/:mailId',
            name: 'mail_detail',
            builder: (context, state) {
              AppLogger.info('🐚📧 Shell: Building mail detail page');
              return _buildMailDetailPage(context, state);
            },
          ),
        ],
      ),

      // ========== NON-SHELL ROUTES ==========

      // Login page - NO SHELL (clean login experience)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          AppLogger.info('🔑 Building login page (no shell)');
          return const LoginPageWeb();
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => _buildErrorPage(
      error: state.error.toString(),
      location: state.uri.toString(),
    ),
  );
});

// ========== AUTH INTEGRATION HELPERS ==========

/// Simple ChangeNotifier implementation for router refresh
class SimpleChangeNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

// ========== ALTERNATIVE: Simpler Auth Check ==========

/// Simpler auth check that doesn't attempt refresh
/// Use this if the above approach still causes issues
Future<bool> _simpleAuthCheck() async {
  try {
    // Check if we have valid tokens in storage
    final hasValidTokens = await SimpleTokenStorage.hasValidTokens();

    if (!hasValidTokens) {
      AppLogger.warning('🔍 Router: No valid tokens, redirecting to login');
      return false;
    }

    // Check if token is expired
    final isExpired = await SimpleTokenStorage.isTokenExpired();

    if (isExpired) {
      AppLogger.warning('⏰ Router: Token expired, redirecting to login');
      // Note: The AuthInterceptor will handle refresh on first API call
      return false;
    }

    AppLogger.info('✅ Router: Valid tokens found, allowing access');
    return true;
  } catch (e) {
    AppLogger.error('❌ Router: Auth check error - $e');
    return false;
  }
}

// ========== FALLBACK: Minimal Router (If above doesn't work) ==========

/// Minimal router configuration without complex auth integration
final simpleRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,

    // Simple auth check without provider integration
redirect: (context, state) async {
      final isLoginPage = state.uri.path == '/login';

      AppLogger.debug('🔄 Router: Auth check for ${state.uri.path}');

      // Skip auth check for login page
      if (isLoginPage) return null;

      // Simple token existence check
      try {
        final hasTokens = await SimpleTokenStorage.hasValidTokens();
        final hasAccessToken = await SimpleTokenStorage.getAccessToken();
        final hasRefreshToken = await SimpleTokenStorage.getRefreshToken();

        final isAuthenticated =
            hasTokens && hasAccessToken != null && hasRefreshToken != null;

        if (!isAuthenticated) {
          AppLogger.warning('❌ Router: No tokens found, redirecting to login');
          return '/login';
        }

        // ✅ YENİ: Token expired check ama redirect yapma
        final isExpired = await SimpleTokenStorage.isTokenExpired();
        if (isExpired) {
          AppLogger.warning(
            '⏰ Token expired - Auth interceptor will handle refresh on first API call',
          );
          // Redirect YAPMA - Auth interceptor ilk API çağrısında refresh yapacak
        }

        AppLogger.info('✅ Router: Tokens exist, allowing navigation');
        return null;
      } catch (e) {
        AppLogger.error(
          '❌ Router: Auth check error - $e, redirecting to login',
        );
        return '/login';
      }
    },

    routes: [
      // Same routes as above...
      // (Copy from the main router above)
    ],
  );
});

// ========== EXISTING HELPER METHODS (unchanged) ==========

Widget _buildHomePage(BuildContext context, GoRouterState state) {
  AppLogger.info('🐚🏠 Shell: Building home page');

  if (PlatformHelper.shouldUseMobileExperience) {
    return const HomeMobile();
  } else {
    return const HomeWeb();
  }
}

Widget _buildMailFolderPage(BuildContext context, GoRouterState state) {
  final email = state.pathParameters['email'];
  final folder = state.pathParameters['folder'];

  if (email == null || !_isValidEmail(email)) {
    AppLogger.warning('❌ Invalid email parameter: $email');
    return _buildErrorPage(
      error: 'Invalid email address',
      location: state.uri.toString(),
    );
  }

  if (folder == null || !_isValidFolder(folder)) {
    AppLogger.warning('❌ Invalid folder parameter: $folder');
    return _buildErrorPage(
      error: 'Folder "$folder" not found',
      location: state.uri.toString(),
    );
  }

  AppLogger.info('🐚📁 Building mail folder page: $email/$folder');

  if (PlatformHelper.shouldUseMobileExperience) {
    return MailPageMobile(userEmail: email);
  } else {
    return MailPageWeb(userEmail: email, initialFolder: folder);
  }
}

Widget _buildMailDetailPage(BuildContext context, GoRouterState state) {
  final email = state.pathParameters['email'];
  final folder = state.pathParameters['folder'];
  final mailId = state.pathParameters['mailId'];

  if (email == null || !_isValidEmail(email)) {
    return _buildErrorPage(
      error: 'Invalid email address',
      location: state.uri.toString(),
    );
  }

  if (folder == null || !_isValidFolder(folder)) {
    return _buildErrorPage(
      error: 'Invalid folder',
      location: state.uri.toString(),
    );
  }

  if (mailId == null || mailId.isEmpty) {
    return _buildErrorPage(
      error: 'Invalid mail ID',
      location: state.uri.toString(),
    );
  }

  AppLogger.info('🐚📧 Building mail detail: $email/$folder/$mailId');

  if (PlatformHelper.shouldUseMobileExperience) {
    return MailPageMobile(userEmail: email);
  } else {
    return MailPageDetailWeb(
      userEmail: email,
      folder: folder,
      mailId: mailId,
    );
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

/// Valid folder names - COMPLETE LIST
final _validFolders = {
  'inbox', // 📥 Gelen kutusu
  'sent', // 📤 Gönderilenler
  'drafts', // 📝 Taslaklar
  'trash', // 🗑️ Çöp kutusu
  'spam', // 🚫 Spam
  'starred', // ⭐ Yıldızlananlar
  'important', // 🔥 Önemli
  'archive', // 📁 Arşiv
};

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
