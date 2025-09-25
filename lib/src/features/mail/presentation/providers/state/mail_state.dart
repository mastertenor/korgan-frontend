// lib/src/features/mail/presentation/providers/state/mail_state.dart

import '../../../domain/entities/mail.dart';
import '../../../domain/entities/tree_node.dart';

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
  //final int totalEstimate;
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
    //this.totalEstimate = 0,
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
      //totalEstimate: totalEstimate ?? this.totalEstimate,
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
    return copyWith(currentPage: 1, pageTokenStack: []);
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
        //other.totalEstimate == totalEstimate &&
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
      //totalEstimate,
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

  final TreeNode? currentTreeNode;
  final Map<String, List<Mail>> nodeMailCache; // Node ID -> Mails
  final Map<String, DateTime> nodeCacheTime; // Node ID -> Cache time
  final Map<String, String?> nodeNextPageTokens; // Node ID -> Next page token
  final Map<String, List<String>>
  nodePageTokenStacks; // Node ID -> Previous tokens
  final Map<String, int> nodeCurrentPages; // Node ID -> Current page
  

  const MailState({
    this.contexts = const {},
    this.currentFolder = MailFolder.inbox,
    this.isSearchMode = false,
    this.currentUserEmail,
    this.currentTreeNode,
    this.nodeMailCache = const {},
    this.nodeCacheTime = const {},
    this.nodeNextPageTokens = const {},
    this.nodePageTokenStacks = const {},
    this.nodeCurrentPages = const {},
  });


  /// Create copy with updated values
