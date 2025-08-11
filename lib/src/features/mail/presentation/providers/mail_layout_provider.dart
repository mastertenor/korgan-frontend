// lib/src/features/mail/presentation/providers/mail_layout_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/mail_layout_state.dart';
import 'notifiers/mail_layout_notifier.dart';

/// Main provider for mail layout state management
final mailLayoutProvider = StateNotifierProvider<MailLayoutNotifier, MailLayoutState>((ref) {
  return MailLayoutNotifier();
});

/// Provider for current layout type (convenience)
final currentLayoutProvider = Provider<MailLayoutType>((ref) {
  return ref.watch(mailLayoutProvider).currentLayout;
});

/// Provider for layout changing state (convenience)
final isLayoutChangingProvider = Provider<bool>((ref) {
  return ref.watch(mailLayoutProvider).isChanging;
});

/// Provider for checking if a specific layout is currently selected
final isLayoutSelectedProvider = Provider.family<bool, MailLayoutType>((ref, layoutType) {
  final currentLayout = ref.watch(currentLayoutProvider);
  return currentLayout == layoutType;
});

/// Provider for getting all available layout types
final availableLayoutsProvider = Provider<List<MailLayoutType>>((ref) {
  return MailLayoutType.values;
});

// ========== 🆕 SPLIT RATIO PROVIDERS ==========

/// Provider for current split ratio
final currentSplitRatioProvider = Provider<double>((ref) {
  return ref.watch(mailLayoutProvider).splitRatio;
});

/// Provider for constrained split ratio (with min/max limits applied)
final constrainedSplitRatioProvider = Provider<double>((ref) {
  return ref.watch(mailLayoutProvider).constrainedSplitRatio;
});

/// Provider to check if current layout supports resizing
final supportsResizingProvider = Provider<bool>((ref) {
  return ref.watch(mailLayoutProvider).supportsResizing;
});

/// Provider for left/top panel ratio (same as split ratio)
final leftPanelRatioProvider = Provider<double>((ref) {
  final splitRatio = ref.watch(currentSplitRatioProvider);
  return splitRatio;
});

/// Provider for right/bottom panel ratio (complement of split ratio)
final rightPanelRatioProvider = Provider<double>((ref) {
  final splitRatio = ref.watch(currentSplitRatioProvider);
  return 1.0 - splitRatio;
});

/// Provider for left/top panel flex value (for Expanded widgets)
final leftPanelFlexProvider = Provider<int>((ref) {
  final ratio = ref.watch(leftPanelRatioProvider);
  return (ratio * 100).round().clamp(1, 99); // Ensure at least 1 flex
});

/// Provider for right/bottom panel flex value (for Expanded widgets)
final rightPanelFlexProvider = Provider<int>((ref) {
  final ratio = ref.watch(rightPanelRatioProvider);
  return (ratio * 100).round().clamp(1, 99); // Ensure at least 1 flex
});

// ========== 🆕 CONDITIONAL PROVIDERS ==========

/// Provider that returns split ratio only if current layout supports resizing
/// Returns 0.5 (default) for non-resizable layouts
final activeSplitRatioProvider = Provider<double>((ref) {
  final supportsResizing = ref.watch(supportsResizingProvider);
  if (!supportsResizing) return 0.5;
  
  return ref.watch(currentSplitRatioProvider);
});

/// Provider for checking if split ratio is at default (0.5)
final isDefaultSplitRatioProvider = Provider<bool>((ref) {
  final splitRatio = ref.watch(currentSplitRatioProvider);
  const threshold = 0.05; // 5% threshold for "close to default"
  return (splitRatio - 0.5).abs() < threshold;
});

/// Provider for checking if split ratio is at minimum constraint (close to 0.1)
final isMinimumSplitRatioProvider = Provider<bool>((ref) {
  final splitRatio = ref.watch(currentSplitRatioProvider);
  const threshold = 0.15; // If ratio is less than 15%, consider it "minimum"
  return splitRatio < threshold;
});

/// Provider for checking if split ratio is at maximum constraint (close to 0.9)
final isMaximumSplitRatioProvider = Provider<bool>((ref) {
  final splitRatio = ref.watch(currentSplitRatioProvider);
  const threshold = 0.85; // If ratio is more than 85%, consider it "maximum"
  return splitRatio > threshold;
});

// ========== 🆕 PRESET PROVIDERS ==========

/// Provider for current split ratio preset (if it matches one)
final currentSplitRatioPresetProvider = Provider<SplitRatioPreset?>((ref) {
  final splitRatio = ref.watch(currentSplitRatioProvider);
  const threshold = 0.05; // 5% threshold for matching presets
  
  for (final preset in SplitRatioPreset.values) {
    double presetValue;
    switch (preset) {
      case SplitRatioPreset.leftHeavy:
        presetValue = 0.3;
        break;
      case SplitRatioPreset.balanced:
        presetValue = 0.5;
        break;
      case SplitRatioPreset.rightHeavy:
        presetValue = 0.7;
        break;
    }
    
    if ((splitRatio - presetValue).abs() < threshold) {
      return preset;
    }
  }
  
  return null; // No matching preset
});

/// Provider for available split ratio presets
final availableSplitRatioPresetsProvider = Provider<List<SplitRatioPreset>>((ref) {
  return SplitRatioPreset.values;
});

// ========== 🆕 DEBUGGING PROVIDER ==========

/// Provider for layout debug info (useful for development)
final layoutDebugInfoProvider = Provider<String>((ref) {
  final state = ref.watch(mailLayoutProvider);
  return 'Layout: ${state.currentLayout.title} | '
         'Resizable: ${state.supportsResizing} | '
         'Ratio: ${state.splitRatio.toStringAsFixed(2)} | '
         'Changing: ${state.isChanging}';
});