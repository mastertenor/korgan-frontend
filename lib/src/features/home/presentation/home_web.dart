// lib/src/features/home/presentation/pages/home_web.dart

import 'package:flutter/material.dart';
import '../../../routing/app_router.dart';
import '../../../utils/app_logger.dart';

/// Web-specific home page with module selection
///
/// This page provides a web-optimized interface for selecting
/// and navigating to different modules in the Korgan platform.
/// Features hover effects, larger click targets, and web-specific UX.
class HomeWeb extends StatefulWidget {
  const HomeWeb({super.key});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb> {
  String? _hoveredModule;

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🌐 Building HomeWeb');

    return Scaffold(
      body: _buildBody(context),
    );
  }

  /// Build main body content
  Widget _buildBody(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Main content
            Expanded(
              child: _buildMainContent(context),
            ),
            
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo and title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Korgan Platform',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Modular Enterprise Platform',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // User actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  AppLogger.debug('🌐 Notifications clicked');
                },
                tooltip: 'Bildirimler',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {
                  AppLogger.debug('🌐 Profile clicked');
                },
                tooltip: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build main content section
Widget _buildMainContent(BuildContext context) {
  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome section
          _buildWelcomeSection(context),

          const SizedBox(height: 48),

          // Modules grid wrapped in Expanded to prevent overflow
          Expanded(
            child: _buildModulesGrid(context),
          ),
        ],
      ),
    ),
  );
}

  /// Build welcome section
  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Hoş Geldiniz',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Korgan Platform modüllerini seçerek işlemlerinizi gerçekleştirin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build modules grid
  Widget _buildModulesGrid(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
        children: [
          _buildModuleCard(
            context: context,
            id: 'mail',
            icon: Icons.email,
            title: 'Mail',
            subtitle: 'E-posta Yönetimi',
            color: Colors.blue,
            onTap: () => _navigateToMail(context),
          ),
          _buildModuleCard(
            context: context,
            id: 'crm',
            icon: Icons.people,
            title: 'CRM',
            subtitle: 'Müşteri İlişkileri',
            color: Colors.green,
            onTap: () => _navigateToCRM(context),
          ),
          _buildModuleCard(
            context: context,
            id: 'erp',
            icon: Icons.business,
            title: 'ERP',
            subtitle: 'Kurumsal Kaynak',
            color: Colors.orange,
            onTap: () => _navigateToERP(context),
          ),
        ],
      ),
    );
  }

  /// Build individual module card
  Widget _buildModuleCard({
    required BuildContext context,
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredModule == id;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredModule = id),
      onExit: (_) => setState(() => _hoveredModule = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.05 : 1.0),
        child: Card(
          elevation: isHovered ? 12 : 4,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isHovered
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isHovered 
                          ? color 
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: isHovered 
                          ? Colors.white 
                          : color,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isHovered ? color : Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Subtitle
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build footer section
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.web, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Web Experience',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '•',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          Text(
            'Korgan Platform v1.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ========== NAVIGATION METHODS ==========

  /// Navigate to Mail module
  void _navigateToMail(BuildContext context) {
    AppLogger.info('🌐 Navigating to Mail module');
    
    // For web, we use Go Router for URL-based navigation
    AppRouter.goToModule('mail'); // TODO: Get from user session
    
    _showNavigationFeedback(context, 'Mail modülüne yönlendiriliyor...');
  }

  /// Navigate to CRM module
  void _navigateToCRM(BuildContext context) {
    AppLogger.info('🌐 Navigating to CRM module');
    
    AppRouter.goToModule('crm');
    _showNavigationFeedback(context, 'CRM modülüne yönlendiriliyor...');
  }

  /// Navigate to ERP module
  void _navigateToERP(BuildContext context) {
    AppLogger.info('🌐 Navigating to ERP module');
    
    _showComingSoonDialog(context, 'ERP');
  }

  /// Show navigation feedback
  void _showNavigationFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoonDialog(BuildContext context, String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.construction, color: Colors.orange, size: 48),
        title: Text('$moduleName Modülü'),
        content: const Text(
          'Bu modül henüz geliştiriliyor.\nYakında kullanıma sunulacak!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}