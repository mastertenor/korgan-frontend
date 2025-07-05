// lib/src/features/mail/presentation/providers/mail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../domain/entities/mail.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/get_trash_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';

/// Mail state class - Gmail mobile style
class MailState {
  final List<Mail> mails;
  final List<Mail> trashMails;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isLoadingTrash;
  final bool isLoadingMoreTrash;
  final String? error;
  final String? trashError;
  final String? nextPageToken;
  final String? trashNextPageToken;
  final bool hasMore;
  final bool trashHasMore;
  final int unreadCount;
  final int trashCount;
  final int totalEstimate;

  const MailState({
    this.mails = const [],
    this.trashMails = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isLoadingTrash = false,
    this.isLoadingMoreTrash = false,
    this.error,
    this.trashError,
    this.nextPageToken,
    this.trashNextPageToken,
    this.hasMore = false,
    this.trashHasMore = false,
    this.unreadCount = 0,
    this.trashCount = 0,
    this.totalEstimate = 0,
  });

  /// Create copy with updated values
  MailState copyWith({
    List<Mail>? mails,
    List<Mail>? trashMails,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isLoadingTrash,
    bool? isLoadingMoreTrash,
    String? error,
    String? trashError,
    String? nextPageToken,
    String? trashNextPageToken,
    bool? hasMore,
    bool? trashHasMore,
    int? unreadCount,
    int? trashCount,
    int? totalEstimate,
  }) {
    return MailState(
      mails: mails ?? this.mails,
      trashMails: trashMails ?? this.trashMails,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingTrash: isLoadingTrash ?? this.isLoadingTrash,
      isLoadingMoreTrash: isLoadingMoreTrash ?? this.isLoadingMoreTrash,
      error: error,
      trashError: trashError,
      nextPageToken: nextPageToken,
      trashNextPageToken: trashNextPageToken,
      hasMore: hasMore ?? this.hasMore,
      trashHasMore: trashHasMore ?? this.trashHasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      trashCount: trashCount ?? this.trashCount,
      totalEstimate: totalEstimate ?? this.totalEstimate,
    );
  }

  /// Clear error
  MailState clearError() {
    return copyWith(error: null);
  }

  /// Clear trash error
  MailState clearTrashError() {
    return copyWith(trashError: null);
  }

  /// Check if any loading state is active
  bool get isAnyLoading =>
      isLoading || isLoadingMore || isLoadingTrash || isLoadingMoreTrash;

  @override
  String toString() {
    return 'MailState(mails: ${mails.length}, hasMore: $hasMore, nextToken: $nextPageToken)';
  }
}

/// Mail provider - Gmail mobile style pagination
class MailNotifier extends StateNotifier<MailState> {
  final GetMailsUseCase _getMailsUseCase;
  final GetTrashMailsUseCase _getTrashMailsUseCase;
  final MailActionsUseCase _mailActionsUseCase;

  MailNotifier(
    this._getMailsUseCase,
    this._getTrashMailsUseCase,
    this._mailActionsUseCase,
  ) : super(const MailState());

  /// Refresh mails (pull to refresh) - Gmail mobile style
  Future<void> refreshMails(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = GetMailsParams.refresh(email: email, maxResults: 20);
    final result = await _getMailsUseCase.refresh(params);

    result.when(
      success: (paginatedResult) => _handleRefreshSuccess(paginatedResult),
      failure: (failure) => _handleLoadFailure(failure),
    );
  }

