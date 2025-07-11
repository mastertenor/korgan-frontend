// lib/src/features/mail/presentation/providers/mail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';

/// Mail folder types - supports all Gmail-like folders
enum MailFolder {
  inbox,
  sent,
  drafts,
  spam,
  trash,
  starred,
  important,
  // Search contexts
  inboxSearch,
  sentSearch,
  draftsSearch,
  spamSearch,
  starredSearch,
  importantSearch,
}

/// Mail context for each folder - independent state management
class MailContext {
  final List<Mail> mails;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? nextPageToken;
  final bool hasMore;
  final int unreadCount;
  final int totalEstimate;
  final DateTime? lastUpdated;

  // Search/Filter specific
  final List<String>? currentLabels;
  final String? currentQuery;

  const MailContext({
    this.mails = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.nextPageToken,
    this.hasMore = false,
    this.unreadCount = 0,
    this.totalEstimate = 0,
    this.lastUpdated,
    this.currentLabels,
    this.currentQuery,
  });

  /// Create copy with updated values
  MailContext copyWith({
    List<Mail>? mails,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? nextPageToken,
    bool? hasMore,
    int? unreadCount,
    int? totalEstimate,
    DateTime? lastUpdated,
    List<String>? currentLabels,
    String? currentQuery,
  }) {
    return MailContext(
      mails: mails ?? this.mails,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      nextPageToken: nextPageToken,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      totalEstimate: totalEstimate ?? this.totalEstimate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentLabels: currentLabels ?? this.currentLabels,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }

  /// Clear error
  MailContext clearError() {
    return copyWith(error: null);
  }

  /// Check if context has filtering active
  bool get isFiltered =>
      (currentLabels != null && currentLabels!.isNotEmpty) ||
      (currentQuery != null && currentQuery!.isNotEmpty);

  /// Get filter description
  String get filterDescription {
    if (currentQuery != null && currentQuery!.isNotEmpty) {
      return 'Query: $currentQuery';
    }
    if (currentLabels != null && currentLabels!.isNotEmpty) {
      return 'Labels: ${currentLabels!.join(', ')}';
    }
    return 'All mails';
  }

  /// Check if context is stale (needs refresh)
  bool get isStale {
    if (lastUpdated == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    return difference.inMinutes > 5; // Stale after 5 minutes
  }

  @override
  String toString() {
    return 'MailContext(mails: ${mails.length}, loading: $isLoading, filtered: $isFiltered)';
  }
}

/// Enhanced Mail state with context-aware architecture
class MailState {
  final Map<MailFolder, MailContext> contexts;
  final MailFolder currentFolder;
  final bool isSearchMode;
  final String? currentUserEmail;

  const MailState({
    this.contexts = const {},
    this.currentFolder = MailFolder.inbox,
    this.isSearchMode = false,
    this.currentUserEmail,
  });

  /// Create copy with updated values
  MailState copyWith({
    Map<MailFolder, MailContext>? contexts,
    MailFolder? currentFolder,
    bool? isSearchMode,
    String? currentUserEmail,
  }) {
    return MailState(
      contexts: contexts ?? this.contexts,
      currentFolder: currentFolder ?? this.currentFolder,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      currentUserEmail: currentUserEmail ?? this.currentUserEmail,
    );
  }

  /// Update specific context
  MailState updateContext(MailFolder folder, MailContext context) {
    final updatedContexts = Map<MailFolder, MailContext>.from(contexts);
    updatedContexts[folder] = context;
    return copyWith(contexts: updatedContexts);
  }

  /// Get current context
  MailContext? get currentContext => contexts[currentFolder];

  /// Get current mails (from current context)
  List<Mail> get currentMails => currentContext?.mails ?? [];

  /// Get current loading state
  bool get isCurrentLoading => currentContext?.isLoading ?? false;

  /// Get current error
  String? get currentError => currentContext?.error;

  /// Total unread count across all folders
  int get totalUnreadCount {
    return contexts.values
        .expand((context) => context.mails)
        .where((mail) => !mail.isRead)
        .length;
  }

  /// Check if any loading is active
  bool get isAnyLoading {
    return contexts.values.any(
      (context) => context.isLoading || context.isLoadingMore,
    );
  }

  /// Get folder-specific unread count
  int getUnreadCount(MailFolder folder) {
    final context = contexts[folder];
    return context?.unreadCount ?? 0;
  }

  @override
  String toString() {
    return 'MailState(currentFolder: $currentFolder, contexts: ${contexts.length}, searchMode: $isSearchMode)';
  }
}

/// Context-aware Mail provider with multi-folder support
class MailNotifier extends StateNotifier<MailState> {
  final GetMailsUseCase _getMailsUseCase;
  final MailActionsUseCase _mailActionsUseCase;

  MailNotifier(this._getMailsUseCase, this._mailActionsUseCase)
    : super(const MailState());

  // ========== FOLDER MANAGEMENT ==========

  /// Switch to specific folder
  void switchToFolder(MailFolder folder) {
    state = state.copyWith(
      currentFolder: folder,
      isSearchMode: _isSearchFolder(folder),
    );
  }

  /// Check if folder is a search context
  bool _isSearchFolder(MailFolder folder) {
    return [
      MailFolder.inboxSearch,
      MailFolder.sentSearch,
      MailFolder.draftsSearch,
      MailFolder.spamSearch,
      MailFolder.starredSearch,
      MailFolder.importantSearch,
    ].contains(folder);
  }

  /// Get base folder from search folder
  MailFolder _getBaseFolder(MailFolder searchFolder) {
    switch (searchFolder) {
      case MailFolder.inboxSearch:
        return MailFolder.inbox;
      case MailFolder.sentSearch:
        return MailFolder.sent;
      case MailFolder.draftsSearch:
        return MailFolder.drafts;
      case MailFolder.spamSearch:
        return MailFolder.spam;
      case MailFolder.starredSearch:
        return MailFolder.starred;
      case MailFolder.importantSearch:
        return MailFolder.important;
      default:
        return searchFolder;
    }
  }

  /// Get search folder for base folder
  MailFolder _getSearchFolder(MailFolder baseFolder) {
    switch (baseFolder) {
      case MailFolder.inbox:
        return MailFolder.inboxSearch;
      case MailFolder.sent:
        return MailFolder.sentSearch;
      case MailFolder.drafts:
        return MailFolder.draftsSearch;
      case MailFolder.spam:
        return MailFolder.spamSearch;
      case MailFolder.starred:
        return MailFolder.starredSearch;
      case MailFolder.important:
        return MailFolder.importantSearch;
      default:
        return baseFolder;
    }
  }

  // ========== CONTEXT OPERATIONS ==========

  /// Load folder with smart caching
  Future<void> loadFolder(
    MailFolder folder, {
    String? userEmail,
    bool forceRefresh = false,
  }) async {
    final context = state.contexts[folder];

    // Smart loading: only refresh if stale or forced
    if (context != null && !context.isStale && !forceRefresh) {
      // Just switch to folder - data already cached
      switchToFolder(folder);
      return;
    }

    // Switch to folder and start loading
    switchToFolder(folder);

    switch (folder) {
      case MailFolder.inbox:
        await loadInboxMails(userEmail: userEmail, refresh: true);
        break;
      case MailFolder.starred:
        await loadStarredMails(userEmail: userEmail, refresh: true);
        break;
      case MailFolder.trash:
        await loadTrashMails(userEmail: userEmail, refresh: true);
        break;
      case MailFolder.sent:
        await loadSentMails(userEmail: userEmail, refresh: true);
        break;
      case MailFolder.drafts:
        await loadDraftMails(userEmail: userEmail, refresh: true);
        break;
      case MailFolder.spam:
        await loadSpamMails(userEmail: userEmail, refresh: true);
        break;
      case MailFolder.important:
        await loadImportantMails(userEmail: userEmail, refresh: true);
        break;
      default:
        break;
    }
  }

  /// Refresh current folder
  Future<void> refreshCurrentFolder({String? userEmail}) async {
    await loadFolder(
      state.currentFolder,
      userEmail: userEmail,
      forceRefresh: true,
    );
  }

  /// Load more in current folder
  Future<void> loadMoreInCurrentFolder({String? userEmail}) async {
    final folder = state.currentFolder;
    final context = state.contexts[folder];

    if (context == null || context.isLoadingMore || !context.hasMore) {
      return;
    }

    switch (folder) {
      case MailFolder.inbox:
      case MailFolder.inboxSearch:
        await _loadMailsWithFilters(
          folder: folder,
          userEmail: userEmail ?? state.currentUserEmail,
          refresh: false,
        );
        break;
      case MailFolder.trash:
        await _loadMailsWithFilters(
          folder: MailFolder.trash,
          userEmail: userEmail ?? state.currentUserEmail!,
          refresh: false,
        );
        break;
      case MailFolder.sent:
      case MailFolder.sentSearch:
        await _loadMailsWithFilters(
          folder: folder,
          userEmail: userEmail ?? state.currentUserEmail,
          refresh: false,
        );
        break;
      case MailFolder.drafts:
      case MailFolder.draftsSearch:
        await _loadMailsWithFilters(
          folder: folder,
          userEmail: userEmail ?? state.currentUserEmail,
          refresh: false,
        );
        break;
      case MailFolder.spam:
      case MailFolder.spamSearch:
        await _loadMailsWithFilters(
          folder: folder,
          userEmail: userEmail ?? state.currentUserEmail,
          refresh: false,
        );
        break;
      case MailFolder.starred:
      case MailFolder.starredSearch:
        await _loadMailsWithFilters(
          folder: folder,
          userEmail: userEmail ?? state.currentUserEmail,
          refresh: false,
        );
        break;
      case MailFolder.important:
      case MailFolder.importantSearch:
        await _loadMailsWithFilters(
          folder: folder,
          userEmail: userEmail ?? state.currentUserEmail,
          refresh: false,
        );
        break;
    }
  }

  // ========== FOLDER-SPECIFIC LOADING METHODS ==========

  /// Load INBOX mails
  Future<void> loadInboxMails({String? userEmail, bool refresh = true}) async {
    await _loadMailsWithFilters(
      folder: MailFolder.inbox,
      userEmail: userEmail,
      labels: [ApiEndpoints.labelInbox],
      refresh: refresh,
    );
  }

  /// Load SENT mails
  Future<void> loadSentMails({String? userEmail, bool refresh = true}) async {
    await _loadMailsWithFilters(
      folder: MailFolder.sent,
      userEmail: userEmail,
      labels: [ApiEndpoints.labelSent],
      refresh: refresh,
    );
  }

  /// Load DRAFT mails
  Future<void> loadDraftMails({String? userEmail, bool refresh = true}) async {
    await _loadMailsWithFilters(
      folder: MailFolder.drafts,
      userEmail: userEmail,
      labels: [ApiEndpoints.labelDraft],
      refresh: refresh,
    );
  }

  /// Load SPAM mails
  Future<void> loadSpamMails({String? userEmail, bool refresh = true}) async {
    await _loadMailsWithFilters(
      folder: MailFolder.spam,
      userEmail: userEmail,
      labels: [ApiEndpoints.labelSpam],
      refresh: refresh,
    );
  }

  /// Load STARRED mails
  Future<void> loadStarredMails({
    String? userEmail,
    bool refresh = true,
  }) async {
    await _loadMailsWithFilters(
      folder: MailFolder.starred,
      userEmail: userEmail,
      labels: [ApiEndpoints.labelStarred],
      refresh: refresh,
    );
  }

  /// Load IMPORTANT mails
  Future<void> loadImportantMails({
    String? userEmail,
    bool refresh = true,
  }) async {
    await _loadMailsWithFilters(
      folder: MailFolder.important,
      userEmail: userEmail,
      query: 'is:important',
      refresh: refresh,
    );
  }

  /// Load TRASH mails
  Future<void> loadTrashMails({String? userEmail, bool refresh = true}) async {
    await _loadMailsWithFilters(
      folder: MailFolder.trash,
      userEmail: userEmail,
      labels: [ApiEndpoints.labelTrash],
      refresh: refresh,
    );
  }

  // ========== SEARCH OPERATIONS ==========

  /// Search in current folder
  Future<void> searchInCurrentFolder({
    required String query,
    String? userEmail,
  }) async {
    final baseFolder = _getBaseFolder(state.currentFolder);
    final searchFolder = _getSearchFolder(baseFolder);

    // Get base folder labels for search context
    final labels = _getFolderLabels(baseFolder);

    await _loadMailsWithFilters(
      folder: searchFolder,
      userEmail: userEmail,
      query: query,
      labels: labels,
      refresh: true,
    );

    // Switch to search context
    switchToFolder(searchFolder);
  }

  /// Exit search mode - return to base folder
  void exitSearch() {
    if (state.isSearchMode) {
      final baseFolder = _getBaseFolder(state.currentFolder);
      switchToFolder(baseFolder);
    }
  }

  /// Get folder-specific labels
  List<String>? _getFolderLabels(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return [ApiEndpoints.labelInbox];
      case MailFolder.sent:
        return [ApiEndpoints.labelSent];
      case MailFolder.drafts:
        return [ApiEndpoints.labelDraft];
      case MailFolder.spam:
        return [ApiEndpoints.labelSpam];
      case MailFolder.starred:
        return [ApiEndpoints.labelStarred];
      case MailFolder.trash:
        return [ApiEndpoints.labelTrash];
      default:
        return null;
    }
  }

  // ========== CORE LOADING LOGIC ==========

  /// Generic mail loading with filters
  Future<void> _loadMailsWithFilters({
    required MailFolder folder,
    String? userEmail,
    List<String>? labels,
    String? query,
    bool refresh = true,
    int maxResults = 20,
  }) async {
    // Update context loading state
    final currentContext = state.contexts[folder] ?? const MailContext();

    // For load more: preserve current filters if not explicitly provided
    final effectiveLabels =
        labels ?? (refresh ? null : currentContext.currentLabels);
    final effectiveQuery =
        query ?? (refresh ? null : currentContext.currentQuery);

    final loadingContext = currentContext.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh,
      error: null,
      currentLabels: effectiveLabels,
      currentQuery: effectiveQuery,
    );

    state = state.updateContext(folder, loadingContext);

    final params = refresh
        ? GetMailsParams.refresh(
            userEmail: userEmail,
            maxResults: maxResults,
            labels: effectiveLabels,
            query: effectiveQuery,
          )
        : GetMailsParams.loadMore(
            userEmail: userEmail ?? state.currentUserEmail,
            pageToken: currentContext.nextPageToken!,
            maxResults: maxResults,
            labels: effectiveLabels, // ✅ Context'ten alındı
            query: effectiveQuery, // ✅ Context'ten alındı
          );

    final result = refresh
        ? await _getMailsUseCase.refresh(params)
        : await _getMailsUseCase.loadMore(params);

    result.when(
      success: (paginatedResult) =>
          _handleLoadSuccess(folder, paginatedResult, refresh),
      failure: (failure) => _handleLoadFailure(folder, failure, refresh),
    );
  }

