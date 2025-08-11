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

  // ========== 🆕 SPLIT RATIO METHODS ==========

  /// Update split ratio for resizable layouts
  /// 
  /// [ratio] must be between 0.0 and 1.0
  /// - 0.0 = left/top panel minimum
  /// - 0.5 = equal split
  /// - 1.0 = right/bottom panel minimum
  /// 
  /// Only works when current layout supports resizing (vertical/horizontal split)
  void updateSplitRatio(double ratio) {
    // Validate ratio range
    if (ratio < 0.0 || ratio > 1.0) {
      AppLogger.warning('🎨 Invalid split ratio: $ratio. Must be between 0.0 and 1.0');
      return;
    }

    // Check if current layout supports resizing
    if (!state.supportsResizing) {
      AppLogger.warning('🎨 Current layout ${state.currentLayout.title} does not support resizing');
      return;
    }

    // Apply constraints (10% - 90%)
    final constrainedRatio = ratio.clamp(0.1, 0.9);
    
    AppLogger.debug('🎨 Updating split ratio from ${state.splitRatio} to $constrainedRatio');
    
    state = state.copyWith(splitRatio: constrainedRatio);
    
    // TODO: Save to SharedPreferences for persistence
    // _saveSplitRatioToPrefs(constrainedRatio);
  }

  /// Reset split ratio to default (50-50)
  void resetSplitRatio() {
    AppLogger.info('🎨 Resetting split ratio to default (0.5)');
    updateSplitRatio(0.5);
  }

  /// Set split ratio to a predefined value
  void setSplitRatioPreset(SplitRatioPreset preset) {
    double ratio;
    switch (preset) {
      case SplitRatioPreset.leftHeavy:
        ratio = 0.3; // 30-70 split (left/top smaller)
        break;
      case SplitRatioPreset.balanced:
        ratio = 0.5; // 50-50 split (equal)
        break;
      case SplitRatioPreset.rightHeavy:
        ratio = 0.7; // 70-30 split (right/bottom smaller)
        break;
    }
    
    AppLogger.info('🎨 Setting split ratio preset: ${preset.name} (ratio: $ratio)');
    updateSplitRatio(ratio);
  }

  /// Get current layout info for debugging
  String getCurrentLayoutInfo() {
    return 'Current Layout: ${state.currentLayout.title} (${state.currentLayout.id}) - Split Ratio: ${state.splitRatio}';
  }

  // ========== 🆕 VALIDATION HELPERS ==========

  /// Check if a ratio change is significant enough to update
  bool _isSignificantRatioChange(double newRatio) {
    const threshold = 0.01; // 1% threshold
    return (newRatio - state.splitRatio).abs() > threshold;
  }

  /// Smooth ratio update (for drag gestures)
  void updateSplitRatioSmooth(double ratio) {
    if (!_isSignificantRatioChange(ratio)) return;
    updateSplitRatio(ratio);
  }
}

// ========== 🆕 SPLIT RATIO PRESETS ==========

/// Predefined split ratio presets for quick selection
enum SplitRatioPreset {
  /// 30-70 split (left/top panel smaller)
  leftHeavy('left_heavy'),
  
  /// 50-50 split (equal panels)
  balanced('balanced'),
  
  /// 70-30 split (right/bottom panel smaller)
  rightHeavy('right_heavy');

  const SplitRatioPreset(this.id);
  final String id;
}