MailState copyWith({
    Map<MailFolder, MailContext>? contexts,
    MailFolder? currentFolder,
    bool? isSearchMode,
    String? currentUserEmail,
    TreeNode? currentTreeNode,
    Map<String, List<Mail>>? nodeMailCache,
    Map<String, DateTime>? nodeCacheTime,
    // 🆕 Yeni parametreler
    Map<String, String?>? nodeNextPageTokens,
    Map<String, List<String>>? nodePageTokenStacks,
    Map<String, int>? nodeCurrentPages,
  }) {
    return MailState(
      contexts: contexts ?? this.contexts,
      currentFolder: currentFolder ?? this.currentFolder,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      currentUserEmail: currentUserEmail ?? this.currentUserEmail,
      currentTreeNode: currentTreeNode ?? this.currentTreeNode,
      nodeMailCache: nodeMailCache ?? this.nodeMailCache,
      nodeCacheTime: nodeCacheTime ?? this.nodeCacheTime,
      // 🆕 Yeni parametreler
      nodeNextPageTokens: nodeNextPageTokens ?? this.nodeNextPageTokens,
      nodePageTokenStacks: nodePageTokenStacks ?? this.nodePageTokenStacks,
      nodeCurrentPages: nodeCurrentPages ?? this.nodeCurrentPages,
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
List<Mail> get currentMails {
    print('🔍 currentMails getter çağrıldı');

    // Loading durumunda boş liste döndür
// Sadece ilk yükleme sırasında boş liste döndür, pagination loading'de değil
    if (currentContext?.isLoading == true && !currentContext!.isLoadingMore) {
      print('⏳ İlk yükleme - boş liste');
      return [];
    }

    // TreeNode varsa onun cache'inden al
    if (currentTreeNode != null &&
        nodeMailCache.containsKey(currentTreeNode!.id)) {
      final nodeMails = nodeMailCache[currentTreeNode!.id] ?? [];
      print('✅ TreeNode cache\'den: ${nodeMails.length} mail');
      return nodeMails;
    }

    // Yoksa eski sistem
    final contextMails = currentContext?.mails ?? [];
    print('⚠️ Legacy context\'ten: ${contextMails.length} mail');
    return contextMails;
  }

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

  // 🆕 TreeNode helper methods

  /// Check if node has cached data
  bool hasNodeCache(String nodeId) {
    return nodeMailCache.containsKey(nodeId) &&
        nodeCacheTime.containsKey(nodeId);
  }

  /// Check if node cache is fresh (not stale)
  bool isNodeCacheFresh(String nodeId, {int maxAgeMinutes = 5}) {
    if (!nodeCacheTime.containsKey(nodeId)) return false;

    final cacheAge = DateTime.now().difference(nodeCacheTime[nodeId]!);
    return cacheAge.inMinutes < maxAgeMinutes;
  }

  /// Get mails for specific node
  List<Mail> getNodeMails(String nodeId) {
    return nodeMailCache[nodeId] ?? [];
  }

  /// Clear node cache
  MailState clearNodeCache([String? nodeId]) {
    if (nodeId != null) {
      final updatedCache = Map<String, List<Mail>>.from(nodeMailCache);
      updatedCache.remove(nodeId);

      final updatedTime = Map<String, DateTime>.from(nodeCacheTime);
      updatedTime.remove(nodeId);

      return copyWith(nodeMailCache: updatedCache, nodeCacheTime: updatedTime);
    } else {
      // Clear all
      return copyWith(nodeMailCache: {}, nodeCacheTime: {});
    }
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
    if (other is! MailState) return false;

    // Temel state karşılaştırması (mevcut kodun aynısı)
    if (other.currentFolder != currentFolder ||
        other.isSearchMode != isSearchMode ||
        other.currentUserEmail != currentUserEmail ||
        other.contexts.length != contexts.length ||
        other.currentTreeNode != currentTreeNode ||
        other.nodeMailCache.length != nodeMailCache.length) {
      return false;
    }

    // 🔥 ÖNEMLİ EK: Mevcut node'daki maillerin içeriğini karşılaştır
    if (currentTreeNode != null) {
      final currentMails = nodeMailCache[currentTreeNode!.id];
      final otherMails = other.nodeMailCache[currentTreeNode!.id];

      // Null check
      if (currentMails == null && otherMails == null) return true;
      if (currentMails == null || otherMails == null) return false;

      // Mail sayısı farklıysa
      if (currentMails.length != otherMails.length) {
        return false;
      }

      // Mail ID'leri farklıysa (içerik değişmiş)
      for (int i = 0; i < currentMails.length; i++) {
        if (currentMails[i].id != otherMails[i].id) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  int get hashCode {
    // Mevcut node'daki mail ID'leri ile hash oluştur
    int mailIdsHash = 0;
    if (currentTreeNode != null) {
      final currentMails = nodeMailCache[currentTreeNode!.id];
      if (currentMails != null && currentMails.isNotEmpty) {
        // Mail ID'lerinden hash oluştur
        mailIdsHash = Object.hashAll(currentMails.map((mail) => mail.id));
      }
    }

    return Object.hash(
      currentFolder,
      isSearchMode,
      currentUserEmail,
      contexts.length,
      currentTreeNode,
      nodeMailCache.length,
      mailIdsHash, // 🔥 Mail içeriği değişikliği algısı
    );
  }
   PaginationInfo get nodeBasedPaginationInfo {
    if (currentTreeNode == null) {
      return currentPaginationInfo; // Fallback to old system
    }
    
    final nodeMails = nodeMailCache[currentTreeNode!.id] ?? [];
    final currentPage = nodeCurrentPages[currentTreeNode!.id] ?? 1;
    final hasNext = nodeNextPageTokens[currentTreeNode!.id] != null;
    final hasPrevious = (nodePageTokenStacks[currentTreeNode!.id]?.isNotEmpty) ?? false;
    
    final itemsPerPage = 20;
    final startIndex = ((currentPage - 1) * itemsPerPage) + 1;
    final endIndex = startIndex + nodeMails.length - 1;
    
    return PaginationInfo(
      currentPage: currentPage,
      startIndex: nodeMails.isEmpty ? 0 : startIndex,
      endIndex: nodeMails.isEmpty ? 0 : endIndex,
      canGoNext: hasNext,
      canGoPrevious: hasPrevious,
      isLoading: false,
    );
  }
}

