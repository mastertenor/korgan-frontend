// lib/src/features/mail/presentation/providers/mail_layout_providers.dart

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