  /// Load more mails (infinite scroll) - Gmail mobile style
  Future<void> loadMoreMails(String email) async {
    // Don't load if already loading or no more data
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    // Check if we have a next page token
    final nextToken = state.nextPageToken;
    if (nextToken == null || nextToken.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    final params = GetMailsParams.loadMore(
      email: email,
      pageToken: nextToken,
      maxResults: 20,
    );

    final result = await _getMailsUseCase.loadMore(params);

    result.when(
      success: (paginatedResult) => _handleLoadMoreSuccess(paginatedResult),
      failure: (failure) => _handleLoadMoreFailure(failure),
    );
  }

  /// Initial load mails (first app launch)
  Future<void> initialLoadMails(String email) async {
    // Only load if no mails exist
    if (state.mails.isNotEmpty) return;

    await refreshMails(email);
  }

  /// Handle refresh success (replace all mails)
  void _handleRefreshSuccess(PaginatedResult<Mail> paginatedResult) {
    final unreadCount = paginatedResult.items
        .where((mail) => !mail.isRead)
        .length;

    state = state.copyWith(
      mails: paginatedResult.items,
      isLoading: false,
      error: null,
      nextPageToken: paginatedResult.nextPageToken,
      hasMore: paginatedResult.hasMore,
      unreadCount: unreadCount,
      totalEstimate: paginatedResult.totalEstimate,
    );
  }

  /// Handle load more success (append mails)
  void _handleLoadMoreSuccess(PaginatedResult<Mail> paginatedResult) {
    final updatedMails = [...state.mails, ...paginatedResult.items];
    final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

    state = state.copyWith(
      mails: updatedMails,
      isLoadingMore: false,
      error: null,
      nextPageToken: paginatedResult.nextPageToken,
      hasMore: paginatedResult.hasMore,
      unreadCount: unreadCount,
      totalEstimate: paginatedResult.totalEstimate,
    );
  }

  /// Handle loading failure
  void _handleLoadFailure(failures.Failure failure) {
    state = state.copyWith(isLoading: false, error: failure.message);
  }

  /// Handle load more failure
  void _handleLoadMoreFailure(failures.Failure failure) {
    state = state.copyWith(isLoadingMore: false, error: failure.message);
  }

  /// Refresh trash mails (pull to refresh) - Gmail mobile style
  Future<void> refreshTrashMails(String email) async {
    state = state.copyWith(isLoadingTrash: true, trashError: null);

    final params = GetTrashMailsParams.refresh(email: email, maxResults: 20);
    final result = await _getTrashMailsUseCase.refresh(params);

    result.when(
      success: (paginatedResult) => _handleTrashRefreshSuccess(paginatedResult),
      failure: (failure) => _handleTrashLoadFailure(failure),
    );
  }

  /// Load more trash mails (infinite scroll) - Gmail mobile style
  Future<void> loadMoreTrashMails(String email) async {
    // Don't load if already loading or no more data
    if (state.isLoadingMoreTrash || !state.trashHasMore) {
      return;
    }

    // Check if we have a next page token
    final nextToken = state.trashNextPageToken;
    if (nextToken == null || nextToken.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMoreTrash: true, trashError: null);

    final params = GetTrashMailsParams.loadMore(
      email: email,
      pageToken: nextToken,
      maxResults: 20,
    );

    final result = await _getTrashMailsUseCase.loadMore(params);

    result.when(
      success: (paginatedResult) =>
          _handleTrashLoadMoreSuccess(paginatedResult),
      failure: (failure) => _handleTrashLoadMoreFailure(failure),
    );
  }

  /// Initial load trash mails (first time)
  Future<void> initialLoadTrashMails(String email) async {
    // Only load if no trash mails exist
    if (state.trashMails.isNotEmpty) return;

    await refreshTrashMails(email);
  }

  /// Handle trash refresh success (replace all trash mails)
  void _handleTrashRefreshSuccess(PaginatedResult<Mail> paginatedResult) {
    state = state.copyWith(
      trashMails: paginatedResult.items,
      isLoadingTrash: false,
      trashError: null,
      trashNextPageToken: paginatedResult.nextPageToken,
      trashHasMore: paginatedResult.hasMore,
      trashCount: paginatedResult.items.length,
    );
  }

  /// Handle trash load more success (append trash mails)
  void _handleTrashLoadMoreSuccess(PaginatedResult<Mail> paginatedResult) {
    final updatedTrashMails = [...state.trashMails, ...paginatedResult.items];

    state = state.copyWith(
      trashMails: updatedTrashMails,
      isLoadingMoreTrash: false,
      trashError: null,
      trashNextPageToken: paginatedResult.nextPageToken,
      trashHasMore: paginatedResult.hasMore,
      trashCount: updatedTrashMails.length,
    );
  }

  /// Handle trash loading failure
  void _handleTrashLoadFailure(failures.Failure failure) {
    state = state.copyWith(isLoadingTrash: false, trashError: failure.message);
  }

  /// Handle trash load more failure
  void _handleTrashLoadMoreFailure(failures.Failure failure) {
    state = state.copyWith(
      isLoadingMoreTrash: false,
      trashError: failure.message,
    );
  }

  /// Mark mail as read
  Future<void> markAsRead(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.markAsRead(params);

    result.when(
      success: (_) => _updateMailStatus(mailId, isRead: true),
      failure: (failure) => _setError(failure.message),
    );
  }

  /// Mark mail as unread
  Future<void> markAsUnread(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.markAsUnread(params);

    result.when(
      success: (_) => _updateMailStatus(mailId, isRead: false),
      failure: (failure) => _setError(failure.message),
    );
  }

  /// Move mail to trash (soft delete)
  Future<void> moveToTrash(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.moveToTrash(params);

    result.when(
      success: (_) => _moveMailToTrash(mailId),
      failure: (failure) => _setError(failure.message),
    );
  }

  /// Restore mail from trash
  Future<void> restoreFromTrash(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.restoreFromTrash(params);

    result.when(
      success: (_) => _restoreMailFromTrash(mailId),
      failure: (failure) => _setTrashError(failure.message),
    );
  }

  /// Permanently delete mail (hard delete)
  Future<void> deleteMail(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.deleteMail(params);

    result.when(
      success: (_) => _removeMailFromTrash(mailId),
      failure: (failure) => _setTrashError(failure.message),
    );
  }

  /// Empty trash (permanently delete all emails in trash)
  Future<void> emptyTrash(String email) async {
    final params = EmptyTrashParams(email: email);
    final result = await _mailActionsUseCase.emptyTrash(params);

    result.when(
      success: (_) => _clearTrashMails(),
      failure: (failure) => _setTrashError(failure.message),
    );
  }

  /// Archive mail
  Future<void> archiveMail(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.archiveMail(params);

    result.when(
      success: (_) => _removeMail(mailId),
      failure: (failure) => _setError(failure.message),
    );
  }

  /// Star mail
  Future<void> starMail(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.starMail(params);

    result.when(
      success: (_) => _updateMailStatus(mailId, isStarred: true),
      failure: (failure) => _setError(failure.message),
    );
  }

  /// Unstar mail
  Future<void> unstarMail(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.unstarMail(params);

    result.when(
      success: (_) => _updateMailStatus(mailId, isStarred: false),
      failure: (failure) => _setError(failure.message),
    );
  }

  /// Update mail status in local state
  void _updateMailStatus(
    String mailId, {
    bool? isRead,
    bool? isStarred,
    bool? isDeleted,
  }) {
    final updatedMails = state.mails.map((mail) {
      if (mail.id == mailId) {
        return mail.copyWith(
          isRead: isRead ?? mail.isRead,
          isStarred: isStarred ?? mail.isStarred,
          isDeleted: isDeleted ?? mail.isDeleted,
        );
      }
      return mail;
    }).toList();

    final updatedTrashMails = state.trashMails.map((mail) {
      if (mail.id == mailId) {
        return mail.copyWith(
          isRead: isRead ?? mail.isRead,
          isStarred: isStarred ?? mail.isStarred,
          isDeleted: isDeleted ?? mail.isDeleted,
        );
      }
      return mail;
    }).toList();

    final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

    state = state.copyWith(
      mails: updatedMails,
      trashMails: updatedTrashMails,
      unreadCount: unreadCount,
    );
  }

  /// Move mail from mails to trash
  void _moveMailToTrash(String mailId) {
    final mail = state.mails.firstWhere((m) => m.id == mailId);
    final updatedMail = mail.copyWith(isDeleted: true);

    final updatedMails = state.mails.where((m) => m.id != mailId).toList();
    final updatedTrashMails = [...state.trashMails, updatedMail];

    final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

    state = state.copyWith(
      mails: updatedMails,
      trashMails: updatedTrashMails,
      unreadCount: unreadCount,
      trashCount: updatedTrashMails.length,
    );
  }

  /// Restore mail from trash to mails
  void _restoreMailFromTrash(String mailId) {
    final mail = state.trashMails.firstWhere((m) => m.id == mailId);
    final updatedMail = mail.copyWith(isDeleted: false);

    final updatedTrashMails = state.trashMails
        .where((m) => m.id != mailId)
        .toList();
    final updatedMails = [...state.mails, updatedMail];

    final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

    state = state.copyWith(
      mails: updatedMails,
      trashMails: updatedTrashMails,
      unreadCount: unreadCount,
      trashCount: updatedTrashMails.length,
    );
  }

  /// Remove mail from local state
  void _removeMail(String mailId) {
    final updatedMails = state.mails
        .where((mail) => mail.id != mailId)
        .toList();
    final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

    state = state.copyWith(mails: updatedMails, unreadCount: unreadCount);
  }

  /// Remove mail from trash (permanent delete)
  void _removeMailFromTrash(String mailId) {
    final updatedTrashMails = state.trashMails
        .where((mail) => mail.id != mailId)
        .toList();

    state = state.copyWith(
      trashMails: updatedTrashMails,
      trashCount: updatedTrashMails.length,
    );
  }

  /// Clear all trash mails (empty trash)
  void _clearTrashMails() {
    state = state.copyWith(trashMails: [], trashCount: 0);
  }

  /// Set error message
  void _setError(String message) {
    state = state.copyWith(error: message);
  }

  /// Set trash error message
  void _setTrashError(String message) {
    state = state.copyWith(trashError: message);
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  /// Clear trash error
  void clearTrashError() {
    state = state.clearTrashError();
  }

  // Legacy methods for backward compatibility
  @Deprecated('Use refreshMails() instead')
  Future<void> refresh(String email) async {
    await refreshMails(email);
  }

  @Deprecated('Use loadMoreMails() instead')
  Future<void> loadMore(String email) async {
    await loadMoreMails(email);
  }

  @Deprecated('Use initialLoadMails() instead')
  Future<void> loadMails(String email, {bool refresh = false}) async {
    if (refresh) {
      await refreshMails(email);
    } else {
      await loadMoreMails(email);
    }
  }

  @Deprecated('Use refreshTrashMails() instead')
  Future<void> refreshTrash(String email) async {
    await refreshTrashMails(email);
  }

  @Deprecated('Use loadMoreTrashMails() instead')
  Future<void> loadMoreTrash(String email) async {
    await loadMoreTrashMails(email);
  }

  @Deprecated('Use refreshTrashMails() or loadMoreTrashMails() instead')
  Future<void> loadTrashMails(String email, {bool refresh = false}) async {
    if (refresh) {
      await refreshTrashMails(email);
    } else {
      await loadMoreTrashMails(email);
    }
  }
}
