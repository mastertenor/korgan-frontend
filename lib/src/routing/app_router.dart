// lib/src/core/routing/app_router.dart - Simplified Platform-Aware Router

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/mail/presentation/pages/mobile/mail_page_mobile.dart';
import '../features/mail/presentation/pages/web/mail_page_web.dart';
import '../utils/platform_helper.dart';
import '../utils/app_logger.dart';
import '../features/home/presentation/home_mobile.dart';
import '../features/home/presentation/home_web.dart';

/// Simplified platform-aware routing configuration
///
/// This router only handles platform-aware home page routing.
/// Each module will handle its own internal routing separately.
class AppRouter {
  // Route path constants
  static const String _homeRoute = '/';

  /// Main GoRouter configuration - only handles home routing
  static final GoRouter router = GoRouter(
    initialLocation: _homeRoute,
    debugLogDiagnostics: true,
    
    routes: [
      // ========== PLATFORM-AWARE HOME ROUTE ==========
      GoRoute(
        path: _homeRoute,
        name: 'home',
        builder: (context, state) {
          final platform = PlatformHelper.recommendedExperience;
          AppLogger.info('🏠 Routing to $platform home');
          
          // Platform-based home page selection
          switch (platform) {
            case 'mobile':
              return const HomeMobile();
            case 'web':
              return const HomeWeb();
            default:
              AppLogger.warning('Unknown platform: $platform, falling back to mobile');
              return const HomeMobile();
          }
        },
      ),

      // ========== MODULE PLACEHOLDERS ==========
      // These will be replaced by module-specific routers later
      
      GoRoute(
        path: '/mail',
        name: 'mail',
        builder: (context, state) {
          final user = state.uri.queryParameters['user'] ?? 'guest@example.com';
          
          if (PlatformHelper.shouldUseMobileExperience) {
            return MailPageMobile(userEmail: user);
          } else {
            return MailPageWeb(userEmail: user);
          }
        }
      ),
      
      GoRoute(
        path: '/crm',
        name: 'crm-placeholder',
        builder: (context, state) => _buildModulePlaceholder('CRM', Colors.green),
      ),
      
      GoRoute(
        path: '/erp',
        name: 'erp-placeholder',
        builder: (context, state) => _buildModulePlaceholder('ERP', Colors.orange),
      ),
      
      GoRoute(
        path: '/tasks',
        name: 'tasks-placeholder',
        builder: (context, state) => _buildModulePlaceholder('Tasks', Colors.purple),
      ),
      
      GoRoute(
        path: '/files',
        name: 'files-placeholder',
        builder: (context, state) => _buildModulePlaceholder('Files', Colors.teal),
      ),
      
      GoRoute(
        path: '/chat',
        name: 'chat-placeholder',
        builder: (context, state) => _buildModulePlaceholder('Chat', Colors.indigo),
      ),
      
      GoRoute(
        path: '/dashboard',
        name: 'dashboard-placeholder',
        builder: (context, state) => _buildModulePlaceholder('Dashboard', Colors.amber),
      ),
    ],

    // ========== ERROR HANDLING ==========
    errorBuilder: (context, state) => _ErrorPage(
      error: state.error.toString(),
      location: state.uri.toString(),
    ),

    // ========== GLOBAL REDIRECT LOGIC ==========
    redirect: (context, state) {
      // Add global redirect logic here (auth, onboarding, etc.)
      AppLogger.debug('🔄 Router redirect check: ${state.uri}');
      return null; // No redirect needed for now
    },
  );

  // ========== SIMPLE NAVIGATION HELPERS ==========

  /// Navigate to platform-appropriate home
  static void goToHome() {
    router.go(_homeRoute);
    AppLogger.info('🏠 Navigating to home');
  }

  /// Navigate to module by name
  static void goToModule(String moduleName) {
    final route = '/$moduleName';
    router.go(route);
    AppLogger.info('📦 Navigating to module: $moduleName');
  }

  // ========== UTILITY METHODS ==========

  /// Get current route location
  static String get currentLocation => 
      router.routerDelegate.currentConfiguration.uri.toString();

  /// Check if currently on home page
  static bool get isOnHomePage => currentLocation == '/';

  /// Get current module name from route
  static String? get currentModule {
    final location = currentLocation;
    if (location == '/') return null;
    
    final segments = location.split('/');
    return segments.length > 1 ? segments[1] : null;
  }
}

/// Module placeholder widget for development
Widget _buildModulePlaceholder(String moduleName, Color color) {
  return Scaffold(
    appBar: AppBar(
      title: Text('$moduleName Module'),
      backgroundColor: color,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.home),
        onPressed: () => AppRouter.goToHome(),
        tooltip: 'Ana Sayfa',
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.construction,
                size: 64,
                color: color,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              '$moduleName Module',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Bu modül geliştiriliyor...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Modül kendi internal routing sistemini burada yönetecek',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => AppRouter.goToHome(),
                  icon: const Icon(Icons.home),
                  label: const Text('Ana Sayfaya Dön'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                OutlinedButton.icon(
                  onPressed: () {
                    AppLogger.info('📦 $moduleName module settings clicked');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Modül Ayarları'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Route: ${AppRouter.currentLocation}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform: ${PlatformHelper.recommendedExperience}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Simple error page
class _ErrorPage extends StatelessWidget {
  final String error;
  final String location;

  const _ErrorPage({required this.error, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
}