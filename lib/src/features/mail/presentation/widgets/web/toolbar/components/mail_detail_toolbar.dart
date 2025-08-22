// lib/src/features/mail/presentation/widgets/web/toolbar/components/mail_detail_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/mail_compose_modal_provider.dart'; // NEW IMPORT
import '../../../../../domain/entities/mail_detail.dart';
import '../../../../../domain/entities/mail_recipient.dart'; // NEW IMPORT  
import '../../../../../domain/enums/reply_type.dart'; // NEW IMPORT
import '../toolbar_buttons/back_button.dart' as custom_back;
import '../toolbar_buttons/more_actions_menu.dart';
import '../toolbar_buttons/reply_button.dart';
import '../toolbar_buttons/reply_all_button.dart';
import '../toolbar_buttons/forward_button.dart';
import '../toolbar_buttons/star_button.dart';
import '../toolbar_buttons/mark_as_unread_button.dart';
import '../toolbar_buttons/delete_button.dart';
import '../toolbar_buttons/previous_mail_button.dart';
import '../toolbar_buttons/next_mail_button.dart';

/// Toolbar for mail detail page actions
/// 
/// Contains action buttons similar to selection_toolbar design:
/// - Back navigation
/// - Reply, Reply All, Forward
/// - Mark as unread, Star, Delete
/// - More actions menu
/// - Previous/Next mail navigation
class MailDetailToolbar extends ConsumerWidget {
  final MailDetail mailDetail;
  final String userEmail;
  final VoidCallback onBack;
  final bool isLoading;
  final VoidCallback? onPreviousMail;
  final VoidCallback? onNextMail;
  final bool hasPreviousMail;
  final bool hasNextMail;

