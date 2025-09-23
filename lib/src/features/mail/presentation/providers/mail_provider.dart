// lib/src/features/mail/presentation/providers/mail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../utils/app_logger.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/tree_node.dart';

import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';

import 'mail_providers.dart';
import 'state/mail_state.dart';
import 'mixins/mail_pagination_mixin.dart';
import 'mixins/mail_search_mixin.dart';
import 'mixins/mail_folder_mixin.dart';
import 'mixins/mail_actions_mixin.dart';

/// 🎉 FINAL: Fully modular context-aware Mail provider
///
/// This provider now uses 4 specialized mixins for complete separation of concerns:
/// - MailPaginationMixin: Page navigation, token management
/// - MailSearchMixin: Search operations, folder conversions
/// - MailFolderMixin: Folder loading, smart caching
/// - MailActionsMixin: Mail actions, bulk operations, optimistic UI
///
/// Main provider is now focused only on core logic and coordination.
class MailNotifier extends StateNotifier<MailState>
    with
        MailPaginationMixin,
        MailSearchMixin,
        MailFolderMixin,
        MailActionsMixin {
  // 🆕 ALL MIXINS APPLIED

  final GetMailsUseCase _getMailsUseCase;
  final MailActionsUseCase _mailActionsUseCase;
  final Ref _ref; // 🆕 Added for provider access

  MailNotifier(this._getMailsUseCase, this._mailActionsUseCase, this._ref)
    : super(const MailState());

  // ========== MIXIN IMPLEMENTATIONS ==========

  /// Required by MailPaginationMixin and MailSearchMixin
  @override
  GetMailsUseCase get getMailsUseCase => _getMailsUseCase;

  /// Required by MailActionsMixin
  @override
  MailActionsUseCase get mailActionsUseCase => _mailActionsUseCase;

  /// Required by MailSearchMixin, MailFolderMixin, and MailActionsMixin
  @override
  void switchToFolder(MailFolder folder) {
    AppLogger.info('📁 Switching to folder: $folder');
    state = state.copyWith(
      currentFolder: folder,
      isSearchMode: isSearchFolder(folder), // Using SearchMixin method
    );
  }

  /// Required by MailSearchMixin and MailFolderMixin
  @override
  Future<void> loadMailsWithFilters({
    required MailFolder folder,
    String? userEmail,
    List<String>? labels,
    String? query,
    bool refresh = true,
    int maxResults = 20,
    bool enableHighlight = false,
  }) async {
    return _loadMailsWithFilters(
      folder: folder,
      userEmail: userEmail,
      labels: labels,
      query: query,
      refresh: refresh,
      maxResults: maxResults,
      enableHighlight: enableHighlight,
    );
  }

  /// Required by MailActionsMixin
  @override
  void setCurrentError(String? message) {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedContext = currentContext.copyWith(error: message);
      state = state.updateContext(state.currentFolder, updatedContext);
    }
  }

  /// Load folder with custom labels from TreeNode
  @override
  loadFolderWithLabels(
    MailFolder folder, { // <-- Positional parameter
    required String userEmail,
    required List<String> labels,
    bool forceRefresh = true,
  }) async {
    AppLogger.info(
      '📁 MailNotifier: Loading folder with labels: $folder, labels: $labels',
    );

    await loadMailsWithFilters(
      folder: folder,
      userEmail: userEmail,
      labels: labels,
      refresh: forceRefresh,
      maxResults: 20,
      enableHighlight: false,
    );
  }

  // 🆕 ========== TREENODE SUPPORT ==========

  /// Load mails for a specific TreeNode
  Future<void> loadTreeNodeMails({
    required TreeNode node,
    required String userEmail,
    bool forceRefresh = false,
  }) async {
    AppLogger.info('🌳 Loading mails for TreeNode: ${node.title} (${node.id})');

    // Check cache first
    if (!forceRefresh &&
        state.hasNodeCache(node.id) &&
        state.isNodeCacheFresh(node.id)) {
      AppLogger.info('📦 Using cached data for node: ${node.title}');

      // Update state with cached data
      state = state.copyWith(
        currentTreeNode: node,
        currentFolder: MailFolder.inbox, // Default folder for compatibility
      );

      // Update selection provider
      _ref
          .read(mailSelectionProvider.notifier)
          .updateMailList(state.getNodeMails(node.id));

      return;
    }

    // Set loading state
    state = state.copyWith(
      currentTreeNode: node,
      currentFolder: MailFolder.inbox,
    );

    // Update current context to show loading
    final loadingContext = MailContext(
      isLoading: true,
      mails: [],
      error: null,
      currentLabels: node.gmailLabelNames,
    );

    state = state.updateContext(MailFolder.inbox, loadingContext);

    try {
      // Get labels from node
      final labels = node.gmailLabelNames;

      AppLogger.info('📮 Fetching mails with labels: $labels');

      // API call
      final params = GetMailsParams.refresh(
        userEmail: userEmail,
        maxResults: 20,
        labels: labels.isNotEmpty ? labels : null,
        query: null,
        enableHighlight: false,
      );

      final result = await _getMailsUseCase.refresh(params);

      result.when(
        success: (paginatedResult) {
          // Update node cache
          final updatedNodeCache = Map<String, List<Mail>>.from(
            state.nodeMailCache,
          );
          updatedNodeCache[node.id] = paginatedResult.items;

          final updatedCacheTime = Map<String, DateTime>.from(
            state.nodeCacheTime,
          );
          updatedCacheTime[node.id] = DateTime.now();

          // 🆕 Pagination bilgilerini güncelle
          final updatedNextTokens = Map<String, String?>.from(
            state.nodeNextPageTokens,
          );
          updatedNextTokens[node.id] = paginatedResult.nextPageToken;

          final updatedPages = Map<String, int>.from(state.nodeCurrentPages);
          updatedPages[node.id] = 1; // İlk sayfa

          final updatedPageStacks = Map<String, List<String>>.from(
            state.nodePageTokenStacks,
          );
          updatedPageStacks[node.id] = []; // Stack'i temizle

          state = state.copyWith(
            nodeMailCache: updatedNodeCache,
            nodeCacheTime: updatedCacheTime,
            nodeNextPageTokens: updatedNextTokens,
            nodeCurrentPages: updatedPages,
            nodePageTokenStacks: updatedPageStacks,
          );

          // Update context for compatibility
          final updatedContext = MailContext(
            isLoading: false,
            mails: paginatedResult.items,
            error: null,
            nextPageToken: paginatedResult.nextPageToken,
            lastUpdated: DateTime.now(),
            currentLabels: labels,
          );

          state = state.updateContext(MailFolder.inbox, updatedContext);

          // Update selection provider
          _ref
              .read(mailSelectionProvider.notifier)
              .updateMailList(paginatedResult.items);

          AppLogger.info(
            '✅ Successfully loaded ${paginatedResult.items.length} mails for node: ${node.title}',
          );
        },
        failure: (failure) {
          // Update error state
          final errorContext = MailContext(
            isLoading: false,
            mails: [],
            error: failure.message,
            currentLabels: labels,
          );

          state = state.updateContext(MailFolder.inbox, errorContext);

          AppLogger.error(
            '❌ Failed to load mails for node ${node.title}: ${failure.message}',
          );
        },
      );
    } catch (error) {
      AppLogger.error('❌ Exception loading node mails: $error');

      final errorContext = MailContext(
        isLoading: false,
        mails: [],
        error: error.toString(),
      );

      state = state.updateContext(MailFolder.inbox, errorContext);
    }
  }

  /// Clear node cache
  void clearNodeCache([String? nodeId]) {
    state = state.clearNodeCache(nodeId);
    AppLogger.info('🧹 Cleared node cache: ${nodeId ?? "all"}');
  }

  // ========== CORE LOADING LOGIC ==========

  /// Internal mail loading with filters (private implementation)
  ///
  /// This is the core loading engine that all mixins use.
  /// Handles state management, API calls, and result processing.
  Future<void> _loadMailsWithFilters({
    required MailFolder folder,
    String? userEmail,
    List<String>? labels,
    String? query,
    bool refresh = true,
    int maxResults = 20,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  }) async {
    AppLogger.info(
      '📨 Loading mails for folder $folder (refresh: $refresh, maxResults: $maxResults, highlight: $enableHighlight)',
    );
    // 🔍 DEBUG: API çağrısı öncesi parametreler
    AppLogger.debug('🌐 _loadMailsWithFilters API call parameters:');
    AppLogger.debug('   - folder: $folder');
    AppLogger.debug('   - userEmail: $userEmail');
    AppLogger.debug('   - labels: $labels');
    AppLogger.debug('   - query: $query');
    AppLogger.debug('   - refresh: $refresh');
    AppLogger.debug('   - maxResults: $maxResults');

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

    try {
      final params = refresh
          ? GetMailsParams.refresh(
              userEmail: userEmail,
              maxResults: maxResults,
              labels: effectiveLabels,
              query: effectiveQuery,
              enableHighlight: enableHighlight, // 🆕 HIGHLIGHT TO PARAMS
            )
          : GetMailsParams.loadMore(
              userEmail: userEmail ?? state.currentUserEmail,
              pageToken: currentContext.nextPageToken ?? '',
              maxResults: maxResults,
              labels: effectiveLabels,
              query: effectiveQuery,
              enableHighlight: enableHighlight, // 🆕 HIGHLIGHT TO PARAMS
            );

      final result = refresh
          ? await _getMailsUseCase.refresh(params)
          : await _getMailsUseCase.loadMore(params);

      result.when(
        success: (paginatedResult) {
          _handleLoadSuccess(folder, paginatedResult, refresh);
          AppLogger.info(
            '✅ Successfully loaded ${paginatedResult.items.length} mails for folder $folder',
          );
        },
        failure: (failure) {
          _handleLoadFailure(folder, failure, refresh);
          AppLogger.error(
            '❌ Failed to load mails for folder $folder: ${failure.message}',
          );
        },
      );
    } catch (error) {
      // Mevcut failure class'ınızı kullanın (örneğin NetworkFailure, ServerFailure, vb.)
      final failure = failures.AppFailure.unknown(
        message: 'Loading failed: ${error.toString()}',
      );
      _handleLoadFailure(folder, failure, refresh);
      AppLogger.error('❌ Exception loading mails for folder $folder: $error');
    }
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

// lib/src/features/mail/presentation/providers/mail_provider.dart

  // TreeNode için next page
  Future<void> loadNextPageForNode({required String userEmail}) async {
    final currentNode = state.currentTreeNode;
    if (currentNode == null) {
      AppLogger.warning('No current tree node for pagination');
      return;
    }

    final nextToken = state.nodeNextPageTokens[currentNode.id];
    if (nextToken == null) {
      AppLogger.info('No more pages for node: ${currentNode.title}');
      return;
    }

    try {
      AppLogger.info('📄 Loading next page for node: ${currentNode.title}');

      final params = GetMailsParams.loadMore(
        userEmail: userEmail,
        pageToken: nextToken,
        maxResults: 20,
        labels: currentNode.gmailLabelNames,
      );

      final result = await _getMailsUseCase.loadMore(params);

      result.when(
        success: (paginatedResult) {
          // Update node cache with additional mails
          final currentMails = state.nodeMailCache[currentNode.id] ?? [];
          final updatedMails = [...currentMails, ...paginatedResult.items];

          final updatedCache = Map<String, List<Mail>>.from(
            state.nodeMailCache,
          );
          updatedCache[currentNode.id] = updatedMails;

          // Update pagination state
          final updatedNextTokens = Map<String, String?>.from(
            state.nodeNextPageTokens,
          );
          updatedNextTokens[currentNode.id] = paginatedResult.nextPageToken;

          final updatedPageStacks = Map<String, List<String>>.from(
            state.nodePageTokenStacks,
          );
          final currentStack = updatedPageStacks[currentNode.id] ?? [];
          updatedPageStacks[currentNode.id] = [...currentStack, nextToken];

          final updatedPages = Map<String, int>.from(state.nodeCurrentPages);
          updatedPages[currentNode.id] =
              (updatedPages[currentNode.id] ?? 1) + 1;

          state = state.copyWith(
            nodeMailCache: updatedCache,
            nodeNextPageTokens: updatedNextTokens,
            nodePageTokenStacks: updatedPageStacks,
            nodeCurrentPages: updatedPages,
          );

          // Update selection provider
          _ref
              .read(mailSelectionProvider.notifier)
              .updateMailList(updatedMails);

          AppLogger.info(
            '✅ Loaded page ${updatedPages[currentNode.id]} for node: ${currentNode.title}',
          );
        },
        failure: (failure) {
          AppLogger.error('❌ Failed to load next page: ${failure.message}');
        },
      );
    } catch (error) {
      AppLogger.error('❌ Exception loading next page: $error');
    }
  }

  // TreeNode için previous page
  Future<void> loadPreviousPageForNode({required String userEmail}) async {
    final currentNode = state.currentTreeNode;
    if (currentNode == null) return;

    final pageStack = state.nodePageTokenStacks[currentNode.id] ?? [];
    if (pageStack.isEmpty) {
      AppLogger.info('Already at first page for node: ${currentNode.title}');
      return;
    }

    // Previous page için full refresh gerekli (Gmail API limitation)
    // İlk sayfadan başlayıp istenen sayfaya kadar yükle
    await loadTreeNodeMails(
      node: currentNode,
      userEmail: userEmail,
      forceRefresh: true,
    );

    // İstenen sayfa sayısı kadar next page çağır
    for (int i = 0; i < pageStack.length - 1; i++) {
      await loadNextPageForNode(userEmail: userEmail);
    }
  }

  // ========== LOAD MORE OPERATIONS ==========

  /// Load more in current folder
  ///
  /// Specialized method for "load more" functionality.
  /// Includes robust error handling and user email resolution.
  Future<void> loadMoreInCurrentFolder({String? userEmail}) async {
    final folder = state.currentFolder;
    final context = state.contexts[folder];

    if (context == null || context.isLoadingMore || !context.hasMore) {
      AppLogger.info(
        '📄 Cannot load more: no context, already loading, or no more items',
      );
      return;
    }

    // 🔧 CRASH FIX: Safe user email resolution
    final effectiveUserEmail =
        userEmail ??
        state.currentUserEmail ??
        context.currentLabels?.first; // Fallback strategy

    // 🔧 CRASH FIX: Early return if no user email available
    if (effectiveUserEmail == null || effectiveUserEmail.isEmpty) {
      AppLogger.warning('⚠️ No user email available for loadMore operation');
      final errorContext = context.copyWith(
        error: 'Kullanıcı e-postası bulunamadı',
        isLoadingMore: false,
      );
      state = state.updateContext(folder, errorContext);
      return;
    }

    AppLogger.info('📄 Loading more for folder: $folder');

    try {
      await _loadMailsWithFilters(
        folder: folder,
        userEmail: effectiveUserEmail,
        refresh: false,
      );
    } catch (error) {
      // 🔧 CRASH FIX: Graceful error handling
      AppLogger.error('❌ loadMoreInCurrentFolder error: $error');
      final errorContext = context.copyWith(
        error: 'Daha fazla mail yüklenemedi: ${error.toString()}',
        isLoadingMore: false,
      );
      state = state.updateContext(folder, errorContext);
    }
  }

  // ========== UTILITY METHODS ==========

  /// Clear error in current context
  void clearError() {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final updatedContext = currentContext.clearError();
      state = state.updateContext(state.currentFolder, updatedContext);
      AppLogger.info('🧹 Cleared error for current context');
    }
  }

  /// Set current user email
  void setCurrentUserEmail(String email) {
    state = state.copyWith(currentUserEmail: email);
    AppLogger.info('👤 Set current user email: $email');
  }
}
