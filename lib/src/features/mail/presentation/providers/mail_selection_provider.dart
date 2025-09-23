// lib/src/features/mail/presentation/providers/mail_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mail.dart';

/// Mail selection state for managing selected mails in UI
/// 
/// This provider handles the selection state for mail items,
/// particularly useful for batch operations like delete, archive, etc.
class MailSelectionState {
  /// Set of selected mail IDs
  final Set<String> selectedMailIds;
  
  /// Whether "select all" is currently active
  final bool isSelectAllActive;
  
  /// Total count of available mails (for select all logic)
  final int totalMailCount;
  
  /// Last selection action timestamp (for UI feedback)
  final DateTime? lastSelectionTime;

  const MailSelectionState({
    this.selectedMailIds = const {},
    this.isSelectAllActive = false,
    this.totalMailCount = 0,
    this.lastSelectionTime,
  });

  /// Create initial state
  factory MailSelectionState.initial() {
    return const MailSelectionState();
  }

  /// Create copy with updated values
  MailSelectionState copyWith({
    Set<String>? selectedMailIds,
    bool? isSelectAllActive,
    int? totalMailCount,
    DateTime? lastSelectionTime,
  }) {
    return MailSelectionState(
      selectedMailIds: selectedMailIds ?? this.selectedMailIds,
      isSelectAllActive: isSelectAllActive ?? this.isSelectAllActive,
      totalMailCount: totalMailCount ?? this.totalMailCount,
      lastSelectionTime: lastSelectionTime ?? this.lastSelectionTime,
    );
  }

  // ========== COMPUTED PROPERTIES ==========

  /// Number of selected mails
  int get selectedCount => selectedMailIds.length;

  /// Whether any mail is selected
  bool get hasSelection => selectedMailIds.isNotEmpty;

  /// Whether all available mails are selected
  bool get isAllSelected => 
      totalMailCount > 0 && selectedCount == totalMailCount;

  /// Whether some (but not all) mails are selected
  bool get isPartiallySelected => 
      hasSelection && !isAllSelected;

  /// Selection percentage (0.0 to 1.0)
  double get selectionPercentage => 
      totalMailCount > 0 ? selectedCount / totalMailCount : 0.0;

  // ========== UTILITY METHODS ==========

  /// Check if specific mail is selected
  bool isMailSelected(String mailId) => selectedMailIds.contains(mailId);

  /// Get list of selected mail IDs
  List<String> get selectedMailIdsList => selectedMailIds.toList();

  @override
  String toString() {
    return 'MailSelectionState(selected: $selectedCount/$totalMailCount, '
           'selectAll: $isSelectAllActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailSelectionState &&
        other.selectedMailIds == selectedMailIds &&
        other.isSelectAllActive == isSelectAllActive &&
        other.totalMailCount == totalMailCount;
  }

  @override
  int get hashCode {
    return selectedMailIds.hashCode ^
        isSelectAllActive.hashCode ^
        totalMailCount.hashCode;
  }
}

/// Mail selection notifier for managing selection state
class MailSelectionNotifier extends StateNotifier<MailSelectionState> {
  MailSelectionNotifier() : super(MailSelectionState.initial());

  // ========== CORE SELECTION METHODS ==========

  /// Toggle selection of a specific mail
  void toggleMailSelection(String mailId) {
    final currentSelected = Set<String>.from(state.selectedMailIds);
    final now = DateTime.now();

    if (currentSelected.contains(mailId)) {
      // Deselect mail
      currentSelected.remove(mailId);
    } else {
      // Select mail
      currentSelected.add(mailId);
    }

    // Update select all state based on new selection
    final isAllSelected = state.totalMailCount > 0 && 
                         currentSelected.length == state.totalMailCount;

    state = state.copyWith(
      selectedMailIds: currentSelected,
      isSelectAllActive: isAllSelected,
      lastSelectionTime: now,
    );
  }

  /// Select specific mail (if not already selected)
  void selectMail(String mailId) {
    if (!state.isMailSelected(mailId)) {
      toggleMailSelection(mailId);
    }
  }

  /// Deselect specific mail (if currently selected)
  void deselectMail(String mailId) {
    if (state.isMailSelected(mailId)) {
      toggleMailSelection(mailId);
    }
  }

