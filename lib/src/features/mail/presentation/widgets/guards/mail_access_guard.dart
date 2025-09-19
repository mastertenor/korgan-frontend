// lib/src/features/mail/presentation/widgets/guards/mail_access_guard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/app_logger.dart';
import '../../../presentation/providers/mail_context_provider.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';

/// Mail access guard widget
///
/// This widget acts as a gatekeeper for the mail module. It ensures that:
/// 1. User has selected an organization
/// 2. User has access to at least one mail context
/// 3. Automatically selects first available context if none selected
/// 4. Shows appropriate error messages when access is denied
///
/// If all conditions are met, it renders the child widget.
/// Otherwise, it shows loading states or access denied screens.
class MailAccessGuard extends ConsumerWidget {
  /// The child widget to render when access is granted
  final Widget child;

  /// Optional loading widget to show during initialization
  final Widget? loadingWidget;

  /// Optional custom no access widget
  final Widget? noAccessWidget;

  const MailAccessGuard({
    super.key,
    required this.child,
    this.loadingWidget,
    this.noAccessWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug('🛡️ MailAccessGuard: Building guard');

    // Watch organization state
    final selectedOrg = ref.watch(selectedOrganizationProvider);
    final isOrgLoading = ref.watch(isOrganizationLoadingProvider);
    final orgError = ref.watch(organizationErrorProvider);

    // Watch mail context state
    final availableContexts = ref.watch(availableMailContextsProvider);
    final selectedContext = ref.watch(selectedMailContextProvider);
    final hasMailContexts = ref.watch(hasMailContextsProvider);

    // Trigger auto-selection logic
    ref.watch(autoContextSelectorProvider);

    // Show loading if organization is still loading
    if (isOrgLoading || selectedOrg == null) {
      AppLogger.debug('🛡️ MailAccessGuard: Organization loading');
      return _buildLoadingState();
    }

    // Show error if organization loading failed
    if (orgError != null) {
      AppLogger.warning('🛡️ MailAccessGuard: Organization error - $orgError');
      return _buildOrganizationErrorState(orgError);
    }

    // Show no access screen if user has no mail contexts
    if (!hasMailContexts) {
      AppLogger.warning(
        '🛡️ MailAccessGuard: No mail contexts available for org: ${selectedOrg.name}',
      );
      return _buildNoAccessState();
    }

    // Show loading if context is being auto-selected
    if (selectedContext == null && availableContexts.isNotEmpty) {
      AppLogger.debug(
        '🛡️ MailAccessGuard: Context auto-selection in progress',
      );
      return _buildLoadingState();
    }

    // Show error if no context could be selected
    if (selectedContext == null) {
      AppLogger.error(
        '🛡️ MailAccessGuard: No context selected despite available contexts',
      );
      return _buildContextSelectionErrorState();
    }

    // All checks passed - render child
    AppLogger.info(
      '✅ MailAccessGuard: Access granted for ${selectedContext.emailAddress}',
    );

    return child;
  }

  /// Build loading state widget
  Widget _buildLoadingState() {
    if (loadingWidget != null) {
      return loadingWidget!;
    }

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Mail hesapları kontrol ediliyor...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Build no access state widget (main error case)
  Widget _buildNoAccessState() {
    if (noAccessWidget != null) {
      return noAccessWidget!;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mail'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mail icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    size: 40,
                    color: Colors.orange[400],
                  ),
                ),

                const SizedBox(height: 24),

                // Main message
                const Text(
                  'Hesabınız ile ilişkilendirilmiş bir e-posta hesabı yok',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Mail modülünü kullanabilmek için sistem yöneticisi ile iletişime geçin.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Help button
                OutlinedButton.icon(
                  onPressed: () {
                    _showHelpDialog(context);
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Yardım'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build organization error state
  Widget _buildOrganizationErrorState(String error) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mail'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              const Text(
                'Organizasyon bilgileri yüklenemedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build context selection error state
  Widget _buildContextSelectionErrorState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mail'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Mail hesabı seçilemedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Mevcut mail hesapları arasından otomatik seçim yapılamadı.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show help dialog with contact information
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mail erişimi için:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('• Sistem yöneticiniz ile iletişime geçin'),
            Text('• E-posta hesabınızın sisteme tanımlanmasını isteyin'),
            Text('• Gerekli yetkilerin verilmesini talep edin'),
            SizedBox(height: 16),
            Text(
              'Bu işlem genellikle birkaç dakika sürmektedir.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
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
}