  /// Handle successful load
  void _handleLoadSuccess(
    MailFolder folder,
    PaginatedResult<Mail> result,
    bool isRefresh,
  ) {
    final currentContext = state.contexts[folder] ?? const MailContext();

    final updatedMails = isRefresh
        ? result.items
        : [...currentContext.mails, ...result.items];

    final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

    final updatedContext = currentContext.copyWith(
      mails: updatedMails,
      isLoading: false,
      isLoadingMore: false,
      error: null,
      nextPageToken: result.nextPageToken,
      hasMore: result.hasMore,
      unreadCount: unreadCount,
      totalEstimate: result.totalEstimate,
      lastUpdated: DateTime.now(),
    );

    state = state.updateContext(folder, updatedContext);
  }

  /// Handle failed load
  void _handleLoadFailure(
    MailFolder folder,
    failures.Failure failure,
    bool isRefresh,
  ) {
    final currentContext = state.contexts[folder] ?? const MailContext();

    final updatedContext = currentContext.copyWith(
      isLoading: false,
      isLoadingMore: false,
      error: failure.message,
    );

    state = state.updateContext(folder, updatedContext);
  }

  // ========== TRASH OPERATIONS (Legacy Support) ==========

  // Private methods removed - now using generic _loadMailsWithFilters

