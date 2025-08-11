// lib/src/features/mail/presentation/providers/state/mail_state.dart

import '../../../domain/entities/mail.dart';

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

/// Extension for MailFolder utilities
extension MailFolderExtension on MailFolder {
  /// Check if folder is a search context
  bool get isSearchFolder {
    return [
      MailFolder.inboxSearch,
      MailFolder.sentSearch,
      MailFolder.draftsSearch,
      MailFolder.spamSearch,
      MailFolder.starredSearch,
      MailFolder.importantSearch,
    ].contains(this);
  }

  /// Get base folder from search folder
  MailFolder get baseFolder {
    switch (this) {
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
        return this;
    }
  }

  /// Get search folder for base folder
  MailFolder get searchFolder {
    switch (this) {
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
        return this;
    }
  }

  /// Get display name for folder
  String get displayName {
    switch (this) {
      case MailFolder.inbox:
      case MailFolder.inboxSearch:
        return 'Inbox';
      case MailFolder.sent:
      case MailFolder.sentSearch:
        return 'Sent';
      case MailFolder.drafts:
      case MailFolder.draftsSearch:
        return 'Drafts';
      case MailFolder.spam:
      case MailFolder.spamSearch:
        return 'Spam';
      case MailFolder.trash:
        return 'Trash';
      case MailFolder.starred:
      case MailFolder.starredSearch:
        return 'Starred';
      case MailFolder.important:
      case MailFolder.importantSearch:
        return 'Important';
    }
  }
}

/// Pagination information for UI display
class PaginationInfo {
  final int currentPage;
  final int startIndex;
  final int endIndex;
  final bool canGoNext;
  final bool canGoPrevious;
  final bool isLoading;

  const PaginationInfo({
    required this.currentPage,
    required this.startIndex,
    required this.endIndex,
    required this.canGoNext,
    required this.canGoPrevious,
    required this.isLoading,
  });

  factory PaginationInfo.empty() {
    return const PaginationInfo(
      currentPage: 1,
      startIndex: 1,
      endIndex: 0,
      canGoNext: false,
      canGoPrevious: false,
      isLoading: false,
    );
  }

  /// Get display text for page range (e.g., "1-50 range")
  String get rangeDisplayText {
    if (startIndex == endIndex) {
      return '$startIndex';
    }
    return '$startIndex-$endIndex range';
  }

  @override
  String toString() {
    return 'PaginationInfo(page: $currentPage, range: $startIndex-$endIndex, next: $canGoNext, prev: $canGoPrevious, loading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginationInfo &&
        other.currentPage == currentPage &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.canGoNext == canGoNext &&
        other.canGoPrevious == canGoPrevious &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPage,
      startIndex,
      endIndex,
      canGoNext,
      canGoPrevious,
      isLoading,
    );
  }
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

  // Pagination specific
  final int currentPage;
  final List<String> pageTokenStack;
  final int itemsPerPage;

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
    this.currentPage = 1,
    this.pageTokenStack = const [],
    this.itemsPerPage = 20,
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
    int? currentPage,
    List<String>? pageTokenStack,
    int? itemsPerPage,
  }) {
    return MailContext(
      mails: mails ?? this.mails,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      totalEstimate: totalEstimate ?? this.totalEstimate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentLabels: currentLabels ?? this.currentLabels,
      currentQuery: currentQuery ?? this.currentQuery,
      currentPage: currentPage ?? this.currentPage,
      pageTokenStack: pageTokenStack ?? this.pageTokenStack,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  /// Get pagination info for current context
  PaginationInfo get paginationInfo {
    final startIndex = ((currentPage - 1) * itemsPerPage) + 1;
    final endIndex = startIndex + mails.length - 1;
    
    return PaginationInfo(
      currentPage: currentPage,
      startIndex: startIndex,
      endIndex: endIndex.clamp(startIndex, startIndex + itemsPerPage - 1),
      canGoNext: hasMore,
      canGoPrevious: pageTokenStack.isNotEmpty,
      isLoading: isLoading || isLoadingMore,
    );
  }

  /// Reset pagination state (for new folder/search)
  MailContext resetPagination() {
    return copyWith(
      currentPage: 1,
      pageTokenStack: [],
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
    return 'MailContext(mails: ${mails.length}, loading: $isLoading, filtered: $isFiltered, page: $currentPage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailContext &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.error == error &&
        other.nextPageToken == nextPageToken &&
        other.hasMore == hasMore &&
        other.unreadCount == unreadCount &&
        other.totalEstimate == totalEstimate &&
        other.currentPage == currentPage &&
        other.itemsPerPage == itemsPerPage;
  }

  @override
  int get hashCode {
    return Object.hash(
      mails.length,
      isLoading,
      isLoadingMore,
      error,
      nextPageToken,
      hasMore,
      unreadCount,
      totalEstimate,
      currentPage,
      itemsPerPage,
    );
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

  /// Get current pagination info
  PaginationInfo get currentPaginationInfo => 
      currentContext?.paginationInfo ?? PaginationInfo.empty();

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

  /// Get context for specific folder (creates empty if not exists)
  MailContext getContextOrEmpty(MailFolder folder) {
    return contexts[folder] ?? const MailContext();
  }

  /// Check if folder has been loaded
  bool isFolderLoaded(MailFolder folder) {
    final context = contexts[folder];
    return context != null && context.lastUpdated != null;
  }

  /// Check if folder is stale
  bool isFolderStale(MailFolder folder) {
    final context = contexts[folder];
    return context?.isStale ?? true;
  }

  @override
  String toString() {
    return 'MailState(currentFolder: $currentFolder, contexts: ${contexts.length}, searchMode: $isSearchMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailState &&
        other.currentFolder == currentFolder &&
        other.isSearchMode == isSearchMode &&
        other.currentUserEmail == currentUserEmail &&
        other.contexts.length == contexts.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentFolder,
      isSearchMode,
      currentUserEmail,
      contexts.length,
    );
  }
}