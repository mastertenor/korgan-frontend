// lib/src/features/mail/presentation/widgets/web/toolbar/components/mail_detail_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/mail_compose_modal_provider.dart';
import '../../../../../domain/entities/mail_detail.dart';
import '../../../../../domain/entities/mail_recipient.dart';
import '../../../../../domain/enums/reply_type.dart';
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

/// Toolbar mode enum - defines which buttons to show
enum ToolbarMode {
  detail,   // Full mode - all buttons visible (for detail page)
  preview   // Preview mode - back/prev/next buttons hidden (for preview panel)
}

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
  final ToolbarMode mode;
  final Function(String)? onSelectMail;
  

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
    this.mode = ToolbarMode.detail,
    this.onSelectMail,
    
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactive state tracking for star button
    final mailState = ref.watch(mailProvider);
    final currentMail = mailState.currentMails.where((m) => m.id == mailDetail.id).firstOrNull;
    final isStarred = currentMail?.isStarred ?? mailDetail.isStarred;

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
          // Back Button - only show in detail mode
          if (mode == ToolbarMode.detail) ...[
            custom_back.BackButton(
              isLoading: isLoading,
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
          ],

          // Reply Button
          ReplyButton(
            isLoading: isLoading,
            onPressed: () => _handleReply(context, ref),
          ),

          const SizedBox(width: 8),

          // Reply All Button
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

          // Mark as Read/Unread Button - Reactive
          MarkAsUnreadButton(
            selectedMailIds: [mailDetail.id],
            isLoading: isLoading,
            onPressed: () => _handleToggleRead(ref),
          ),

          const SizedBox(width: 8),

          // Star Button - Reactive
          StarButton(
            isStarred: isStarred,
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

          // Previous/Next Mail Buttons - only show in detail mode
          if (mode == ToolbarMode.detail) ...[
            PreviousMailButton(
              isLoading: isLoading,
              hasPreviousMail: hasPreviousMail,
              onPressed: onPreviousMail,
            ),

            const SizedBox(width: 4),

            NextMailButton(
              isLoading: isLoading,
              hasNextMail: hasNextMail,
              onPressed: onNextMail,
            ),

            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // ========== ACTION HANDLERS ==========

  /// Handle reply action
  void _handleReply(BuildContext context, WidgetRef ref) {
    AppLogger.info('Reply action for mail: ${mailDetail.id}');
    
    try {
      final currentUser = MailRecipient(
        email: userEmail,
        name: _extractUserNameFromEmail(userEmail),
      );
      
      ref.read(mailReplyProvider.notifier).initializeForReply(
        from: currentUser,
        originalMail: mailDetail,
        replyType: ReplyType.reply,
      );
      
      ref.read(mailComposeModalProvider.notifier).openModal();
      
    } catch (e) {
      AppLogger.error('Error in reply action: $e');
      _showErrorSnackBar(context, 'Yanıtlama sırasında hata oluştu');
    }
  }

  /// Handle reply all action
  void _handleReplyAll(BuildContext context, WidgetRef ref) {
    AppLogger.info('Reply all action for mail: ${mailDetail.id}');
    
    try {
      final currentUser = MailRecipient(
        email: userEmail,
        name: _extractUserNameFromEmail(userEmail),
      );
      
      ref.read(mailReplyProvider.notifier).initializeForReply(
        from: currentUser,
        originalMail: mailDetail,
        replyType: ReplyType.replyAll,
      );
      
      ref.read(mailComposeModalProvider.notifier).openModal();
      
    } catch (e) {
      AppLogger.error('Error in reply all action: $e');
      _showErrorSnackBar(context, 'Tümünü yanıtlama sırasında hata oluştu');
    }
  }

  /// Handle toggle read/unread action - Reactive implementation
  void _handleToggleRead(WidgetRef ref) {
    final mailState = ref.read(mailProvider);
    final currentMail = mailState.currentMails.where((m) => m.id == mailDetail.id).firstOrNull;
    final isCurrentlyRead = currentMail?.isRead ?? mailDetail.isRead;
    
    if (isCurrentlyRead) {
      AppLogger.info('Mark as unread action for mail: ${mailDetail.id}');
      ref.read(mailProvider.notifier).markAsUnread(mailDetail.id, userEmail);
    } else {
      AppLogger.info('Mark as read action for mail: ${mailDetail.id}');
      ref.read(mailProvider.notifier).markAsRead(mailDetail.id, userEmail);
    }
  }

  /// Handle forward action
  void _handleForward(BuildContext context) {
    AppLogger.info('Forward action for mail: ${mailDetail.id}');
    _showInfoSnackBar(context, 'Yönlendirme özelliği yakında eklenecek');
  }

  /// Handle toggle star action - Reactive implementation
  void _handleToggleStar(WidgetRef ref) {
    AppLogger.info('Toggle star action for mail: ${mailDetail.id}');
    
    final mailState = ref.read(mailProvider);
    final currentMail = mailState.currentMails.where((m) => m.id == mailDetail.id).firstOrNull;
    final isCurrentlyStarred = currentMail?.isStarred ?? mailDetail.isStarred;
    
    if (isCurrentlyStarred) {
      ref.read(mailProvider.notifier).unstarMail(mailDetail.id, userEmail);
      _showSuccessSnackBar(ref.context, 'Yıldız kaldırıldı');
    } else {
      ref.read(mailProvider.notifier).starMail(mailDetail.id, userEmail);
      _showSuccessSnackBar(ref.context, 'Yıldızlandı');
    }
  }

  /// Handle delete action
  void _handleDelete(BuildContext context, WidgetRef ref) {
    AppLogger.info('Delete action for mail: ${mailDetail.id}');
    _performDelete(context, ref);
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action) {
    AppLogger.info('Menu action: $action for mail: ${mailDetail.id}');
    
    switch (action) {
      case 'test1':
        _showInfoSnackBar(context, 'Test1 seçildi');
        break;
      case 'test2':
        _showInfoSnackBar(context, 'Test2 seçildi');
        break;
    }
  }

  // ========== DELETE LOGIC ==========

  /// Perform delete action with proper navigation
Future<void> _performDelete(BuildContext context, WidgetRef ref) async {
  try {
    final mailName = mailDetail.senderName;
    final mailId = mailDetail.id;
    
    // 1. ÖNCE navigation target'ını belirle (listede hala varken)
    final nextMailId = _determineNextMailBeforeDelete(ref, mailId);
    AppLogger.info('🎯 Pre-delete navigation target: $nextMailId');
    
    // 2. Optimistic remove
    ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mailId);
    
    // 3. Navigation target'ına git (eğer varsa)
    if (nextMailId != null) {
      ref.read(mailSelectionControllerProvider)
         .select(nextMailId, userEmail: userEmail);
    } else {
      // Mail yoksa preview'ı temizle
      ref.read(selectedMailIdProvider.notifier).state = null;
      ref.read(mailDetailProvider.notifier).clearData();
    }
    
    // 4. Success message
    if (context.mounted) {
      _showSuccessSnackBar(context, '$mailName çöp kutusuna taşındı');
    }
    
    // 5. Background API call
    await ref.read(mailProvider.notifier).moveToTrashApiOnly(mailId, userEmail);
    
  } catch (error) {
    AppLogger.error('Mail delete failed: $error');
    if (context.mounted) {
      _showErrorSnackBar(context, 'Çöp kutusuna taşıma başarısız');
    }
  }
}

/// Determine next mail ID before delete (when mail is still in list)
String? _determineNextMailBeforeDelete(WidgetRef ref, String mailId) {
  final list = ref.read(currentMailsProvider);
  final idx = list.indexWhere((m) => m.id == mailId);
  
  AppLogger.info('🔍 Mail position before delete: $idx/${list.length}');
  
  if (idx != -1) {
    if (idx < list.length - 1) {
      final nextId = list[idx + 1].id;
      AppLogger.info('➡️ Will select next mail: $nextId');
      return nextId;
    } else if (idx > 0) {
      final prevId = list[idx - 1].id;
      AppLogger.info('⬅️ Will select previous mail: $prevId');
      return prevId;
    }
  }
  
  AppLogger.info('🚫 No navigation target found');
  return null;
}  
 
  // ========== HELPER METHODS ==========

  /// Extract user name from 
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