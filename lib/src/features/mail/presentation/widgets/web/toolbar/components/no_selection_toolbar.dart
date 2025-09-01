// lib/src/features/mail/presentation/widgets/web/toolbar/components/no_selection_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/state/mail_state.dart';
import '../toolbar_buttons/select_all_checkbox.dart';
import '../toolbar_buttons/refresh_button.dart';
import '../pagination/mail_pagination_web.dart';
import 'layout_dropdown/mail_layout_dropdown.dart'; // 🆕 Layout dropdown import

/// Toolbar displayed when no mails are selected
/// 
/// Contains:
/// - Select All checkbox (to select all current mails)
/// - Refresh button (to refresh current folder)
/// - Layout dropdown (to change view mode) 🆕
/// - Pagination controls (previous/next page navigation)
/// - Mail count info
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
    
    // 🆕 Watch pagination state
    final canGoNext = ref.watch(canGoNextPageProvider);
    final canGoPrevious = ref.watch(canGoPreviousPageProvider);
    //final paginationLoading = ref.watch(paginationLoadingProvider);
    final pageRange = ref.watch(pageRangeInfoProvider);


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

        //const SizedBox(width: 12),

        RefreshButton(
          userEmail: userEmail,
          currentFolder: currentFolder,
          isLoading: isLoading,
          onPressed: () => _handleRefresh(ref),
        ),

        // 🆕 Layout dropdown - Refresh button'dan sonra
        const Spacer(),

        // 🆕 Center: Pagination controls (when applicable)
        if (_shouldShowPagination(pageRange, canGoNext, canGoPrevious)) ...[
          // Use the existing MailPaginationWeb component
          MailPaginationWeb(
            userEmail: userEmail,
            height: 32.0, // Compact height for toolbar
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ],
        
        const SizedBox(width: 4),
        const MailLayoutDropdown(),

      ],
    );
  }

  // 🆕 PAGINATION LOGIC

  /// Check if pagination should be shown
  bool _shouldShowPagination(
    ({int start, int end}) pageRange,
    bool canGoNext,
    bool canGoPrevious,
  ) {
    // Show pagination if:
    // 1. There are mails to display (not empty state)
    // 2. Can navigate in either direction OR showing range > 0
    return pageRange.start > 0 && (canGoNext || canGoPrevious || pageRange.start > 1);
  }

  // EXISTING METHODS (UNCHANGED)

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