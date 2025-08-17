// lib/src/features/mail/presentation/widgets/web/compose/mail_page_with_compose_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_recipient.dart';
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/mail_providers.dart';
import 'mail_compose_modal_web.dart';

/// Mail page wrapper that adds compose modal overlay
/// 
/// Bu wrapper herhangi bir mail sayfasını (mail_page_web, mail_page_detail_web)
/// compose modal ile wrapper'lar.
/// 
/// Usage:
/// ```dart
/// MailPageWithComposeWrapper(
///   userEmail: userEmail,
///   userName: userName,
///   child: MailPageWeb(userEmail: userEmail),
/// )
/// ```
class MailPageWithComposeWrapper extends ConsumerWidget {
  /// Wrapped child page
  final Widget child;
  
  /// Current user email
  final String userEmail;
  
  /// Current user name
  final String userName;

  const MailPageWithComposeWrapper({
    super.key,
    required this.child,
    required this.userEmail,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Main page content
        child,
        
        // Compose modal overlay (only when visible)
        MailComposeModalWeb(
          userEmail: userEmail,
          userName: userName,
        ),
      ],
    );
  }
}

/// Extension for easy wrapping of mail pages
extension MailPageComposerExtension on Widget {
  /// Wrap this widget with compose modal functionality
  Widget withComposeModal({
    required String userEmail,
    required String userName,
  }) {
    return MailPageWithComposeWrapper(
      userEmail: userEmail,
      userName: userName,
      child: this,
    );
  }
}

/// Standalone compose modal trigger button for testing
class ComposeModalTriggerButton extends ConsumerWidget {
  final String userEmail;
  final String userName;
  final String? buttonText;
  final IconData? icon;
  final Color? color;

  const ComposeModalTriggerButton({
    super.key,
    required this.userEmail,
    required this.userName,
    this.buttonText,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _openModal(context, ref),
      icon: Icon(icon ?? Icons.edit),
      label: Text(buttonText ?? 'Oluştur'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openModal(BuildContext context, WidgetRef ref) {
    // Initialize compose provider
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    composeNotifier.clearAll();
    
    final sender = MailRecipient(
      email: userEmail,
      name: userName,
    );
    composeNotifier.initializeWithSender(sender);
    
    // Open modal
    ref.read(mailComposeModalProvider.notifier).openModal();
  }
}

/// Debug info widget to show modal state
class ComposeModalDebugInfo extends ConsumerWidget {
  const ComposeModalDebugInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(mailComposeModalProvider);
    final composeState = ref.watch(mailComposeProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Compose Modal State:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Open: ${modalState.isOpen} | '
            'Minimized: ${modalState.isMinimized} | '
            'Maximized: ${modalState.isMaximized}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From: ${composeState.from?.email ?? "null"} | '
            'To: ${composeState.to.length} | '
            'Valid: ${composeState.isValid}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick access methods for common compose operations
class ComposeModalQuickActions {
  /// Show compose modal with quick button for demo/test
  static Widget buildQuickButton(
    BuildContext context,
    WidgetRef ref, {
    required String userEmail,
    required String userName,
  }) {
    return ComposeModalTriggerButton(
      userEmail: userEmail,
      userName: userName,
    );
  }

  /// Show compose modal state for debugging
  static Widget buildDebugInfo() {
    return const ComposeModalDebugInfo();
  }

  /// Create a full test environment
  static Widget buildTestEnvironment({
    required String userEmail,
    required String userName,
    Widget? child,
  }) {
    return Column(
      children: [
        ComposeModalTriggerButton(
          userEmail: userEmail,
          userName: userName,
        ),
        const ComposeModalDebugInfo(),
        if (child != null) Expanded(child: child),
      ],
    );
  }
}