// lib/src/features/mail/presentation/widgets/mobile/compose/send_button_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_providers.dart';

/// Send button widget for compose form
class SendButtonWidget extends ConsumerWidget {
  const SendButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(canSendMailProvider);
    final isLoading = ref.watch(composeLoadingProvider);
    //final lastResult = ref.watch(composeLastResultProvider);
    
    return ElevatedButton.icon(
      onPressed: canSend ? () => _handleSend(context, ref) : null,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.send),
      label: Text(isLoading ? 'Gönderiliyor...' : 'Gönder'),
      style: ElevatedButton.styleFrom(
        backgroundColor: canSend ? Colors.blue : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Handle send button press
  Future<void> _handleSend(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(mailComposeProvider.notifier).sendMail();
    
    if (result && context.mounted) {
      // Success - show message and close
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mail başarıyla gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Close compose page
      Navigator.of(context).pop(true);
    } else if (context.mounted) {
      // Error - show error message (error is already in state)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Mail gönderilemedi. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}