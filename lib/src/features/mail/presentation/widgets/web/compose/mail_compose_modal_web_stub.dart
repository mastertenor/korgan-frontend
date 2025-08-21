// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_web_stub.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/mail_compose_modal_provider.dart';
import '../../../../../../utils/app_logger.dart';

/// Mobile stub implementation - shows a platform notice
class MailComposeModalWeb extends ConsumerStatefulWidget {
  /// Current user email
  final String userEmail;
  
  /// Current user name
  final String userName;

  const MailComposeModalWeb({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  ConsumerState<MailComposeModalWeb> createState() => _MailComposeModalWebState();
}

class _MailComposeModalWebState extends ConsumerState<MailComposeModalWeb> {
  @override
  void initState() {
    super.initState();
    AppLogger.info('📱 MailComposeModalWeb stub loaded for mobile platform');
  }

  @override
  Widget build(BuildContext context) {
    final modalState = ref.watch(mailComposeModalProvider);
    
    // Modal kapalıysa hiçbir şey gösterme
    if (!modalState.isVisible) {
      return const SizedBox.shrink();
    }

    // Mobile platformlarda basit bilgilendirme modalı
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    size: 32,
                    color: Colors.blue,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Mail Oluşturma',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Mail oluşturma özelliği şu anda sadece web sürümünde kullanılabilir. Gelişmiş editör ve dosya ekleme özellikleri için lütfen web sürümünü kullanın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Secondary button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(mailComposeModalProvider.notifier).closeModal();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tamam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Primary button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(mailComposeModalProvider.notifier).closeModal();
                          // TODO: Navigate to web version or show instructions
                          _showWebVersionInfo(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Web Sürümü',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show web version information
  void _showWebVersionInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Web tarayıcısından uygulamayı açarak mail oluşturabilirsiniz',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}