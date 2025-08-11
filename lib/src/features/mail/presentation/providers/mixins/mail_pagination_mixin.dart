// lib/src/features/mail/presentation/providers/mixins/mail_pagination_mixin.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/app_logger.dart';
import '../../../domain/usecases/get_mails_usecase.dart';
import '../state/mail_state.dart';

/// Mixin for pagination-related operations in mail provider
/// 
/// This mixin provides pagination functionality including:
/// - Navigate to next page
/// - Navigate to previous page  
/// - Reset pagination state
/// - Page token management
mixin MailPaginationMixin on StateNotifier<MailState> {
  
  /// Get the GetMailsUseCase - must be implemented by the class using this mixin
  GetMailsUseCase get getMailsUseCase;

  // ========== PAGINATION METHODS ==========

  /// Go to next page
  /// 
  /// Loads the next page of mails for the current folder context.
  /// Uses page tokens for navigation and maintains page history.
  Future<void> goToNextPage({required String userEmail}) async {
    final currentContext = state.currentContext;
    if (currentContext == null || !currentContext.hasMore) {
      AppLogger.info('📄 Cannot go to next page: no more pages available');
      return;
    }

    AppLogger.info('📄 Going to next page from ${currentContext.currentPage}');

    // Set loading state
    final loadingContext = currentContext.copyWith(
      isLoadingMore: true,
      error: null,
    );
    state = state.updateContext(state.currentFolder, loadingContext);

    try {
      // Add current page token to stack for going back
      final updatedTokenStack = [
        ...currentContext.pageTokenStack,
        if (currentContext.nextPageToken != null) currentContext.nextPageToken!,
      ];

      // Load next page with current nextPageToken
      final params = GetMailsParams.loadMore(
        userEmail: userEmail,
        pageToken: currentContext.nextPageToken ?? '',
        maxResults: currentContext.itemsPerPage,
        labels: currentContext.currentLabels,
        query: currentContext.currentQuery,
      );

      final result = await getMailsUseCase.loadMore(params);

      result.when(
        success: (paginatedResult) {
          final updatedContext = currentContext.copyWith(
            mails: paginatedResult.items, // Replace with new page items
            isLoadingMore: false,
            error: null,
            nextPageToken: paginatedResult.nextPageToken,
            hasMore: paginatedResult.hasMore,
            currentPage: currentContext.currentPage + 1,
            pageTokenStack: updatedTokenStack,
            lastUpdated: DateTime.now(),
          );

          state = state.updateContext(state.currentFolder, updatedContext);
          AppLogger.info('✅ Successfully loaded next page ${updatedContext.currentPage}');
        },
        failure: (failure) {
          final errorContext = currentContext.copyWith(
            isLoadingMore: false,
            error: failure.message,
          );
          state = state.updateContext(state.currentFolder, errorContext);
          AppLogger.error('❌ Failed to load next page: ${failure.message}');
        },
      );
    } catch (e) {
      final errorContext = currentContext.copyWith(
        isLoadingMore: false,
        error: 'Sonraki sayfa yüklenirken hata oluştu',
      );
      state = state.updateContext(state.currentFolder, errorContext);
      AppLogger.error('❌ Exception in goToNextPage: $e');
    }
  }

  /// Go to previous page
  /// 
  /// Loads the previous page of mails using the page token stack.
  /// Removes the last token from stack to navigate backwards.
  Future<void> goToPreviousPage({required String userEmail}) async {
    final currentContext = state.currentContext;
    if (currentContext == null || currentContext.pageTokenStack.isEmpty) {
      AppLogger.info('📄 Cannot go to previous page: no previous pages available');
      return;
    }

    AppLogger.info('📄 Going to previous page from ${currentContext.currentPage}');

    // Set loading state
    final loadingContext = currentContext.copyWith(
      isLoadingMore: true,
      error: null,
    );
    state = state.updateContext(state.currentFolder, loadingContext);

    try {
      // Get previous page token from stack
      final updatedTokenStack = [...currentContext.pageTokenStack];
      final previousPageToken = updatedTokenStack.removeLast();

      final params = GetMailsParams.loadMore(
        userEmail: userEmail,
        pageToken: previousPageToken,
        maxResults: currentContext.itemsPerPage,
        labels: currentContext.currentLabels,
        query: currentContext.currentQuery,
      );

      final result = await getMailsUseCase.loadMore(params);

      result.when(
        success: (paginatedResult) {
          final updatedContext = currentContext.copyWith(
            mails: paginatedResult.items, // Replace with previous page items
            isLoadingMore: false,
            error: null,
            nextPageToken: paginatedResult.nextPageToken,
            hasMore: paginatedResult.hasMore,
            currentPage: currentContext.currentPage - 1,
            pageTokenStack: updatedTokenStack,
            lastUpdated: DateTime.now(),
          );

          state = state.updateContext(state.currentFolder, updatedContext);
          AppLogger.info('✅ Successfully loaded previous page ${updatedContext.currentPage}');
        },
        failure: (failure) {
          final errorContext = currentContext.copyWith(
            isLoadingMore: false,
            error: failure.message,
          );
          state = state.updateContext(state.currentFolder, errorContext);
          AppLogger.error('❌ Failed to load previous page: ${failure.message}');
        },
      );
    } catch (e) {
      final errorContext = currentContext.copyWith(
        isLoadingMore: false,
        error: 'Önceki sayfa yüklenirken hata oluştu',
      );
      state = state.updateContext(state.currentFolder, errorContext);
      AppLogger.error('❌ Exception in goToPreviousPage: $e');
    }
  }

  /// Reset pagination for current folder
  /// 
  /// Useful when switching folders or refreshing content.
  /// Clears page history and resets to page 1.
  void resetPagination() {
    final currentContext = state.currentContext;
    if (currentContext != null) {
      final resetContext = currentContext.resetPagination();
      state = state.updateContext(state.currentFolder, resetContext);
      AppLogger.info('🔄 Pagination reset for folder: ${state.currentFolder}');
    }
  }

  // ========== PAGINATION UTILITIES ==========

  /// Check if next page is available
  bool get canGoToNextPage {
    final currentContext = state.currentContext;
    return currentContext?.hasMore ?? false;
  }

  /// Check if previous page is available
  bool get canGoToPreviousPage {
    final currentContext = state.currentContext;
    return currentContext?.pageTokenStack.isNotEmpty ?? false;
  }

  /// Check if pagination is currently loading
  bool get isPaginationLoading {
    final currentContext = state.currentContext;
    return currentContext?.isLoadingMore ?? false;
  }

  /// Get current page number
  int get currentPageNumber {
    final currentContext = state.currentContext;
    return currentContext?.currentPage ?? 1;
  }

  /// Get pagination info for UI
  PaginationInfo get currentPaginationInfo {
    final currentContext = state.currentContext;
    return currentContext?.paginationInfo ?? PaginationInfo.empty();
  }

  /// Check if can perform next page action (not loading and has more)
  bool get canPerformNextPage {
    return canGoToNextPage && !isPaginationLoading;
  }

  /// Check if can perform previous page action (not loading and has previous)
  bool get canPerformPreviousPage {
    return canGoToPreviousPage && !isPaginationLoading;
  }
}