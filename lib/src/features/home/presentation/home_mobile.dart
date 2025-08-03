// lib/src/features/home/presentation/pages/home_mobile.dart

import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../../mail/presentation/pages/mobile/mail_page_mobile.dart';

/// Mobile-specific home page with module selection
///
/// This page provides a mobile-optimized interface for selecting
/// and navigating to different modules in the Korgan platform.
class HomeMobile extends StatelessWidget {
  const HomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('📱 Building HomeMobile');

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  /// Build app bar for mobile home
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.dashboard, color: Colors.white),
          SizedBox(width: 12),
          Text('Korgan Platform'),
        ],
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            // TODO: Navigate to profile page
            AppLogger.debug('📱 Profile button tapped');
          },
          tooltip: 'Profil',
        ),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(context),
            
            const SizedBox(height: 32),
            
            // Modules section
            _buildModulesSection(context),
            
            const Spacer(),
            
            // Platform indicator
            _buildPlatformIndicator(context),
          ],
        ),
      ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş Geldiniz',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hangi modüle girmek istiyorsunuz?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build modules section
  Widget _buildModulesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modüller',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        
        // Module buttons
        _buildModuleButton(
          context: context,
          icon: Icons.email,
          title: 'Mail',
          subtitle: 'E-posta yönetimi',
          color: Colors.blue,
          onTap: () => _navigateToMail(context),
        ),
        
        const SizedBox(height: 12),
        
        _buildModuleButton(
          context: context,
          icon: Icons.people,
          title: 'CRM',
          subtitle: 'Müşteri ilişkileri',
          color: Colors.green,
          onTap: () => _navigateToCRM(context),
        ),
        
        const SizedBox(height: 12),
        
        _buildModuleButton(
          context: context,
          icon: Icons.business,
          title: 'ERP',
          subtitle: 'Kurumsal kaynak planlama',
          color: Colors.orange,
          onTap: () => _navigateToERP(context),
        ),
      ],
    );
  }

  /// Build individual module button
  Widget _buildModuleButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build platform indicator
  Widget _buildPlatformIndicator(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Mobile Experience',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========== NAVIGATION METHODS ==========

  /// Navigate to Mail module
void _navigateToMail(BuildContext context) {
    AppLogger.info('📱 Navigating to Mail module');
    
    // For mobile, use Navigator.push for native mobile experience
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MailPageMobile(
          userEmail: 'berk@dynhyp.com',
        ),
      ),
    );   
  }

  /// Navigate to CRM module
  void _navigateToCRM(BuildContext context) {
    AppLogger.info('📱 Navigating to CRM module');
    
    // Navigate using AppRouter for consistency
    //AppRouter.goToModule('crm');
    _showNavigationFeedback(context, 'CRM modülü açılıyor...');
  }

  /// Navigate to ERP module
  void _navigateToERP(BuildContext context) {
    AppLogger.info('📱 Navigating to ERP module');
    
    // For now, show coming soon message
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