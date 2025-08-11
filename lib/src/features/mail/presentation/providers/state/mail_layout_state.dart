// lib/src/features/mail/presentation/providers/state/mail_layout_state.dart

import 'package:flutter/foundation.dart';

/// Mail layout types for different view modes
enum MailLayoutType {
  /// Single pane view - only mail list
  noSplit('no_split', 'Bölme yok', 'Tek panel görünüm'),
  
  /// Vertical split - mail list on left, preview on right
  verticalSplit('vertical_split', 'Dikey bölme', 'İki kolon düzeni'),
  
  /// Horizontal split - mail list on top, preview on bottom
  horizontalSplit('horizontal_split', 'Yatay bölme', 'İki satır düzeni');

  const MailLayoutType(this.id, this.title, this.subtitle);

  /// Unique identifier for the layout type
  final String id;
  
  /// Display title for UI
  final String title;
  
  /// Description subtitle for UI
  final String subtitle;

  /// Get layout type by id
  static MailLayoutType fromId(String id) {
    return MailLayoutType.values.firstWhere(
      (layout) => layout.id == id,
      orElse: () => MailLayoutType.noSplit,
    );
  }
}

/// Mail layout state class
@immutable
class MailLayoutState {
  const MailLayoutState({
    required this.currentLayout,
    this.isChanging = false,
  });

  /// Currently selected layout type
  final MailLayoutType currentLayout;
  
  /// Whether layout is currently being changed
  final bool isChanging;

  /// Default state with no split layout
  static const MailLayoutState initial = MailLayoutState(
    currentLayout: MailLayoutType.noSplit,
    isChanging: false,
  );

  /// Copy with new values
  MailLayoutState copyWith({
    MailLayoutType? currentLayout,
    bool? isChanging,
  }) {
    return MailLayoutState(
      currentLayout: currentLayout ?? this.currentLayout,
      isChanging: isChanging ?? this.isChanging,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailLayoutState &&
        other.currentLayout == currentLayout &&
        other.isChanging == isChanging;
  }

  @override
  int get hashCode => Object.hash(currentLayout, isChanging);

  @override
  String toString() {
    return 'MailLayoutState(currentLayout: $currentLayout, isChanging: $isChanging)';
  }
}