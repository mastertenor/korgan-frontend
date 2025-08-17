// lib/src/features/mail/presentation/providers/mail_compose_modal_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/mail_compose_modal_state.dart';

/// Mail compose modal state notifier
class MailComposeModalNotifier extends StateNotifier<MailComposeModalState> {
  MailComposeModalNotifier() : super(MailComposeModalState.initial);

  // ========== BASIC MODAL OPERATIONS ==========

  /// Modal'ı aç (normal boyutta)
  void openModal({String? modalId}) {
    state = state.copyWith(
      isOpen: true,
      isMinimized: false,
      isMaximized: false,
      modalId: modalId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Modal'ı kapat
  void closeModal() {
    state = MailComposeModalState.initial;
  }

  // ========== SIZE CONTROL OPERATIONS ==========

  /// Modal'ı küçült (bottom bar)
  void minimizeModal() {
    if (state.isOpen) {
      state = state.copyWith(
        isMinimized: true,
        isMaximized: false,
      );
    }
  }

  /// Modal'ı tam ekrana çıkar
  void maximizeModal() {
    if (state.isOpen) {
      state = state.copyWith(
        isMinimized: false,
        isMaximized: true,
      );
    }
  }

  /// Modal'ı normal boyuta getir
  void normalizeModal() {
    if (state.isOpen) {
      state = state.copyWith(
        isMinimized: false,
        isMaximized: false,
      );
    }
  }

  // ========== TOGGLE OPERATIONS ==========

  /// Minimize/Normal toggle
  void toggleMinimize() {
    if (state.isOpen) {
      if (state.isMinimized) {
        normalizeModal();
      } else {
        minimizeModal();
      }
    }
  }

  /// Maximize/Normal toggle
  void toggleMaximize() {
    if (state.isOpen) {
      if (state.isMaximized) {
        normalizeModal();
      } else {
        maximizeModal();
      }
    }
  }

  // ========== UTILITY METHODS ==========

  /// Modal'ı restore et (minimized'dan normal'a)
  void restoreModal() {
    if (state.isOpen && state.isMinimized) {
      normalizeModal();
    }
  }

  /// Reset tüm state
  void reset() {
    state = MailComposeModalState.initial;
  }
}

// ========== PROVIDERS ==========

/// Main modal state provider
final mailComposeModalProvider = StateNotifierProvider<MailComposeModalNotifier, MailComposeModalState>((ref) {
  return MailComposeModalNotifier();
});

// ========== UTILITY PROVIDERS ==========

/// Modal açık mı?
final isModalOpenProvider = Provider<bool>((ref) {
  final modalState = ref.watch(mailComposeModalProvider);
  return modalState.isOpen;
});

/// Modal küçültülmüş mü?
final isModalMinimizedProvider = Provider<bool>((ref) {
  final modalState = ref.watch(mailComposeModalProvider);
  return modalState.isMinimized;
});

/// Modal tam ekran mı?
final isModalMaximizedProvider = Provider<bool>((ref) {
  final modalState = ref.watch(mailComposeModalProvider);
  return modalState.isMaximized;
});

/// Modal normal boyutta mı?
final isModalNormalSizeProvider = Provider<bool>((ref) {
  final modalState = ref.watch(mailComposeModalProvider);
  return modalState.isNormalSize;
});

/// Modal görünür mü?
final isModalVisibleProvider = Provider<bool>((ref) {
  final modalState = ref.watch(mailComposeModalProvider);
  return modalState.isVisible;
});

/// Current modal ID
final currentModalIdProvider = Provider<String?>((ref) {
  final modalState = ref.watch(mailComposeModalProvider);
  return modalState.modalId;
});