  // ========== CONTEXT-AWARE OPTIMISTIC UI METHODS ==========

  /// Optimistic remove from current context
  void optimisticRemoveFromCurrentContext(String mailId) {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedMails = currentContext.mails
          .where((mail) => mail.id != mailId)
          .toList();

      final unreadCount = updatedMails.where((mail) => !mail.isRead).length;

      final updatedContext = currentContext.copyWith(
        mails: updatedMails,
        unreadCount: unreadCount,
      );

      state = state.updateContext(state.currentFolder, updatedContext);
    }
  }

  /// Restore mail to current context (for UNDO)
  void restoreMailToCurrentContext(Mail mail) {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedMails = [...currentContext.mails, mail];

      // Sort by time to maintain order
      updatedMails.sort((a, b) => b.time.compareTo(a.time));

      final unreadCount = updatedMails.where((m) => !m.isRead).length;

      final updatedContext = currentContext.copyWith(
        mails: updatedMails,
        unreadCount: unreadCount,
        error: null, // Clear any error
      );

      state = state.updateContext(state.currentFolder, updatedContext);
    }
  }

  /// API-only move to trash (context-aware)
  Future<void> moveToTrashApiOnly(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.moveToTrash(params);

    result.when(
      success: (_) {
        // ✅ API successful - clear any error
        _setCurrentError(null);
      },
      failure: (failure) {
        // ❌ API failed - set error and throw for UNDO
        _setCurrentError(failure.message);
        throw Exception(failure.message);
      },
    );
  }

  /// API-only archive mail (context-aware)
  Future<void> archiveMailApiOnly(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.archiveMail(params);

    result.when(
      success: (_) {
        // ✅ API successful - clear any error
        _setCurrentError(null);
      },
      failure: (failure) {
        // ❌ API failed - set error and throw for UNDO
        _setCurrentError(failure.message);
        throw Exception(failure.message);
      },
    );
  }

  // ========== MAIL ACTIONS (Context-Aware) ==========

  /// Update mail in all contexts where it exists
  void _updateMailInAllContexts(String mailId, Mail Function(Mail) updater) {
    final updatedContexts = <MailFolder, MailContext>{};

    for (final entry in state.contexts.entries) {
      final folder = entry.key;
      final context = entry.value;

      final updatedMails = context.mails.map((mail) {
        return mail.id == mailId ? updater(mail) : mail;
      }).toList();

      if (updatedMails != context.mails) {
        final unreadCount = updatedMails.where((mail) => !mail.isRead).length;
        updatedContexts[folder] = context.copyWith(
          mails: updatedMails,
          unreadCount: unreadCount,
        );
      }
    }

    // Update all affected contexts
    for (final entry in updatedContexts.entries) {
      state = state.updateContext(entry.key, entry.value);
    }
  }

  /// Mark mail as read (context-aware)
  Future<void> markAsRead(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.markAsRead(params);

    result.when(
      success: (_) => _updateMailInAllContexts(
        mailId,
        (mail) => mail.copyWith(isRead: true),
      ),
      failure: (failure) => _setCurrentError(failure.message),
    );
  }

  /// Mark mail as unread (context-aware)
  Future<void> markAsUnread(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.markAsUnread(params);

    result.when(
      success: (_) => _updateMailInAllContexts(
        mailId,
        (mail) => mail.copyWith(isRead: false),
      ),
      failure: (failure) => _setCurrentError(failure.message),
    );
  }

  /// Star mail (context-aware)
  Future<void> starMail(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.starMail(params);

    result.when(
      success: (_) => _updateMailInAllContexts(
        mailId,
        (mail) => mail.copyWith(isStarred: true),
      ),
      failure: (failure) {
        _setCurrentError(failure.message);
        throw Exception(failure.message);
      },
    );
  }

  /// Unstar mail (context-aware)
  Future<void> unstarMail(String mailId, String email) async {
    final params = MailActionParams(id: mailId, email: email);
    final result = await _mailActionsUseCase.unstarMail(params);

    result.when(
      success: (_) => _updateMailInAllContexts(
        mailId,
        (mail) => mail.copyWith(isStarred: false),
      ),
      failure: (failure) => _setCurrentError(failure.message),
    );
  }

  // ========== UTILITY METHODS ==========

  /// Set error in current context
  void _setCurrentError(String? message) {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedContext = currentContext.copyWith(error: message);
      state = state.updateContext(state.currentFolder, updatedContext);
    }
  }

  /// Clear error in current context
  void clearError() {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedContext = currentContext.clearError();
      state = state.updateContext(state.currentFolder, updatedContext);
    }
  }

  /// Set current user email
  void setCurrentUserEmail(String email) {
    state = state.copyWith(currentUserEmail: email);
  }
}
