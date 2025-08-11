// lib/src/features/mail/presentation/providers/mixins/mail_actions_mixin.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/app_logger.dart';
import '../../../domain/entities/bulk_read_result.dart';
import '../../../domain/entities/bulk_delete_result.dart';
import '../../../domain/entities/mail.dart';
import '../../../domain/usecases/mail_actions_usecase.dart';
import '../state/mail_state.dart';

/// Mixin for mail action operations in mail provider
/// 
/// This mixin provides mail action functionality including:
/// - Single mail actions (read/unread, star/unstar, trash, archive)
/// - Bulk operations (bulk read, bulk delete)
/// - Optimistic UI updates
/// - Context-aware updates across all folders
mixin MailActionsMixin on StateNotifier<MailState> {
  
  /// Mail actions use case - must be implemented by the class using this mixin
  MailActionsUseCase get mailActionsUseCase;

  // ========== SINGLE MAIL ACTIONS ==========

  /// Mark mail as read (context-aware)
  /// 
  /// Updates the mail state across all contexts where it exists.
  /// Uses optimistic UI updates for immediate feedback.
  Future<void> markAsRead(String mailId, String email) async {
    AppLogger.info('📖 Marking mail as read: $mailId');
    
    final params = MailActionParams(id: mailId, email: email);
    final result = await mailActionsUseCase.markAsRead(params);

    result.when(
      success: (_) {
        updateMailInAllContexts(
          mailId,
          (mail) => mail.copyWith(isRead: true),
        );
        AppLogger.info('✅ Mail marked as read successfully: $mailId');
      },
      failure: (failure) {
        setCurrentError(failure.message);
        AppLogger.error('❌ Failed to mark mail as read: $mailId - ${failure.message}');
      },
    );
  }

  /// Mark mail as unread (context-aware)
  /// 
  /// Updates the mail state across all contexts where it exists.
  /// Uses optimistic UI updates for immediate feedback.
  Future<void> markAsUnread(String mailId, String email) async {
    AppLogger.info('📖 Marking mail as unread: $mailId');
    
    final params = MailActionParams(id: mailId, email: email);
    final result = await mailActionsUseCase.markAsUnread(params);

    result.when(
      success: (_) {
        updateMailInAllContexts(
          mailId,
          (mail) => mail.copyWith(isRead: false),
        );
        AppLogger.info('✅ Mail marked as unread successfully: $mailId');
      },
      failure: (failure) {
        setCurrentError(failure.message);
        AppLogger.error('❌ Failed to mark mail as unread: $mailId - ${failure.message}');
      },
    );
  }

  /// Star mail (context-aware)
  /// 
  /// Updates the mail state across all contexts where it exists.
  /// Throws exception on failure for UI error handling.
  Future<void> starMail(String mailId, String email) async {
    AppLogger.info('⭐ Starring mail: $mailId');
    
    final params = MailActionParams(id: mailId, email: email);
    final result = await mailActionsUseCase.starMail(params);

    result.when(
      success: (_) {
        updateMailInAllContexts(
          mailId,
          (mail) => mail.copyWith(isStarred: true),
        );
        AppLogger.info('✅ Mail starred successfully: $mailId');
      },
      failure: (failure) {
        setCurrentError(failure.message);
        AppLogger.error('❌ Failed to star mail: $mailId - ${failure.message}');
        throw Exception(failure.message);
      },
    );
  }

  /// Unstar mail (context-aware)
  /// 
  /// Updates the mail state across all contexts where it exists.
  /// Uses optimistic UI updates for immediate feedback.
  Future<void> unstarMail(String mailId, String email) async {
    AppLogger.info('⭐ Unstarring mail: $mailId');
    
    final params = MailActionParams(id: mailId, email: email);
    final result = await mailActionsUseCase.unstarMail(params);

    result.when(
      success: (_) {
        updateMailInAllContexts(
          mailId,
          (mail) => mail.copyWith(isStarred: false),
        );
        AppLogger.info('✅ Mail unstarred successfully: $mailId');
      },
      failure: (failure) {
        setCurrentError(failure.message);
        AppLogger.error('❌ Failed to unstar mail: $mailId - ${failure.message}');
      },
    );
  }

  /// API-only move to trash (context-aware)
  /// 
  /// Performs only the API call without UI updates.
  /// Used in combination with optimistic UI updates.
  Future<void> moveToTrashApiOnly(String mailId, String email) async {
    AppLogger.info('🗑️ Moving mail to trash (API only): $mailId');
    
    final params = MailActionParams(id: mailId, email: email);
    final result = await mailActionsUseCase.moveToTrash(params);

    result.when(
      success: (_) {
        // ✅ API successful - clear any error
        setCurrentError(null);
        AppLogger.info('✅ Mail moved to trash successfully: $mailId');
      },
      failure: (failure) {
        // ❌ API failed - set error and throw for UNDO
        setCurrentError(failure.message);
        AppLogger.error('❌ Failed to move mail to trash: $mailId - ${failure.message}');
        throw Exception(failure.message);
      },
    );
  }

  /// API-only archive mail (context-aware)
  /// 
  /// Performs only the API call without UI updates.
  /// Used in combination with optimistic UI updates.
  Future<void> archiveMailApiOnly(String mailId, String email) async {
    AppLogger.info('📦 Archiving mail (API only): $mailId');
    
    final params = MailActionParams(id: mailId, email: email);
    final result = await mailActionsUseCase.archiveMail(params);

    result.when(
      success: (_) {
        // ✅ API successful - clear any error
        setCurrentError(null);
        AppLogger.info('✅ Mail archived successfully: $mailId');
      },
      failure: (failure) {
        // ❌ API failed - set error and throw for UNDO
        setCurrentError(failure.message);
        AppLogger.error('❌ Failed to archive mail: $mailId - ${failure.message}');
        throw Exception(failure.message);
      },
    );
  }

  // ========== BULK OPERATIONS ==========

  /// Bulk move to trash - multiple mails at once
  /// 
  /// Uses optimistic UI updates followed by sequential API calls.
  /// Returns detailed result information for error handling.
  Future<BulkDeleteResult> bulkMoveToTrash(
    List<String> mailIds, 
    String userEmail
  ) async {
    final errors = <String>[];
    final successful = <String>[];

    AppLogger.info('🗑️ Starting bulk delete for ${mailIds.length} mails');

    // 1. Optimistic UI update - remove all mails immediately from UI
    for (final mailId in mailIds) {
      optimisticRemoveFromCurrentContext(mailId);
    }

    AppLogger.info('✅ Optimistic UI update completed');

    // 2. Sequential API calls using existing moveToTrashApiOnly method
    for (final mailId in mailIds) {
      try {
        await moveToTrashApiOnly(mailId, userEmail);
        successful.add(mailId);
        AppLogger.info('✅ Mail deleted successfully: $mailId');
      } catch (error) {
        errors.add(mailId);
        AppLogger.error('❌ Mail delete failed: $mailId - $error');
      }
    }

    // 3. Create and return result summary
    final result = BulkDeleteResult(
      totalCount: mailIds.length,
      successCount: successful.length,
      failedCount: errors.length,
      failedMailIds: errors,
    );

    AppLogger.info('🗑️ Bulk delete completed: ${result.toString()}');
    return result;
  }

  /// Bulk mark as read - multiple mails at once
  /// 
  /// Uses optimistic UI updates followed by sequential API calls.
  /// Returns detailed result information for error handling.
  Future<BulkReadResult> bulkMarkAsRead(
    List<String> mailIds, 
    String userEmail
  ) async {
    final errors = <String>[];
    final successful = <String>[];

    AppLogger.info('📖 Starting bulk mark as read for ${mailIds.length} mails');

    // 1. Optimistic UI update - mark all as read immediately
    for (final mailId in mailIds) {
      updateMailInAllContexts(
        mailId,
        (mail) => mail.copyWith(isRead: true),
      );
    }

    AppLogger.info('✅ Optimistic UI update completed (mark as read)');

    // 2. Sequential API calls using existing markAsRead logic
    for (final mailId in mailIds) {
      try {
        final params = MailActionParams(id: mailId, email: userEmail);
        final result = await mailActionsUseCase.markAsRead(params);
        
        result.when(
          success: (_) {
            successful.add(mailId);
            AppLogger.info('✅ Mail marked as read successfully: $mailId');
          },
          failure: (failure) {
            errors.add(mailId);
            AppLogger.error('❌ Mail mark as read failed: $mailId - ${failure.message}');
          },
        );
      } catch (error) {
        errors.add(mailId);
        AppLogger.error('❌ Mail mark as read failed: $mailId - $error');
      }
    }

    // 3. Create and return result summary
    final result = BulkReadResult(
      totalCount: mailIds.length,
      successCount: successful.length,
      failedCount: errors.length,
      failedMailIds: errors,
    );

    AppLogger.info('📖 Bulk mark as read completed: ${result.toString()}');
    return result;
  }

  /// Bulk mark as unread - multiple mails at once
  /// 
  /// Uses optimistic UI updates followed by sequential API calls.
  /// Returns detailed result information for error handling.
  Future<BulkReadResult> bulkMarkAsUnread(
    List<String> mailIds, 
    String userEmail
  ) async {
    final errors = <String>[];
    final successful = <String>[];

    AppLogger.info('📖 Starting bulk mark as unread for ${mailIds.length} mails');

    // 1. Optimistic UI update - mark all as unread immediately
    for (final mailId in mailIds) {
      updateMailInAllContexts(
        mailId,
        (mail) => mail.copyWith(isRead: false),
      );
    }

    AppLogger.info('✅ Optimistic UI update completed (mark as unread)');

    // 2. Sequential API calls using existing markAsUnread logic
    for (final mailId in mailIds) {
      try {
        final params = MailActionParams(id: mailId, email: userEmail);
        final result = await mailActionsUseCase.markAsUnread(params);
        
        result.when(
          success: (_) {
            successful.add(mailId);
            AppLogger.info('✅ Mail marked as unread successfully: $mailId');
          },
          failure: (failure) {
            errors.add(mailId);
            AppLogger.error('❌ Mail mark as unread failed: $mailId - ${failure.message}');
          },
        );
      } catch (error) {
        errors.add(mailId);
        AppLogger.error('❌ Mail mark as unread failed: $mailId - $error');
      }
    }

    // 3. Create and return result summary
    final result = BulkReadResult(
      totalCount: mailIds.length,
      successCount: successful.length,
      failedCount: errors.length,
      failedMailIds: errors,
    );

    AppLogger.info('📖 Bulk mark as unread completed: ${result.toString()}');
    return result;
  }

  // ========== OPTIMISTIC UI OPERATIONS ==========

  /// Optimistic remove from current context
  /// 
  /// Immediately removes mail from UI for better user experience.
  /// Used before API calls in delete operations.
  void optimisticRemoveFromCurrentContext(String mailId) {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedMails = currentContext.mails
          .where((mail) => mail.id != mailId)
          .toList();

      final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

      final updatedContext = currentContext.copyWith(
        mails: updatedMails,
        unreadCount: unreadCount,
      );

      state = state.updateContext(state.currentFolder, updatedContext);
      AppLogger.info('🔄 Optimistically removed mail from UI: $mailId');
    }
  }

  /// Restore mail to current context (for UNDO)
  /// 
  /// Restores a previously removed mail back to the UI.
  /// Used for UNDO operations when API calls fail.
  void restoreMailToCurrentContext(Mail mail) {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedMails = [...currentContext.mails, mail];

      // Sort by time to maintain order
      updatedMails.sort((a, b) => b.time.compareTo(a.time));

      final unreadCount = updatedMails.where((m) => !m.isRead).length;

      final updatedContext = currentContext.copyWith(
        mails: updatedMails,
        unreadCount: unreadCount,
        error: null, // Clear any error
      );

      state = state.updateContext(state.currentFolder, updatedContext);
      AppLogger.info('🔄 Restored mail to UI: ${mail.id}');
    }
  }

  /// Update mail in all contexts where it exists
  /// 
  /// Updates a specific mail across all folder contexts.
  /// Used for actions that affect mail properties (read, starred, etc.).
  void updateMailInAllContexts(String mailId, Mail Function(Mail) updater) {
    final updatedContexts = <MailFolder, MailContext>{};

    for (final entry in state.contexts.entries) {
      final folder = entry.key;
      final context = entry.value;

      final updatedMails = context.mails.map((mail) {
        return mail.id == mailId ? updater(mail) : mail;
      }).toList();

      if (updatedMails != context.mails) {
        final unreadCount = updatedMails.where((mail) => !mail.isRead).length;
        updatedContexts[folder] = context.copyWith(
          mails: updatedMails,
          unreadCount: unreadCount,
        );
      }
    }

    // Update all affected contexts
    for (final entry in updatedContexts.entries) {
      state = state.updateContext(entry.key, entry.value);
    }

    AppLogger.info('🔄 Updated mail in ${updatedContexts.length} contexts: $mailId');
  }

  // ========== ERROR MANAGEMENT ==========

  /// Set error in current context - must be implemented by the class using this mixin
  void setCurrentError(String? message);

  // ========== ACTION UTILITIES ==========

  /// Check if mail exists in current context
  bool isMailInCurrentContext(String mailId) {
    final currentContext = state.currentContext;
    if (currentContext == null) return false;
    
    return currentContext.mails.any((mail) => mail.id == mailId);
  }

  /// Get mail from current context
  Mail? getMailFromCurrentContext(String mailId) {
    final currentContext = state.currentContext;
    if (currentContext == null) return null;
    
    try {
      return currentContext.mails.firstWhere((mail) => mail.id == mailId);
    } catch (e) {
      return null;
    }
  }

  /// Count mails by status in current context
  MailStatusCount getMailStatusCount() {
    final currentContext = state.currentContext;
    if (currentContext == null) {
      return const MailStatusCount(
        total: 0,
        read: 0,
        unread: 0,
        starred: 0,
        unstarred: 0,
      );
    }

    final mails = currentContext.mails;
    final readCount = mails.where((mail) => mail.isRead).length;
    final starredCount = mails.where((mail) => mail.isStarred).length;

    return MailStatusCount(
      total: mails.length,
      read: readCount,
      unread: mails.length - readCount,
      starred: starredCount,
      unstarred: mails.length - starredCount,
    );
  }

  /// Get action statistics
  ActionStatistics getActionStatistics() {
    final contexts = state.contexts;
    int totalMails = 0;
    int totalRead = 0;
    int totalStarred = 0;

    for (final context in contexts.values) {
      totalMails += context.mails.length;
      totalRead += context.mails.where((mail) => mail.isRead).length;
      totalStarred += context.mails.where((mail) => mail.isStarred).length;
    }

    return ActionStatistics(
      totalMails: totalMails,
      totalRead: totalRead,
      totalUnread: totalMails - totalRead,
      totalStarred: totalStarred,
      totalUnstarred: totalMails - totalStarred,
      readPercentage: totalMails > 0 ? totalRead / totalMails : 0.0,
      starredPercentage: totalMails > 0 ? totalStarred / totalMails : 0.0,
    );
  }
}

// ========== DATA CLASSES ==========

/// Mail status count for current context
class MailStatusCount {
  final int total;
  final int read;
  final int unread;
  final int starred;
  final int unstarred;

  const MailStatusCount({
    required this.total,
    required this.read,
    required this.unread,
    required this.starred,
    required this.unstarred,
  });

  double get readPercentage => total > 0 ? read / total : 0.0;
  double get starredPercentage => total > 0 ? starred / total : 0.0;

  @override
  String toString() {
    return 'MailStatusCount(total: $total, read: $read, unread: $unread, starred: $starred)';
  }
}

/// Overall action statistics across all contexts
class ActionStatistics {
  final int totalMails;
  final int totalRead;
  final int totalUnread;
  final int totalStarred;
  final int totalUnstarred;
  final double readPercentage;
  final double starredPercentage;

  const ActionStatistics({
    required this.totalMails,
    required this.totalRead,
    required this.totalUnread,
    required this.totalStarred,
    required this.totalUnstarred,
    required this.readPercentage,
    required this.starredPercentage,
  });

  @override
  String toString() {
    return 'ActionStatistics(total: $totalMails, read: $totalRead/$totalUnread, starred: $totalStarred/$totalUnstarred)';
  }
}