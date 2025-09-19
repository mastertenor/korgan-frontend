// lib/src/routing/app_router.dart - Clean Organization-Only Implementation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/simple_token_storage.dart';
import '../features/user/presentation/pages/platform/web/login_page_web.dart';
import '../features/home/presentation/home_web.dart';
import '../features/home/presentation/home_mobile.dart';
import '../features/mail/presentation/pages/mobile/mail_page_mobile.dart';
import '../features/mail/presentation/pages/web/mail_page_web.dart';
import '../features/mail/presentation/pages/web/mail_page_detail_web.dart';
import '../common_widgets/shell/app_shell.dart';
import '../utils/app_logger.dart';
import '../utils/platform_helper.dart';
import 'route_constants.dart';

// Global router reference for navigation from anywhere
GoRouter? _globalRouter;

/// Clean router with organization-only routes
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,

    // Simple auth check - no legacy route handling
    redirect: (context, state) async {
      final location = state.fullPath ?? '/';

      AppLogger.debug('Router: Auth check for $location');

      // Skip auth check for login page
      if (location == '/login') return null;

      // Auth validation
      try {
        final hasTokens = await SimpleTokenStorage.hasValidTokens();
        final hasAccessToken = await SimpleTokenStorage.getAccessToken();
        final hasRefreshToken = await SimpleTokenStorage.getRefreshToken();

        final isAuthenticated =
            hasTokens && hasAccessToken != null && hasRefreshToken != null;

        if (!isAuthenticated) {
          AppLogger.warning('Router: No tokens found, redirecting to login');
          return '/login';
        }

        // Token expiry check (but don't redirect - let interceptor handle it)
        final isExpired = await SimpleTokenStorage.isTokenExpired();
        if (isExpired) {
          AppLogger.warning(
            'Token expired - Auth interceptor will handle refresh',
          );
        }

        AppLogger.info('Router: Authentication successful');
        return null;
      } catch (e) {
        AppLogger.error('Router: Auth check error - $e');
        return '/login';
      }
    },

    routes: [
      // LOGIN PAGE (no shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          AppLogger.info('Building login page');
          return const LoginPageWeb();
        },
      ),

      // ERROR PAGE (no shell)
      GoRoute(
        path: '/error',
        name: 'error',
        builder: (context, state) {
          final message =
              state.uri.queryParameters['message'] ?? 'An error occurred';
          return ErrorPage(message: message);
        },
      ),

      // SHELL-WRAPPED ROUTES
      ShellRoute(
        builder: (context, state, child) {
          AppLogger.debug('Shell wrapper for: ${state.uri.path}');

          // Extract correct module name from route
          final module = _extractModuleFromRoute(state);
          AppLogger.debug('Extracted module: $module');

          return AppShell(
            currentModule: module, // Pass correct module name
            child: child,
          );
        },
        routes: [
          // ROOT REDIRECT
          GoRoute(path: '/', redirect: (context, state) => '/home'),

          // HOME PAGE (no organization needed)
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) {
              AppLogger.info('Building home page');
              return PlatformHelper.shouldUseMobileExperience
                  ? const HomeMobile()
                  : const HomeWeb();
            },
          ),

          // ORGANIZATION MAIL ROUTES
          GoRoute(
            path: MailRoutes.orgUserMail,
            name: 'org_mail',
            redirect: (context, state) {
              final orgSlug = state.pathParameters[RouteParams.orgSlug];
              final email = state.pathParameters[RouteParams.email];

              // Validation
              if (orgSlug == null || !RouteConstants.isValidOrgSlug(orgSlug)) {
                return '/error?message=Invalid organization';
              }

              if (email == null || !RouteConstants.isValidEmail(email)) {
                return '/error?message=Invalid email';
              }

              // Redirect to inbox
              final inboxPath = MailRoutes.orgDefaultFolderPath(orgSlug, email);
              AppLogger.info('Redirecting to inbox: $inboxPath');
              return inboxPath;
            },
            builder: (context, state) => const SizedBox.shrink(),
          ),

          GoRoute(
            path: MailRoutes.orgUserMailFolder,
            name: 'org_mail_folder',
            builder: (context, state) {
              return _buildOrgMailFolderPage(context, state);
            },
          ),

          GoRoute(
            path: MailRoutes.orgUserMailDetail,
            name: 'org_mail_detail',
            builder: (context, state) {
              return _buildOrgMailDetailPage(context, state);
            },
          ),

          // OTHER ORGANIZATION MODULES
          GoRoute(
            path: CrmRoutes.orgCrm,
            name: 'org_crm',
            builder: (context, state) {
              final orgSlug = state.pathParameters[RouteParams.orgSlug]!;
              return ModulePlaceholderPage(
                moduleName: 'CRM',
                icon: Icons.people,
                organizationSlug: orgSlug,
              );
            },
          ),

          GoRoute(
            path: TaskRoutes.orgTasks,
            name: 'org_tasks',
            builder: (context, state) {
              final orgSlug = state.pathParameters[RouteParams.orgSlug]!;
              return ModulePlaceholderPage(
                moduleName: 'Tasks',
                icon: Icons.task,
                organizationSlug: orgSlug,
              );
            },
          ),

          GoRoute(
            path: DashboardRoutes.orgDashboard,
            name: 'org_dashboard',
            builder: (context, state) {
              final orgSlug = state.pathParameters[RouteParams.orgSlug]!;
              return ModulePlaceholderPage(
                moduleName: 'Dashboard',
                icon: Icons.dashboard,
                organizationSlug: orgSlug,
              );
            },
          ),
        ],
      ),
    ],

    // Error handling
    errorBuilder: (context, state) {
      AppLogger.error('Router error: ${state.error}');
      return ErrorPage(message: 'Page not found: ${state.fullPath}');
    },
  );

  _globalRouter = router;
  return router;
});

