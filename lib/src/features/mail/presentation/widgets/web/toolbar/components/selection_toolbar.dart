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
          onPressed: () => _handleDeleteSelected(ref, selectedMailIds),
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

  /// Handle delete selected mails
  Future<void> _handleDeleteSelected(WidgetRef ref, List<String> mailIds) async {
    if (isLoading || mailIds.isEmpty) return;

    AppLogger.info('🔧 SelectionToolbar: Deleting ${mailIds.length} mails');

    try {
      // Show confirmation dialog first
      final confirmed = await _showDeleteConfirmation(mailIds.length);
      if (!confirmed) {
        AppLogger.info('❌ Delete cancelled by user');
        return;
      }

      // For now, we'll just log this action
      // In next steps, we'll implement the actual delete functionality
      AppLogger.info('🗑️ TODO: Implement bulk delete for mail IDs: $mailIds');
      
      // Clear selections after successful delete
      ref.read(mailSelectionProvider.notifier).clearAllSelections();
      
      AppLogger.info('✅ Delete operation completed');
      
      // TODO: In next phase, implement actual delete logic:
      // await ref.read(mailProvider.notifier).bulkMoveToTrash(mailIds, userEmail);
      
    } catch (e) {
      AppLogger.error('❌ Delete failed: $e');
      
      // TODO: Show error snackbar
    }
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(int count) async {
    // For now, return true (auto-confirm)
    // In real implementation, show actual dialog
    AppLogger.info('❓ Delete confirmation for $count mails (auto-confirmed for now)');
    return true;
    
    // TODO: Implement actual confirmation dialog:
    /*
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$count Maili Sil'),
        content: Text('Seçili $count mail çöp kutusuna taşınacak. Devam etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sil'),
          ),
        ],
      ),
    ) ?? false;
    */
  }
}