  const MailDetailToolbar({
    super.key,
    required this.mailDetail,
    required this.userEmail,
    required this.onBack,
    required this.isLoading,
    this.onPreviousMail,
    this.onNextMail,
    this.hasPreviousMail = false,
    this.hasNextMail = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          custom_back.BackButton(
            isLoading: isLoading,
            onPressed: onBack,
          ),

          const SizedBox(width: 8),

          // Reply Button - UPDATED
          ReplyButton(
            isLoading: isLoading,
            onPressed: () => _handleReply(context, ref),
          ),

          const SizedBox(width: 8),

          // Reply All Button - UPDATED
          ReplyAllButton(
            isLoading: isLoading,
            onPressed: () => _handleReplyAll(context, ref),
          ),

          const SizedBox(width: 8),

          // Forward Button
          ForwardButton(
            isLoading: isLoading,
            onPressed: () => _handleForward(context),
          ),

          const SizedBox(width: 8),

          // Mark as Unread Button
          MarkAsUnreadButton(
            selectedMailIds: [mailDetail.id],
            isLoading: isLoading,
            onPressed: () => _handleMarkAsUnread(ref),
          ),

          const SizedBox(width: 8),
          // Star Button
          StarButton(
            isStarred: mailDetail.isStarred,
            isLoading: isLoading,
            onPressed: () => _handleToggleStar(ref),
          ),

          const SizedBox(width: 8),

          // Delete Button
          DeleteButton(
            userEmail: userEmail,
            selectedMailIds: [mailDetail.id],
            isLoading: isLoading,
            onPressed: () => _handleDelete(context, ref),
          ),

          const SizedBox(width: 8),

          // More Actions Menu
          MoreActionsMenu(
            isLoading: isLoading,
            onActionSelected: (action) => _handleMenuAction(context, action),
          ),

          const Spacer(),

          // Previous Mail Button
          PreviousMailButton(
            isLoading: isLoading,
            hasPreviousMail: hasPreviousMail,
            onPressed: onPreviousMail,
          ),

          const SizedBox(width: 4),

          // Next Mail Button
          NextMailButton(
            isLoading: isLoading,
            hasNextMail: hasNextMail,
            onPressed: onNextMail,
          ),

          const SizedBox(width: 8),

        ],
      ),
    );
  }

  // ========== ACTION HANDLERS ==========

  /// Handle reply action - UPDATED
  void _handleReply(BuildContext context, WidgetRef ref) {
    AppLogger.info('📧 Reply action for mail: ${mailDetail.id}');
    
    try {
      // Create current user recipient
      final currentUser = MailRecipient(
        email: userEmail,
        name: _extractUserNameFromEmail(userEmail),
      );
      
      // Initialize reply state
      ref.read(mailReplyProvider.notifier).initializeForReply(
        from: currentUser,
        originalMail: mailDetail,
        replyType: ReplyType.reply,
      );
      
      // Open compose modal
      ref.read(mailComposeModalProvider.notifier).openModal();
      
    } catch (e) {
      AppLogger.error('❌ Error in reply action: $e');
      _showErrorSnackBar(context, 'Yanıtlama sırasında hata oluştu');
    }
  }

  /// Handle reply all action - UPDATED
  void _handleReplyAll(BuildContext context, WidgetRef ref) {
    AppLogger.info('📧 Reply all action for mail: ${mailDetail.id}');
    
    try {
      // Create current user recipient
      final currentUser = MailRecipient(
        email: userEmail,
        name: _extractUserNameFromEmail(userEmail),
      );
      
      // Initialize reply all state
      ref.read(mailReplyProvider.notifier).initializeForReply(
        from: currentUser,
        originalMail: mailDetail,
        replyType: ReplyType.replyAll,
      );
      
      // Open compose modal
      ref.read(mailComposeModalProvider.notifier).openModal();
      
    } catch (e) {
      AppLogger.error('❌ Error in reply all action: $e');
      _showErrorSnackBar(context, 'Tümünü yanıtlama sırasında hata oluştu');
    }
  }

  /// Handle mark as unread action
  void _handleMarkAsUnread(WidgetRef ref) {
    AppLogger.info('📖 Mark as unread action for mail: ${mailDetail.id}');
    ref.read(mailProvider.notifier).markAsUnread(mailDetail.id, userEmail);
    _showSuccessSnackBar(ref.context, 'Okunmadı olarak işaretlendi');
  }

  /// Handle forward action
  void _handleForward(BuildContext context) {
    AppLogger.info('📤 Forward action for mail: ${mailDetail.id}');
    _showInfoSnackBar(context, 'Yönlendirme özelliği yakında eklenecek');
  }

  /// Handle toggle star action
  void _handleToggleStar(WidgetRef ref) {
    AppLogger.info('⭐ Toggle star action for mail: ${mailDetail.id}');
    
    if (mailDetail.isStarred) {
      ref.read(mailProvider.notifier).unstarMail(mailDetail.id, userEmail);
      _showSuccessSnackBar(ref.context, 'Yıldız kaldırıldı');
    } else {
      ref.read(mailProvider.notifier).starMail(mailDetail.id, userEmail);
      _showSuccessSnackBar(ref.context, 'Yıldızlandı');
    }
  }

  /// Handle delete action
  void _handleDelete(BuildContext context, WidgetRef ref) {
    AppLogger.info('🗑️ Delete action for mail: ${mailDetail.id}');
    
    // Perform delete action immediately (no confirmation dialog)
    _performDelete(context, ref);
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action) {
    AppLogger.info('📋 Menu action: $action for mail: ${mailDetail.id}');
    
    switch (action) {
      case 'test1':
        _showInfoSnackBar(context, 'Test1 seçildi');
        break;
      case 'test2':
        _showInfoSnackBar(context, 'Test2 seçildi');
        break;
    }
  }

  // ========== CONFIRMATION DIALOGS ==========

  /// Perform delete action directly (no confirmation dialog needed)
  Future<void> _performDelete(BuildContext context, WidgetRef ref) async {
    try {
      final mailName = mailDetail.senderName;
      
      // 1. Optimistic remove (same as selection_toolbar pattern)
      ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mailDetail.id);
      
      // 2. Show success feedback immediately (with mounted check)
      if (context.mounted) {
        _showSuccessSnackBar(context, '$mailName çöp kutusuna taşındı');
      }
      
      // 3. Navigate back immediately (optimistic) - call the callback
      onBack();
      
      // 4. Background API call
      await ref.read(mailProvider.notifier).moveToTrashApiOnly(mailDetail.id, userEmail);
      
      AppLogger.info('✅ Mail deleted successfully: ${mailDetail.id}');
      
    } catch (error) {
      AppLogger.error('❌ Mail delete failed: $error');
      // 5. Error handling with mounted check
      if (context.mounted) {
        _showErrorSnackBar(context, 'Çöp kutusuna taşıma başarısız');
      }
    }
  }

  // ========== HELPER METHODS ==========

  /// Extract user name from email (simple fallback) - NEW
  String _extractUserNameFromEmail(String email) {
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return email;
  }

  // ========== SNACKBAR HELPERS ==========

  /// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show info snackbar
  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}