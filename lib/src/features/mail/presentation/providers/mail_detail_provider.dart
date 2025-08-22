// lib/src/features/mail/presentation/providers/mail_detail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/features/mail/presentation/providers/mail_providers.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/usecases/get_mail_detail_usecase.dart';

/// Mail detail state management
///
/// This provider manages the state for mail detail view including
/// loading, error, and success states for detailed mail information.
class MailDetailState {
  final MailDetail? mailDetail;
  final String? renderedHtml;
  final bool isLoading;
  final String? error;
  final String? currentMailId;
  final DateTime? lastUpdated;

  const MailDetailState({
    this.mailDetail,
    this.renderedHtml,
    this.isLoading = false,
    this.error,
    this.currentMailId,
    this.lastUpdated,
  });

  /// Create initial state
  factory MailDetailState.initial() {
    return const MailDetailState();
  }

  /// Create loading state
  MailDetailState copyWithLoading({required String mailId}) {
    return MailDetailState(
      mailDetail: mailDetail,
      isLoading: true,
      error: null,
      currentMailId: mailId,
      lastUpdated: lastUpdated,
    );
  }

  /// Create success state
  MailDetailState copyWithSuccess({required MailDetail mailDetail}) {
    return MailDetailState(
      mailDetail: mailDetail,
      isLoading: false,
      error: null,
      currentMailId: mailDetail.id,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create error state
  MailDetailState copyWithError({required String error, String? mailId}) {
    return MailDetailState(
      mailDetail: mailDetail,
      isLoading: false,
      error: error,
      currentMailId: mailId ?? currentMailId,
      lastUpdated: lastUpdated,
    );
  }

  /// Clear error state
  MailDetailState clearError() {
    return MailDetailState(
      mailDetail: mailDetail,
      isLoading: isLoading,
      error: null,
      currentMailId: currentMailId,
      lastUpdated: lastUpdated,
    );
  }

  /// Check if state has data
  bool get hasData => mailDetail != null;

  /// Check if state has error
  bool get hasError => error != null;

  /// Check if content is loading for specific mail
  bool isLoadingMail(String mailId) => isLoading && currentMailId == mailId;

  /// Check if specific mail is loaded
  bool isMailLoaded(String mailId) =>
      mailDetail != null && mailDetail!.id == mailId;

  @override
  String toString() {
    return 'MailDetailState(mailId: $currentMailId, isLoading: $isLoading, '
        'hasData: $hasData, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailDetailState &&
        other.mailDetail?.id == mailDetail?.id &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.currentMailId == currentMailId;
  }

  @override
  int get hashCode =>
      Object.hash(mailDetail?.id, isLoading, error, currentMailId);
}

/// Mail detail state notifier
///
/// Manages loading, caching, and error handling for mail detail operations.
class MailDetailNotifier extends StateNotifier<MailDetailState> {
  final GetMailDetailUseCase _getMailDetailUseCase;

  MailDetailNotifier(this._getMailDetailUseCase)
    : super(MailDetailState.initial());

  /// Load mail detail by ID
  ///
  /// [mailId] - Gmail message ID to load
  /// [email] - User's email address
  /// [forceRefresh] - Force reload from server (bypass cache)
  Future<void> loadMailDetail({
    required String mailId,
    required String email,
    bool forceRefresh = false,
  }) async {
    // Check if already loaded and not forcing refresh
    if (!forceRefresh && state.isMailLoaded(mailId)) {
      return;
    }

    // Set loading state
    state = state.copyWithLoading(mailId: mailId);

    // Create use case parameters
    final params = GetMailDetailParams(
      mailId: mailId,
      email: email,
      forceRefresh: forceRefresh,
    );

    // Execute use case
    final result = await _getMailDetailUseCase.call(params);

    // Handle result
    result.when(
      success: (mailDetail) {
        state = state.copyWithSuccess(mailDetail: mailDetail);
      },
      failure: (failure) {
        state = state.copyWithError(error: failure.message, mailId: mailId);
      },
    );
  }

  /// Refresh current mail detail
  ///
  /// [email] - User's email address
  Future<void> refreshCurrentMail({required String email}) async {
    final currentMailId = state.currentMailId;
    if (currentMailId != null) {
      await loadMailDetail(
        mailId: currentMailId,
        email: email,
        forceRefresh: true,
      );
    }
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.clearError();
    }
  }

  /// Clear all data (useful when logging out or switching accounts)
  void clearData() {
    state = MailDetailState.initial();
  }

  /// Update mail detail in state (useful for optimistic updates)
  ///
  /// This can be used when mail actions (like mark as read) are performed
  /// and we want to update the detail view accordingly.
  void updateMailDetail(MailDetail updatedMail) {
    if (state.mailDetail?.id == updatedMail.id) {
      state = state.copyWithSuccess(mailDetail: updatedMail);
    }
  }
}

/// Mail detail provider
///
/// Provides access to mail detail state and operations.
final mailDetailProvider =
    StateNotifierProvider<MailDetailNotifier, MailDetailState>((ref) {
      final getMailDetailUseCase = ref.read(getMailDetailUseCaseProvider);
      return MailDetailNotifier(getMailDetailUseCase);
    });

/// Current mail detail provider
///
/// Returns the currently loaded mail detail, if any.
final currentMailDetailProvider = Provider<MailDetail?>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.mailDetail;
});

/// Mail detail loading provider
///
/// Returns true if mail detail is currently loading.
final mailDetailLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.isLoading;
});

/// Mail detail error provider
///
/// Returns current error message, if any.
final mailDetailErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.error;
});

/// Specific mail loading provider
///
/// Returns true if a specific mail is currently loading.
Provider<bool> mailLoadingProvider(String mailId) {
  return Provider<bool>((ref) {
    final state = ref.watch(mailDetailProvider);
    return state.isLoadingMail(mailId);
  });
}

/// Specific mail loaded provider
///
/// Returns true if a specific mail is currently loaded.
Provider<bool> mailLoadedProvider(String mailId) {
  return Provider<bool>((ref) {
    final state = ref.watch(mailDetailProvider);
    return state.isMailLoaded(mailId);
  });
}

/// Use case providers (to be added to mail_providers.dart)
///
/// These providers should be added to your existing mail_providers.dart file
/// to complete the dependency injection setup.

/*
// Add to mail_providers.dart:

/// Get Mail Detail UseCase Provider
final getMailDetailUseCaseProvider = Provider<GetMailDetailUseCase>((ref) {
  final repository = ref.read(mailRepositoryProvider);
  return GetMailDetailUseCase(repository);
});
*/
