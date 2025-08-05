// lib/src/common_widgets/shell/web_app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_logger.dart';

/// Web-optimized application shell with unified header
/// 
/// Bu shell web platformunda tüm sayfalarda ortak header sağlar:
/// - Gmail-style top header (64px fixed)
/// - Module navigation with breadcrumb
/// - Global search bar
/// - Profile dropdown with notifications
/// - Clean, professional web design
class WebAppShell extends ConsumerWidget {
  final Widget child;
  
  const WebAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Gmail-style background
      body: Column(
        children: [
          // Fixed Top Header
          WebGlobalHeader(),
          
          // Page Content - Full height minus header
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Web Global Header - Gmail-inspired design
class WebGlobalHeader extends ConsumerWidget {
  const WebGlobalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Left Section: Logo + Module Navigation
          _buildLeftSection(context),
          
          const SizedBox(width: 40),
          
          // Center Section: Global Search
          Expanded(child: _buildSearchSection()),
          
          const SizedBox(width: 40),
          
          // Right Section: Actions + Profile
          _buildRightSection(context),
        ],
      ),
    );
  }

  /// Left section: Logo + Module breadcrumb
  Widget _buildLeftSection(BuildContext context) {
    final currentModule = _getCurrentModule(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo - Clickable to home
        GestureDetector(
          onTap: () {
            context.go('/');
            AppLogger.info('🏠 Navigated to home from logo');
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // App Name + Module Breadcrumb
        Row(
          children: [
            // App Name
            GestureDetector(
              onTap: () => context.go('/'),
              child: Text(
                'Korgan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ),
            
            // Module Breadcrumb
            if (currentModule.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentModule,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Center section: Global search bar
  Widget _buildSearchSection() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600), // Gmail-style max width
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Tüm modüllerde ara...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                Icons.search_rounded,
                color: Colors.grey[500],
                size: 20,
              ),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  // Advanced search modal
                  _showAdvancedSearch();
                },
                icon: Icon(
                  Icons.tune_rounded,
                  color: Colors.grey[500],
                  size: 18,
                ),
                tooltip: 'Gelişmiş Arama',
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _performGlobalSearch(query.trim());
            }
          },
        ),
      ),
    );
  }

  /// Right section: Notifications + Profile dropdown
  Widget _buildRightSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Actions (Module-specific)
        //_buildQuickActions(context),
        
        const SizedBox(width: 16),
        
        // Notifications
        _buildNotificationsButton(),
        
        const SizedBox(width: 12),
        
        // Profile Dropdown
        _buildProfileDropdown(context),
      ],
    );
  }

  /// Quick actions based on current module
  Widget _buildQuickActions(BuildContext context) {
    final currentModule = _getCurrentModule(context);
    
    // Module-specific quick actions
    switch (currentModule.toLowerCase()) {
      case 'mail':
        return IconButton(
          onPressed: () {
            // Compose new mail
            AppLogger.info('✍️ Quick compose from header');
          },
          icon: Icon(Icons.edit_rounded, color: Colors.grey[600]),
          tooltip: 'Yeni E-posta',
        );
      case 'crm':
        return IconButton(
          onPressed: () {
            // Add new contact
            AppLogger.info('👤 Quick add contact from header');
          },
          icon: Icon(Icons.person_add_rounded, color: Colors.grey[600]),
          tooltip: 'Yeni Kişi',
        );
      case 'tasks':
        return IconButton(
          onPressed: () {
            // Add new task
            AppLogger.info('✓ Quick add task from header');
          },
          icon: Icon(Icons.add_task_rounded, color: Colors.grey[600]),
          tooltip: 'Yeni Görev',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Notifications button with badge
  Widget _buildNotificationsButton() {
    return IconButton(
      onPressed: () {
        _showNotificationsPanel();
      },
      icon: Stack(
        children: [
          Icon(
            Icons.notifications_rounded,
            color: Colors.grey[600],
            size: 22,
          ),
          // Notification badge
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red[500],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      tooltip: 'Bildirimler (3)',
    );
  }

  /// Profile dropdown menu
  Widget _buildProfileDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Profil Menüsü',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[600],
              backgroundImage: null, // TODO: User image
              child: const Text(
                'B', // TODO: User initials
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Dropdown arrow
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[600],
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // User Info Header
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berk Kızıltan', // TODO: User name
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'berk@dynhyp.com', // TODO: User email
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        
        // Profile Actions
        PopupMenuItem(
          value: 'profile',
          child: _buildMenuItem(
            icon: Icons.person_rounded,
            title: 'Profil',
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: _buildMenuItem(
            icon: Icons.settings_rounded,
            title: 'Ayarlar',
          ),
        ),
        PopupMenuItem(
          value: 'help',
          child: _buildMenuItem(
            icon: Icons.help_rounded,
            title: 'Yardım',
          ),
        ),
        const PopupMenuDivider(),
        
        // Logout
        PopupMenuItem(
          value: 'logout',
          child: _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Çıkış Yap',
            color: Colors.red[600],
          ),
        ),
      ],
      onSelected: (value) {
        _handleProfileAction(context, value);
      },
    );
  }

  /// Helper: Build menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? color,
  }) {
    final itemColor = color ?? Colors.grey[700];
    
    return Row(
      children: [
        Icon(icon, color: itemColor, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ========== HELPER METHODS ==========

  /// Get current module from route
  String _getCurrentModule(BuildContext context) {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final segments = location.split('/');
    
    if (segments.length > 1 && segments[1].isNotEmpty) {
      final module = segments[1];
      // Map route segments to display names
      switch (module) {
        case 'mail':
          return 'Mail';
        case 'crm':
          return 'CRM';
        case 'tasks':
          return 'Görevler';
        case 'files':
          return 'Dosyalar';
        case 'chat':
          return 'Sohbet';
        case 'dashboard':
          return 'Dashboard';
        default:
          return _capitalize(module);
      }
    }
    return '';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ========== ACTION HANDLERS ==========

  void _performGlobalSearch(String query) {
    AppLogger.info('🔍 Global search: $query');
    // TODO: Implement global search logic
    // - Search across all modules
    // - Show search results page/modal
  }

  void _showAdvancedSearch() {
    AppLogger.info('🔍 Advanced search modal');
    // TODO: Show advanced search modal
    // - Filter by module
    // - Date ranges
    // - Content types
  }

  void _showNotificationsPanel() {
    AppLogger.info('🔔 Notifications panel');
    // TODO: Show notifications panel/modal
    // - Recent notifications
    // - Mark as read functionality
  }

  void _handleProfileAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        AppLogger.info('👤 Profile page');
        // TODO: Navigate to profile page
        break;
      case 'settings':
        AppLogger.info('⚙️ Settings page');
        // TODO: Navigate to settings page
        break;
      case 'help':
        AppLogger.info('❓ Help page');
        // TODO: Show help modal/page
        break;
      case 'logout':
        AppLogger.info('🚪 Logout');
        // TODO: Implement logout logic
        // - Clear auth state
        // - Navigate to login
        break;
    }
  }
}

// ========== UPDATED APP ROUTER FOR WEB SHELL ==========
// lib/src/routing/app_router.dart update snippet

/*
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteConstants.home,
    
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Sadece web için shell kullan
          if (PlatformHelper.shouldUseWebExperience) {
            return WebAppShell(child: child);
          } else {
            // Mobile için şimdilik shell yok, direkt sayfa döndür
            return child;
          }
        },
        routes: [
          GoRoute(
            path: RouteConstants.home,
            name: 'home',
            builder: (context, state) => _buildHomePage(context, state),
          ),
          GoRoute(
            path: MailRoutes.userMail,
            name: 'mail',
            builder: (context, state) => _buildMailPage(context, state),
          ),
          // Future modules...
        ],
      ),
    ],
  );

  // Page builders - web için header'sız version döndür
  static Widget _buildMailPage(BuildContext context, GoRouterState state) {
    final email = state.pathParameters[RouteParams.email];
    
    if (email == null || !RouteConstants.isValidEmail(email)) {
      return ErrorPage(error: 'Invalid email');
    }

    if (PlatformHelper.shouldUseWebExperience) {
      // Web: Header yok, sadece content
      return MailPageWeb(userEmail: email, showHeader: false);
    } else {
      // Mobile: Geleneksel AppBar'lı version
      return MailPageMobile(userEmail: email);
    }
  }
}
*/