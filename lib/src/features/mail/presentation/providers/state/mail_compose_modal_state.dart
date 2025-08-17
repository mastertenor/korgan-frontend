// lib/src/features/mail/presentation/providers/state/mail_compose_modal_state.dart

import 'package:flutter/foundation.dart';

/// Mail compose modal state
@immutable
class MailComposeModalState {
  /// Modal açık mı?
  final bool isOpen;
  
  /// Modal küçültülmüş mü? (bottom bar)
  final bool isMinimized;
  
  /// Modal tam ekran mı?
  final bool isMaximized;
  
  /// Modal ID (multiple modal support için)
  final String? modalId;

  const MailComposeModalState({
    this.isOpen = false,
    this.isMinimized = false,
    this.isMaximized = false,
    this.modalId,
  });

  /// Initial state
  static const MailComposeModalState initial = MailComposeModalState();

  /// Copy with method
  MailComposeModalState copyWith({
    bool? isOpen,
    bool? isMinimized,
    bool? isMaximized,
    String? modalId,
  }) {
    return MailComposeModalState(
      isOpen: isOpen ?? this.isOpen,
      isMinimized: isMinimized ?? this.isMinimized,
      isMaximized: isMaximized ?? this.isMaximized,
      modalId: modalId ?? this.modalId,
    );
  }

  /// Computed properties
  bool get isNormalSize => isOpen && !isMinimized && !isMaximized;
  bool get isVisible => isOpen;

  @override
  String toString() {
    return 'MailComposeModalState('
           'isOpen: $isOpen, '
           'isMinimized: $isMinimized, '
           'isMaximized: $isMaximized, '
           'modalId: $modalId'
           ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailComposeModalState &&
        other.isOpen == isOpen &&
        other.isMinimized == isMinimized &&
        other.isMaximized == isMaximized &&
        other.modalId == modalId;
  }

  @override
  int get hashCode {
    return Object.hash(
      isOpen,
      isMinimized,
      isMaximized,
      modalId,
    );
  }
}