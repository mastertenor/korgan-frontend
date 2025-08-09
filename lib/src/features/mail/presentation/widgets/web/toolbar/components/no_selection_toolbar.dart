// lib/src/features/mail/presentation/widgets/web/toolbar/components/no_selection_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/mail_provider.dart';
import '../toolbar_buttons/select_all_checkbox.dart';
import '../toolbar_buttons/refresh_button.dart';

/// Toolbar displayed when no mails are selected
/// 
/// Contains:
/// - Select All checkbox (to select all current mails)
/// - Refresh button (to refresh current folder)
class NoSelectionToolbar extends ConsumerWidget {
  final String userEmail;
  final int totalMailCount;
  final MailFolder currentFolder;
  final bool isLoading;

  const NoSelectionToolbar({
    super.key,
    required this.userEmail,
    required this.totalMailCount,
    required this.currentFolder,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selection state for checkbox
    final isAllSelected = ref.watch(isAllSelectedProvider);
    final isPartiallySelected = ref.watch(isPartiallySelectedProvider);

    AppLogger.info('🔧 NoSelectionToolbar: totalMails=$totalMailCount, '
                  'allSelected=$isAllSelected, partiallySelected=$isPartiallySelected');

    return Row(
      children: [
        // Select All Checkbox
        SelectAllCheckbox(
          isAllSelected: isAllSelected,
          isPartiallySelected: isPartiallySelected,
          totalMailCount: totalMailCount,
          isLoading: isLoading,
          onChanged: (value) => _handleSelectAllChanged(ref, value),
        ),


        // Refresh Button
        RefreshButton(
          userEmail: userEmail,
          currentFolder: currentFolder,
          isLoading: isLoading,
          onPressed: () => _handleRefresh(ref),
        ),

        const Spacer(),

        // Mail count info
        if (totalMailCount > 0) ...[
          Text(
            '$totalMailCount mail',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Handle select all checkbox change
  void _handleSelectAllChanged(WidgetRef ref, bool? value) {
    if (value == null || isLoading) return;

    AppLogger.info('🔧 NoSelectionToolbar: Select all changed to $value');

    if (value) {
      // Select all current mails
      final currentMails = ref.read(currentMailsProvider);
      ref.read(mailSelectionProvider.notifier).selectAllFromList(currentMails);
      
      AppLogger.info('✅ Selected ${currentMails.length} mails');
    } else {
      // Clear all selections
      ref.read(mailSelectionProvider.notifier).clearAllSelections();
      
      AppLogger.info('✅ Cleared all selections');
    }
  }

  /// Handle refresh button press
  Future<void> _handleRefresh(WidgetRef ref) async {
    if (isLoading) return;

    AppLogger.info('🔄 NoSelectionToolbar: Refreshing $currentFolder');

    try {
      // Clear selections first
      ref.read(mailSelectionProvider.notifier).clearAllSelections();
      
      // Refresh current folder
      await ref
          .read(mailProvider.notifier)
          .refreshCurrentFolder(userEmail: userEmail);
      
      AppLogger.info('✅ Refresh completed for $currentFolder');
    } catch (e) {
      AppLogger.error('❌ Refresh failed: $e');
      
      // Show error snackbar if context available
      // Note: In real implementation, you might want to use a global error handler
    }
  }
}