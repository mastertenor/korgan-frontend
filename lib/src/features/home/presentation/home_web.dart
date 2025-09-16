// lib/src/features/home/presentation/home_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/simple_token_storage.dart';
import '../../../utils/app_logger.dart';
import '../../user/presentation/providers/auth_providers.dart';
import '../../organization/presentation/utils/organization_navigation_helper.dart';

/// Web-specific home page with debug functionality for token refresh testing
class HomeWeb extends ConsumerStatefulWidget {
  const HomeWeb({super.key});

  @override
  ConsumerState<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends ConsumerState<HomeWeb> {
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
          child: Column(
            children: [
              Expanded(child: _buildMainContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

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
              const SizedBox(height: 40),

              // Module Grid
              _buildModuleGrid(),

              const SizedBox(height: 32),

              // DEBUG SECTION - Token Refresh Test
              _buildDebugSection(),

              const SizedBox(height: 60), // Extra space for footer
            ],
          ),
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

  // DEBUG SECTION for Token Refresh Testing
  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Token Refresh Debug Panel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // First Row of Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testApiCall,
                  icon: const Icon(Icons.api, size: 18),
                  label: const Text('Test API Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkAuthStatus,
                  icon: const Icon(Icons.verified_user, size: 18),
                  label: const Text('Check Auth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Second Row of Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showTokenInfo,
                  icon: const Icon(Icons.info, size: 18),
                  label: const Text('Token Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testInterceptor,
                  icon: const Icon(Icons.security, size: 18),
                  label: const Text('Test Interceptor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Adımları:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1. "Token Info" ile mevcut token durumunu kontrol edin',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
                Text(
                  '2. "Test API Call" ile expired token durumunda refresh tetikleyin',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
                Text(
                  '3. Console loglarını takip edin',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DEBUG METHODS
Future<void> _testApiCall() async {
    AppLogger.info('🧪 MANUAL TEST: Starting API call');
    _showSnackBar(
      'API çağrısı başlatıldı - Log\'ları kontrol edin',
      Colors.blue,
    );

    try {
      final apiClient = ApiClient.instance;

      // ✅ CRITICAL FIX: Interceptor kontrolü ve yeniden kurulum
      bool hasInterceptor = apiClient.hasAuthInterceptor;
      AppLogger.info('🧪 Has interceptor BEFORE check: $hasInterceptor');

      // Eğer interceptor yoksa, auth notifier'dan yeniden kur
      if (!hasInterceptor) {
        AppLogger.warning(
          '🧪 Interceptor missing! Re-initializing from AuthNotifier...',
        );

        // AuthNotifier'a erişim
        final authNotifier = ref.read(authNotifierProvider.notifier);

        // Interceptor'ı yeniden kur
        await authNotifier.checkAuthStatus(); // Bu interceptor'ı kuracak

        // Tekrar kontrol et
        hasInterceptor = apiClient.hasAuthInterceptor;
        AppLogger.info('🧪 Has interceptor AFTER re-init: $hasInterceptor');
      }

      final response = await apiClient.get('/api/auth/user/profile');
      AppLogger.info('🧪 API call success: ${response.statusCode}');

      _showSnackBar('API çağrısı başarılı!', Colors.green);
    } catch (e) {
      AppLogger.error('🧪 API call failed: $e');
      _showSnackBar('API çağrısı başarısız: $e', Colors.red);
    }
  }

  // ✅ YENİ: Interceptor durumunu kontrol etmek için ayrı method
  Future<void> _testInterceptor() async {
    AppLogger.info('🧪 INTERCEPTOR TEST: Checking interceptor status');

    final apiClient = ApiClient.instance;
    final hasInterceptor = apiClient.hasAuthInterceptor;

    AppLogger.info('🧪 Interceptor status: $hasInterceptor');

    if (!hasInterceptor) {
      _showSnackBar('❌ Interceptor YOK! Re-initializing...', Colors.orange);

      // Auth notifier'dan interceptor'ı yeniden kur
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.checkAuthStatus();

      final newStatus = apiClient.hasAuthInterceptor;
      AppLogger.info('🧪 Interceptor status after re-init: $newStatus');

      _showSnackBar(
        newStatus ? '✅ Interceptor kuruldu!' : '❌ Interceptor kurulamadı!',
        newStatus ? Colors.green : Colors.red,
      );
    } else {
      _showSnackBar('✅ Interceptor aktif!', Colors.green);
    }
  }

  Future<void> _checkAuthStatus() async {
    AppLogger.info('🧪 AUTH STATUS: Checking interceptor setup');
    _showSnackBar('Auth status kontrolü başlatıldı', Colors.blue);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.checkAuthStatus();
      AppLogger.info(authNotifier.toString());

      _showSnackBar('Auth status check tamamlandı', Colors.green);
    } catch (e) {
      AppLogger.error('🧪 Auth status check failed: $e');
      _showSnackBar('Auth check başarısız', Colors.red);
    }
  }

  Future<void> _showTokenInfo() async {
    AppLogger.info('🧪 TOKEN INFO: Checking token status');

    try {
      final hasTokens = await SimpleTokenStorage.hasValidTokens();
      final accessToken = await SimpleTokenStorage.getAccessToken();
      final refreshToken = await SimpleTokenStorage.getRefreshToken();
      final isExpired = await SimpleTokenStorage.isTokenExpired();
      final expirySeconds = await SimpleTokenStorage.getTokenExpirySeconds();

      AppLogger.info('🧪 Has valid tokens: $hasTokens');
      AppLogger.info('🧪 Has access token: ${accessToken != null}');
      AppLogger.info('🧪 Has refresh token: ${refreshToken != null}');
      AppLogger.info('🧪 Is expired: $isExpired');
      AppLogger.info('🧪 Expiry seconds: $expirySeconds');

      if (accessToken != null) {
        AppLogger.info('🧪 Access token length: ${accessToken.length}');
      }

      // Show detailed info in dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Token Durumu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Geçerli token: ${hasTokens ? "Evet" : "Hayır"}'),
                Text('Access token: ${accessToken != null ? "Mevcut" : "Yok"}'),
                Text(
                  'Refresh token: ${refreshToken != null ? "Mevcut" : "Yok"}',
                ),
                Text('Süresi doldu: ${isExpired ? "Evet" : "Hayır"}'),
                Text(
                  'Kalan süre: ${expirySeconds != null ? "${expirySeconds}s" : "Bilinmiyor"}',
                ),
                if (accessToken != null)
                  Text('Token uzunluğu: ${accessToken.length}'),
              ],
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

      _showSnackBar('Token bilgileri loglandı', Colors.green);
    } catch (e) {
      AppLogger.error('🧪 Token info check failed: $e');
      _showSnackBar('Token info alınamadı', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

void _navigateToMail() async {
    AppLogger.info('🌐 Navigating to Mail module');

    try {
      // Auth provider'dan kullanıcı bilgisini al
      final authState = ref.read(authNotifierProvider);

      if (!authState.isAuthenticated) {
        AppLogger.warning('❌ User not authenticated, redirecting to login');
        context.go('/login');
        return;
      }

      // Kullanıcının email adresini al
      final userEmail = authState.user?.email;

      if (userEmail == null || userEmail.isEmpty) {
        AppLogger.error('❌ User email not found in auth state');
        _showErrorMessage('Kullanıcı email bilgisi bulunamadı');
        return;
      }

      AppLogger.info('✅ Navigating to mail for user: $userEmail');

      // ✅ YENİ: Organization Navigation Helper kullan
      context.goToOrgMail(ref, userEmail, folder: 'inbox');
    } catch (e) {
      AppLogger.error('❌ Error navigating to mail: $e');
      _showErrorMessage('Mail modülüne geçiş sırasında hata oluştu');
    }
  }
  /// Show error message to user
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '© 2024 Platform - Token Refresh Debug Mode',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.black45),
        textAlign: TextAlign.center,
      ),
    );
  }
}
