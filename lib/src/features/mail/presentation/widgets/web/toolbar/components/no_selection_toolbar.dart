// lib/src/features/mail/presentation/widgets/web/toolbar/components/no_selection_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/mail_tree_provider.dart'; // V2: TreeNode provider
import '../../../../providers/state/mail_state.dart';
import '../toolbar_buttons/select_all_checkbox.dart';
import '../toolbar_buttons/refresh_button.dart';
import '../pagination/mail_pagination_web.dart';
import 'layout_dropdown/mail_layout_dropdown.dart';

/// Toolbar displayed when no mails are selected (V2)
///
/// Contains:
/// - Select All checkbox (to select all current mails)
/// - Refresh button (to refresh current folder based on TreeNode)
/// - Layout dropdown (to change view mode)
/// - Pagination controls (previous/next page navigation)
/// - Mail count info
class NoSelectionToolbar extends ConsumerWidget {
  final String userEmail;
  final int totalMailCount;
  final List<String>? currentLabels; // V2: Labels for mail loading
  final bool isLoading;

  const NoSelectionToolbar({
    super.key,
    required this.userEmail,
    required this.totalMailCount,
    required this.currentLabels,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selection state for checkbox
    final isAllSelected = ref.watch(isAllSelectedProvider);
    final isPartiallySelected = ref.watch(isPartiallySelectedProvider);

    // Watch pagination state
  final canGoNext = ref.watch(nodeCanGoNextProvider);
    final canGoPrevious = ref.watch(nodeCanGoPreviousProvider);
    final pageRange = ref.watch(pageRangeInfoProvider);

    // V2: Get selected node title for RefreshButton
    final selectedNode = ref.watch(selectedTreeNodeProvider);
    final currentFolderName = selectedNode?.title;

    return Row(
      children: [
        // Left side: Selection controls
        SelectAllCheckbox(
          isAllSelected: isAllSelected,
          isPartiallySelected: isPartiallySelected,
          totalMailCount: totalMailCount,
          isLoading: isLoading,
          onChanged: (value) => _handleSelectAllChanged(ref, value),
        ),

        RefreshButton(
          userEmail: userEmail,
          currentFolderName:
              currentFolderName, // V2: Direct folder name from TreeNode
          isLoading: isLoading,
          onPressed: () => _handleRefresh(ref),
        ),

        const Spacer(),

        // Center: Pagination controls (when applicable)
        if (_shouldShowPagination(pageRange, canGoNext, canGoPrevious)) ...[
          MailPaginationWeb(
            userEmail: userEmail,
            height: 32.0,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ],

        const SizedBox(width: 4),
        const MailLayoutDropdown(),
      ],
    );
  }

  /// Check if pagination should be shown
  bool _shouldShowPagination(
    ({int start, int end}) pageRange,
    bool canGoNext,
    bool canGoPrevious,
  ) {
    return pageRange.start > 0 &&
        (canGoNext || canGoPrevious || pageRange.start > 1);
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

/// V2: Handle refresh with TreeNode
  Future<void> _handleRefresh(WidgetRef ref) async {
    if (isLoading) return;

    AppLogger.info('🔄 NoSelectionToolbar: Refreshing...');

    try {
      // Clear selections first
      ref.read(mailSelectionProvider.notifier).clearAllSelections();

      // Get current tree node
      final selectedNode = ref.read(selectedTreeNodeProvider);

      if (selectedNode != null) {
        // TreeNode based refresh
        await ref
            .read(mailProvider.notifier)
            .loadTreeNodeMails(
              node: selectedNode,
              userEmail: userEmail,
              forceRefresh: true,
            );

        AppLogger.info('✅ Refresh completed for node: ${selectedNode.title}');
      } else {
        // Fallback to old system if no node selected
        await ref
            .read(mailProvider.notifier)
            .loadFolder(
              MailFolder.inbox,
              userEmail: userEmail,
              forceRefresh: true,
            );

        AppLogger.info('✅ Refresh defaulted to INBOX');
      }
    } catch (e) {
      AppLogger.error('❌ Refresh failed: $e');
    }
  }
}
