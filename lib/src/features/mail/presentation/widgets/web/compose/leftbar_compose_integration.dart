// lib/src/features/mail/presentation/widgets/web/compose/leftbar_compose_integration.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../../domain/entities/mail_recipient.dart';
import '../../../providers/mail_providers.dart';

/// Gmail LeftBar Compose Integration Helper
/// 
/// Bu mixin MailLeftBarSection'da compose button'ına modal açma fonksiyonalitesi ekler.
/// Ayrıca diğer web sayfalarında da compose modal açmak için kullanılabilir.
mixin ComposeModalIntegration {
  
  /// Compose modal'ı aç ve provider'ı initialize et
  void openComposeModal(
    BuildContext context, 
    WidgetRef ref, {
    required String userEmail,
    required String userName,
    MailRecipient? replyTo,
    String? originalSubject,
    String? originalContent,
  }) {
    // 1. Compose provider'ı initialize et
    _initializeComposeProvider(
      ref,
      userEmail: userEmail,
      userName: userName,
      replyTo: replyTo,
      originalSubject: originalSubject,
      originalContent: originalContent,
    );
    
    // 2. Modal'ı aç
    ref.read(mailComposeModalProvider.notifier).openModal();
  }

  /// Quick new mail compose
  void openNewMailCompose(
    BuildContext context,
    WidgetRef ref, {
    required String userEmail,
    required String userName,
  }) {
    openComposeModal(
      context,
      ref,
      userEmail: userEmail,
      userName: userName,
    );
  }

  /// Reply compose
  void openReplyCompose(
    BuildContext context,
    WidgetRef ref, {
    required String userEmail,
    required String userName,
    required MailRecipient replyTo,
    required String originalSubject,
  }) {
    openComposeModal(
      context,
      ref,
      userEmail: userEmail,
      userName: userName,
      replyTo: replyTo,
      originalSubject: originalSubject,
    );
  }

  /// Forward compose
  void openForwardCompose(
    BuildContext context,
    WidgetRef ref, {
    required String userEmail,
    required String userName,
    required String originalSubject,
    required String originalContent,
  }) {
    openComposeModal(
      context,
      ref,
      userEmail: userEmail,
      userName: userName,
      originalSubject: originalSubject,
      originalContent: originalContent,
    );
  }

  /// Initialize compose provider based on type
  void _initializeComposeProvider(
    WidgetRef ref, {
    required String userEmail,
    required String userName,
    MailRecipient? replyTo,
    String? originalSubject,
    String? originalContent,
  }) {
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    
    // Clear previous state
    composeNotifier.clearAll();
    
    // Create sender
    final sender = MailRecipient(
      email: userEmail,
      name: userName,
    );
    
    // Initialize based on compose type
    if (replyTo != null && originalSubject != null) {
      // Reply mode
      composeNotifier.initializeForReply(
        from: sender,
        replyTo: replyTo,
        originalSubject: originalSubject,
      );
    } else if (originalSubject != null && originalContent != null) {
      // Forward mode
      composeNotifier.initializeForForward(
        from: sender,
        originalSubject: originalSubject,
        originalContent: originalContent,
      );
    } else {
      // New mail mode
      composeNotifier.initializeWithSender(sender);
    }
  }
}

/// Extension for easy access to compose modal methods
extension ComposeModalContextExtension on BuildContext {
  /// Open new mail compose modal
  void openNewMailModal(
    WidgetRef ref, {
    required String userEmail,
    required String userName,
  }) {
    final helper = _ComposeModalHelper();
    helper.openNewMailCompose(
      this,
      ref,
      userEmail: userEmail,
      userName: userName,
    );
  }

  /// Open reply compose modal
  void openReplyModal(
    WidgetRef ref, {
    required String userEmail,
    required String userName,
    required MailRecipient replyTo,
    required String originalSubject,
  }) {
    final helper = _ComposeModalHelper();
    helper.openReplyCompose(
      this,
      ref,
      userEmail: userEmail,
      userName: userName,
      replyTo: replyTo,
      originalSubject: originalSubject,
    );
  }

  /// Open forward compose modal
  void openForwardModal(
    WidgetRef ref, {
    required String userEmail,
    required String userName,
    required String originalSubject,
    required String originalContent,
  }) {
    final helper = _ComposeModalHelper();
    helper.openForwardCompose(
      this,
      ref,
      userEmail: userEmail,
      userName: userName,
      originalSubject: originalSubject,
      originalContent: originalContent,
    );
  }
}

/// Private helper class for extension methods
class _ComposeModalHelper with ComposeModalIntegration {}

/// Utility class for compose modal operations
class ComposeModalUtils {
  /// Check if compose modal is open
  static bool isComposeOpen(WidgetRef ref) {
    return ref.read(mailComposeModalProvider).isOpen;
  }

  /// Close compose modal
  static void closeCompose(WidgetRef ref) {
    ref.read(mailComposeModalProvider.notifier).closeModal();
  }

  /// Minimize compose modal
  static void minimizeCompose(WidgetRef ref) {
    ref.read(mailComposeModalProvider.notifier).minimizeModal();
  }

  /// Maximize compose modal
  static void maximizeCompose(WidgetRef ref) {
    ref.read(mailComposeModalProvider.notifier).maximizeModal();
  }

  /// Toggle minimize state
  static void toggleMinimize(WidgetRef ref) {
    ref.read(mailComposeModalProvider.notifier).toggleMinimize();
  }

  /// Toggle maximize state
  static void toggleMaximize(WidgetRef ref) {
    ref.read(mailComposeModalProvider.notifier).toggleMaximize();
  }

  /// Get current modal state
  static String getModalStateDescription(WidgetRef ref) {
    final state = ref.read(mailComposeModalProvider);
    
    if (!state.isOpen) return 'Closed';
    if (state.isMinimized) return 'Minimized';
    if (state.isMaximized) return 'Maximized';
    return 'Normal';
  }
}