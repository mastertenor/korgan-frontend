// lib/src/features/mail/presentation/providers/mail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../utils/app_logger.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/paginated_result.dart';

import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';

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

  MailNotifier(this._getMailsUseCase, this._mailActionsUseCase)
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