  /// Select multiple mails at once
  void selectMails(List<String> mailIds) {
    final currentSelected = Set<String>.from(state.selectedMailIds);
    currentSelected.addAll(mailIds);

    final isAllSelected = state.totalMailCount > 0 && 
                         currentSelected.length == state.totalMailCount;

    state = state.copyWith(
      selectedMailIds: currentSelected,
      isSelectAllActive: isAllSelected,
      lastSelectionTime: DateTime.now(),
    );
  }

  /// Deselect multiple mails at once
  void deselectMails(List<String> mailIds) {
    final currentSelected = Set<String>.from(state.selectedMailIds);
    for (final mailId in mailIds) {
      currentSelected.remove(mailId);
    }

    state = state.copyWith(
      selectedMailIds: currentSelected,
      isSelectAllActive: false,
      lastSelectionTime: DateTime.now(),
    );
  }

  // ========== SELECT ALL METHODS ==========

  /// Toggle select all state
  void toggleSelectAll() {
    if (state.isSelectAllActive || state.isAllSelected) {
      // Clear all selections
      clearAllSelections();
    } else {
      // Select all available mails
      selectAllAvailableMails();
    }
  }

  /// Select all available mails
  void selectAllAvailableMails() {
    // This will be called with actual mail IDs from the UI layer
    state = state.copyWith(
      isSelectAllActive: true,
      lastSelectionTime: DateTime.now(),
    );
  }

  /// Select all from provided mail list
  void selectAllFromList(List<Mail> mails) {
    final allMailIds = mails.map((mail) => mail.id).toSet();
    
    state = state.copyWith(
      selectedMailIds: allMailIds,
      isSelectAllActive: true,
      totalMailCount: mails.length,
      lastSelectionTime: DateTime.now(),
    );
  }

  /// Clear all selections
  void clearAllSelections() {
    state = state.copyWith(
      selectedMailIds: const {},
      isSelectAllActive: false,
      lastSelectionTime: DateTime.now(),
    );
  }

  // ========== CONTEXT UPDATE METHODS ==========

  /// Update total mail count (when mail list changes)
  void updateTotalMailCount(int count) {
    // Adjust selections if total count changed
    final currentSelected = Set<String>.from(state.selectedMailIds);
    final isAllSelected = count > 0 && currentSelected.length == count;

    state = state.copyWith(
      totalMailCount: count,
      isSelectAllActive: isAllSelected,
    );
  }

  /// Update selections based on new mail list
  void updateWithMailList(List<Mail> mails) {
    final currentSelected = Set<String>.from(state.selectedMailIds);
    final availableMailIds = mails.map((mail) => mail.id).toSet();
    
    // Remove selections for mails that are no longer available
    currentSelected.removeWhere((id) => !availableMailIds.contains(id));
    
    final isAllSelected = mails.isNotEmpty && 
                         currentSelected.length == mails.length;

    state = state.copyWith(
      selectedMailIds: currentSelected,
      isSelectAllActive: isAllSelected,
      totalMailCount: mails.length,
    );
  }

  /// Remove selections for specific mail IDs (e.g., after deletion)
  void removeFromSelection(List<String> mailIds) {
    final currentSelected = Set<String>.from(state.selectedMailIds);
    for (final mailId in mailIds) {
      currentSelected.remove(mailId);
    }

    state = state.copyWith(
      selectedMailIds: currentSelected,
      isSelectAllActive: false,
      lastSelectionTime: DateTime.now(),
    );
  }

/// Update mail list (simplified version for TreeNode support)
  /// This is called when switching between TreeNodes/folders
  void updateMailList(List<Mail> mails) {
    // Clear previous selections when switching folders/nodes
    state = state.copyWith(
      selectedMailIds: const {},
      isSelectAllActive: false,
      totalMailCount: mails.length,
      lastSelectionTime: DateTime.now(),
    );
  }
  // ========== UTILITY METHODS ==========

  /// Reset to initial state
  void reset() {
    state = MailSelectionState.initial();
  }

  /// Get selection summary for debugging
  String getSelectionSummary() {
    return 'Selected ${state.selectedCount} of ${state.totalMailCount} mails';
  }
}