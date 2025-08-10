// lib/src/features/mail/presentation/widgets/web/toolbar/components/selection_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../providers/mail_providers.dart';
import '../toolbar_buttons/delete_button.dart';

/// Toolbar displayed when mails are selected
/// 
/// Contains:
/// - Clear selection button (X icon)
/// - Delete button (delete selected mails)
/// - Selection info (e.g., "3 mail seçildi")
class SelectionToolbar extends ConsumerWidget {
  final String userEmail;
  final int selectedCount;
  final bool isLoading;

  const SelectionToolbar({
    super.key,
    required this.userEmail,
    required this.selectedCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selected mail IDs for delete operation
    final selectedMailIds = ref.watch(selectedMailIdsProvider);

    AppLogger.info('🔧 SelectionToolbar: selectedCount=$selectedCount, '
                  'selectedIds=${selectedMailIds.length}');

    return Row(
      children: [
        // Checked Checkbox (Clear Selection)
        Tooltip(
          message: 'Seçimi temizle ($selectedCount seçili)',
          child: Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: true, // Always checked when selection exists
              onChanged: isLoading ? null : (value) => _handleClearSelection(ref),
              activeColor: Colors.blue.shade600,
              checkColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Delete Button
        DeleteButton(
          userEmail: userEmail,
          selectedMailIds: selectedMailIds,
          isLoading: isLoading,
          onPressed: () => _handleDeleteSelected(context, ref, selectedMailIds),
        ),

        const Spacer(),

        // Future: More action buttons can be added here
        // ArchiveButton(), StarButton(), LabelButton(), etc.
      ],
    );
  }

  /// Handle clear selection
  void _handleClearSelection(WidgetRef ref) {
    if (isLoading) return;

    AppLogger.info('🔧 SelectionToolbar: Clearing selection');

    ref.read(mailSelectionProvider.notifier).clearAllSelections();
    
    AppLogger.info('✅ Selection cleared');
  }

  /// Handle delete selected mails - CONDITIONAL LOGIC
  Future<void> _handleDeleteSelected(BuildContext context, WidgetRef ref, List<String> mailIds) async {
    if (isLoading || mailIds.isEmpty) return;

    AppLogger.info('🔧 SelectionToolbar: Deleting ${mailIds.length} mails');

    try {
      if (mailIds.length == 1) {
        // SINGLE MAIL - Use existing mobile pattern (no confirmation)
        await _handleSingleMailDelete(context, ref, mailIds.first);
      } else {
        // BULK MAILS - Show confirmation and use bulk function
        final confirmed = await _showDeleteConfirmation(context, mailIds.length);
        if (!confirmed) {
          AppLogger.info('❌ Bulk delete cancelled by user');
          return;
        }

        // SHOW IMMEDIATE FEEDBACK BEFORE ASYNC OPERATION
        _showSuccessSnackBar(context, '${mailIds.length} mail çöp kutusuna taşınıyor...');
        
        await _handleBulkMailDelete(context, ref, mailIds);
      }

      // Clear selections after successful delete - SAFE CHECK
      if (context.mounted) {
        ref.read(mailSelectionProvider.notifier).clearAllSelections();
        AppLogger.info('✅ Delete operation completed');
      }
      
    } catch (e) {
      AppLogger.error('❌ Delete failed: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Silme işlemi başarısız: ${e.toString()}');
      }
    }
  }

  /// Handle single mail delete (reuse mobile pattern)
  Future<void> _handleSingleMailDelete(BuildContext context, WidgetRef ref, String mailId) async {
    // Get mail info for feedback
    final currentMails = ref.read(currentMailsProvider);
    final mail = currentMails.where((m) => m.id == mailId).firstOrNull;
    final mailName = mail?.senderName ?? 'Mail';

    // 1. Optimistic remove (same as mobile)
    ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mailId);
    
    // Show success feedback immediately - SAFE CHECK
    if (context.mounted) {
      _showSuccessSnackBar(context, '$mailName çöp kutusuna taşındı');
    }

    // 2. Background API call (same as mobile)
    try {
      await ref.read(mailProvider.notifier).moveToTrashApiOnly(mailId, userEmail);
      AppLogger.info('✅ Single mail deleted successfully: $mailId');
    } catch (error) {
      AppLogger.error('❌ Single mail delete failed: $error');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Çöp kutusuna taşıma başarısız');
      }
    }
  }

  /// Handle bulk mail delete (new bulk function)
  Future<void> _handleBulkMailDelete(BuildContext context, WidgetRef ref, List<String> mailIds) async {
    AppLogger.info('🗑️ Starting bulk delete for ${mailIds.length} mails');

    final result = await ref.read(mailProvider.notifier)
        .bulkMoveToTrash(mailIds, userEmail);

    AppLogger.info('🔍 DEBUG: Bulk operation completed - ${result.toString()}');

    // NO SNACKBAR HERE - Already shown before async operation
    if (result.isCompletelySuccessful) {
      AppLogger.info('✅ Bulk delete completed successfully');
    } else if (result.isPartiallySuccessful) {
      AppLogger.warning('⚠️ Bulk delete partially successful');
    } else {
      AppLogger.error('❌ Bulk delete completely failed');
    }
  }

  /// Show delete confirmation dialog - ONLY FOR BULK (>1 mail)
  Future<bool> _showDeleteConfirmation(BuildContext context, int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$count Maili Sil'),
        content: Text('Seçili $count mail çöp kutusuna taşınacak. Devam etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    ) ?? false;
  }

  // ========== SNACKBAR FEEDBACK METHODS ==========

  /// Show success feedback (green) - SAFE VERSION
  void _showSuccessSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      AppLogger.info('✅ SnackBar shown: $message');
    } else {
      AppLogger.warning('⚠️ ScaffoldMessenger not available for: $message');
    }
  }

  /// Show error feedback (red) - SAFE VERSION
  void _showErrorSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      AppLogger.error('❌ SnackBar shown: $message');
    } else {
      AppLogger.warning('⚠️ ScaffoldMessenger not available for: $message');
    }
  }
}