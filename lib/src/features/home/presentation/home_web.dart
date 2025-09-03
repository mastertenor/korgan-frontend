// lib/src/features/home/presentation/home_web.dart - UPDATED with Token Monitor

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_logger.dart';
import '../../auth/presentation/widgets/debug/token_monitor_widget.dart'; // ✅ NEW IMPORT

/// Web-specific home page with simple module navigation and token monitoring
///
/// ✅ UPDATED: Added TokenMonitorWidget for debugging token refresh
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
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // ✅ NEW: Left Panel with Token Monitor
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  border: Border(
                    right: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Token Monitor Widget
                    const TokenMonitorWidget(),

                    // Additional debug info can go here
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Debug Panel',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Token refresh testi için:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• F5 yapın (page refresh)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '• Mail modülüne gidin',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '• Token süresini izleyin',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildMainContent()),
                    _buildFooter(),
                  ],
                ),
              ),
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
        constraints: const BoxConstraints(maxWidth: 600),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Module Grid
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
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.2,
      children: [
        _buildModuleCard(
          icon: Icons.email_outlined,
          title: 'Mail',
          description: 'E-posta yönetimi',
          color: Colors.blue,
          onTap: () => _navigateToMail(),
          moduleId: 'mail',
        ),
        _buildModuleCard(
          icon: Icons.people_outline,
          title: 'CRM',
          description: 'Müşteri yönetimi',
          color: Colors.green,
          onTap: () => _showComingSoon('CRM'),
          moduleId: 'crm',
        ),
        _buildModuleCard(
          icon: Icons.task_outlined,
          title: 'Görevler',
          description: 'Görev takibi',
          color: Colors.orange,
          onTap: () => _showComingSoon('Görevler'),
          moduleId: 'tasks',
        ),
        _buildModuleCard(
          icon: Icons.insert_drive_file_outlined,
          title: 'Dosyalar',
          description: 'Dosya yönetimi',
          color: Colors.purple,
          onTap: () => _showComingSoon('Dosyalar'),
          moduleId: 'files',
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required String moduleId,
  }) {
    final isHovered = _hoveredModule == moduleId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredModule = moduleId),
      onExit: (_) => setState(() => _hoveredModule = null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                blurRadius: isHovered ? 20 : 10,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
              color: isHovered ? color.withOpacity(0.3) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== NAVIGATION ==========

  void _navigateToMail() {
    // Test kullanıcısının mail'ine git - token refresh test için
    const testEmail = 'test@example.com';
    final mailPath = '/mail/$testEmail/inbox';

    AppLogger.info('🔄 Navigating to mail: $mailPath');
    context.go(mailPath);
  }

  void _showComingSoon(String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$moduleName Modülü'),
        content: const Text('Bu modül henüz geliştirme aşamasındadır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ========== FOOTER ==========

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '© 2024 Korgan Platform - Token Refresh Debug Mode',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.black45),
        textAlign: TextAlign.center,
      ),
    );
  }
}