// HELPER FUNCTION TO EXTRACT MODULE NAME FROM ROUTE
String _extractModuleFromRoute(GoRouterState state) {
  try {
    final segments = state.uri.pathSegments;

    // Route patterns:
    // /home -> "Home"
    // /argen-teknoloji/mail/user/folder -> "Mail"
    // /argen-teknoloji/crm -> "CRM"

    if (segments.isEmpty) return '';

    // Home page
    if (segments.first == 'home') {
      return 'Home';
    }

    // Organization routes: [orgSlug, module, ...]
    if (segments.length >= 2) {
      final module = segments[1];
      switch (module.toLowerCase()) {
        case 'mail':
          return 'Mail';
        case 'crm':
          return 'CRM';
        case 'tasks':
          return 'Tasks';
        case 'dashboard':
          return 'Dashboard';
        default:
          return _capitalize(module);
      }
    }

    return '';
  } catch (e) {
    AppLogger.error('Error extracting module from route: $e');
    return '';
  }
}

// Simple capitalize helper
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// ORGANIZATION MAIL PAGE BUILDERS

Widget _buildOrgMailFolderPage(BuildContext context, GoRouterState state) {
  final orgSlug = state.pathParameters[RouteParams.orgSlug];
  final email = state.pathParameters[RouteParams.email];
  final folder = state.pathParameters[RouteParams.folder];

  AppLogger.info('Building org mail folder: $orgSlug/$email/$folder');

  // Validation
  if (orgSlug == null || !RouteConstants.isValidOrgSlug(orgSlug)) {
    AppLogger.warning('Invalid org slug: $orgSlug');
    return ErrorPage(message: 'Invalid organization: $orgSlug');
  }

  if (email == null || !RouteConstants.isValidEmail(email)) {
    AppLogger.warning('Invalid email: $email');
    return ErrorPage(message: 'Invalid email address: $email');
  }

  if (folder == null || !MailFolderNames.isValid(folder)) {
    AppLogger.warning('Invalid folder: $folder');
    return ErrorPage(message: 'Invalid folder: $folder');
  }

  // Build appropriate page based on platform
  if (PlatformHelper.shouldUseMobileExperience) {
    return MailPageMobile(userEmail: email);
  } else {
    return MailPageWeb(
      userEmail: email,
      initialFolder: folder,
      organizationSlug: orgSlug,
    );
  }
}

Widget _buildOrgMailDetailPage(BuildContext context, GoRouterState state) {
  final orgSlug = state.pathParameters[RouteParams.orgSlug];
  final email = state.pathParameters[RouteParams.email];
  final folder = state.pathParameters[RouteParams.folder];
  final mailId = state.pathParameters[RouteParams.mailId];

  AppLogger.info('Building org mail detail: $orgSlug/$email/$folder/$mailId');

  // Validation
  if (orgSlug == null || !RouteConstants.isValidOrgSlug(orgSlug)) {
    return ErrorPage(message: 'Invalid organization: $orgSlug');
  }

  if (email == null || !RouteConstants.isValidEmail(email)) {
    return ErrorPage(message: 'Invalid email address: $email');
  }

  if (folder == null || !MailFolderNames.isValid(folder)) {
    return ErrorPage(message: 'Invalid folder: $folder');
  }

  if (mailId == null || mailId.isEmpty) {
    return ErrorPage(message: 'Invalid mail ID: $mailId');
  }

  // Build appropriate page based on platform
  if (PlatformHelper.shouldUseMobileExperience) {
    return MailPageMobile(userEmail: email);
  } else {
    return MailPageDetailWeb(
      userEmail: email,
      folder: folder,
      mailId: mailId,
      organizationSlug: orgSlug,
    );
  }
}

// UTILITY WIDGETS

class ModulePlaceholderPage extends StatelessWidget {
  final String moduleName;
  final IconData icon;
  final String organizationSlug;

  const ModulePlaceholderPage({
    super.key,
    required this.moduleName,
    required this.icon,
    required this.organizationSlug,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$moduleName Module',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Organization: $organizationSlug',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String message;

  const ErrorPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 24),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
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
}

// NAVIGATION HELPERS

class AppRouter {
  static GoRouter getRouter(WidgetRef ref) {
    return ref.watch(routerProvider);
  }

  static void goToHome() {
    _globalRouter?.go('/home');
    AppLogger.info('Navigating to home');
  }

  static void goToLogin() {
    _globalRouter?.go('/login');
    AppLogger.info('Navigating to login');
  }

  static GoRouter? get globalRouter => _globalRouter;
}
