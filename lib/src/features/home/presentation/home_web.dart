// lib/src/features/home/presentation/home_web.dart

import 'package:flutter/material.dart';
import '../../../routing/app_router.dart';
import '../../../utils/app_logger.dart';

/// Web-specific home page with simple module navigation
///
/// Temiz ve basit web arayüzü. Sadece mail modülü navigation'u mevcut.
/// Gelecekte diğer modüller eklenecek.
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
      body: Container(
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
              //_buildHeader(),
              Expanded(child: _buildMainContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }


  // ========== MAIN CONTENT ==========

  Widget _buildMainContent() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome section
            Text(
              'Hoş Geldiniz',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hangi modüle gitmek istiyorsunuz?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            
            // Module grid
            _buildModuleGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: 1.2,
      children: [
        // Mail module (active)
        _buildModuleCard(
          title: 'Mail',
          subtitle: 'Email yönetimi',
          icon: Icons.mail,
          color: Colors.blue,
          isActive: true,
          onTap: () => _navigateToMail(),
        ),
        
        // CRM module (coming soon)
        _buildModuleCard(
          title: 'CRM',
          subtitle: 'Müşteri yönetimi',
          icon: Icons.people,
          color: Colors.green,
          isActive: false,
          onTap: () => _showComingSoon('CRM'),
        ),
        
        // ERP module (coming soon)
        _buildModuleCard(
          title: 'ERP',
          subtitle: 'İşletme yönetimi',
          icon: Icons.business,
          color: Colors.orange,
          isActive: false,
          onTap: () => _showComingSoon('ERP'),
        ),
        
        // Tasks module (coming soon)
        _buildModuleCard(
          title: 'Tasks',
          subtitle: 'Görev yönetimi',
          icon: Icons.task_alt,
          color: Colors.purple,
          isActive: false,
          onTap: () => _showComingSoon('Tasks'),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredModule == title;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredModule = title),
      onExit: (_) => setState(() => _hoveredModule = null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color : Colors.grey[200]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered 
                    ? color.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.05),
                blurRadius: isHovered ? 15 : 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isHovered ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isHovered ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isHovered ? color : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              // Status indicator
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Yakında',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== FOOTER ==========

  Widget _buildFooter() {
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
          Text('•', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(width: 16),
          Text(
            'Korgan Platform v1.0',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ========== NAVIGATION ==========

  void _navigateToMail() {
    AppLogger.info('🌐 Navigating to Mail module');
    
    // Default user email (later from user session)
    const userEmail = 'berk@argenteknoloji.com';
    
    AppRouter.goToMail(userEmail);
    
    _showSnackBar('Mail modülüne yönlendiriliyor...');
  }

  void _showComingSoon(String moduleName) {
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}