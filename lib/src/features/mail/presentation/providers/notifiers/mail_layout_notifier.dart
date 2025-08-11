// lib/src/features/mail/presentation/providers/notifiers/mail_layout_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/mail_layout_state.dart';
import '../../../../../utils/app_logger.dart';

/// StateNotifier for managing mail layout state
class MailLayoutNotifier extends StateNotifier<MailLayoutState> {
  MailLayoutNotifier() : super(MailLayoutState.initial) {
    AppLogger.info('🎨 MailLayoutNotifier initialized with: ${state.currentLayout.title}');
  }

  /// Change the current layout type
  Future<void> changeLayout(MailLayoutType newLayout) async {
    if (state.currentLayout == newLayout) {
      AppLogger.info('🎨 Layout already set to: ${newLayout.title}');
      return;
    }

    AppLogger.info('🎨 Changing layout from ${state.currentLayout.title} to ${newLayout.title}');
    
    // Set changing state
    state = state.copyWith(isChanging: true);

    try {
      // Simulate layout change delay (for smooth transitions)
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Apply new layout
      state = state.copyWith(
        currentLayout: newLayout,
        isChanging: false,
      );

      AppLogger.info('✅ Layout changed successfully to: ${newLayout.title}');
      
      // TODO: Here you can add additional logic like:
      // - Save layout preference to local storage
      // - Trigger UI reorganization
      // - Update analytics
      
    } catch (error, stackTrace) {
      AppLogger.error('❌ Failed to change layout: $error', error, stackTrace);
      
      // Revert to previous state on error
      state = state.copyWith(isChanging: false);
    }
  }

  /// Reset to default layout
  Future<void> resetToDefault() async {
    AppLogger.info('🎨 Resetting layout to default');
    await changeLayout(MailLayoutType.noSplit);
  }

  /// Get current layout info for debugging
  String getCurrentLayoutInfo() {
    return 'Current Layout: ${state.currentLayout.title} (${state.currentLayout.id})';
  }
}