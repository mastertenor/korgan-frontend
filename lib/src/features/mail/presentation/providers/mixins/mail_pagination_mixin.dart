// lib/src/features/mail/presentation/providers/mixins/mail_pagination_mixin.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return;
    }

    // Set loading state
    final loadingContext = currentContext.copyWith(
      isLoadingMore: true,
      error: null,
    );
    state = state.updateContext(state.currentFolder, loadingContext);

    try {
      // Prepare token for API call
      final tokenForAPI = currentContext.nextPageToken ?? '';

      // Load next page with current nextPageToken
      final params = GetMailsParams.loadMore(
        userEmail: userEmail,
        pageToken: tokenForAPI,
        maxResults: currentContext.itemsPerPage,
        labels: currentContext.currentLabels,
        query: currentContext.currentQuery,
      );

      final result = await getMailsUseCase.loadMore(params);

      result.when(
        success: (paginatedResult) {
          // Add the token that was USED to get current page, not the next page token
          final updatedTokenStack = [...currentContext.pageTokenStack];
          
          // Add the token that was used to reach the CURRENT page to stack
          final currentPageToken = tokenForAPI; // This is the token that got us this page
          if (currentPageToken.isNotEmpty) {
            updatedTokenStack.add(currentPageToken);
          }

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
        },
        failure: (failure) {
          final errorContext = currentContext.copyWith(
            isLoadingMore: false,
            error: failure.message,
          );
          state = state.updateContext(state.currentFolder, errorContext);
        },
      );
    } catch (e) {
      final errorContext = currentContext.copyWith(
        isLoadingMore: false,
        error: 'Sonraki sayfa yüklenirken hata oluştu',
      );
      state = state.updateContext(state.currentFolder, errorContext);
    }
  }

  /// Go to previous page
  /// 
  /// Loads the previous page of mails using the page token stack.
  Future<void> goToPreviousPage({required String userEmail}) async {
    final currentContext = state.currentContext;
    
    if (currentContext == null || currentContext.pageTokenStack.isEmpty) {
      return;
    }
    
    // Get the token for the page we want to go back to
    final stackCopy = [...currentContext.pageTokenStack];
    
    // If we're going from page 3 to page 2, we need the token that gets page 2
    // That should be the second-to-last token in the stack, not the last one
    final previousPageToken = stackCopy.length >= 2 
        ? stackCopy[stackCopy.length - 2]  // Second to last token
        : (stackCopy.isNotEmpty ? '' : ''); // If only one token, use empty (first page)
    
    // Check if we're going to the first page (empty token)
    final isGoingToFirstPage = previousPageToken.isEmpty;

    // Set loading state
    final loadingContext = currentContext.copyWith(
      isLoadingMore: true,
      error: null,
    );
    state = state.updateContext(state.currentFolder, loadingContext);

    try {
      late final result;
      
      if (isGoingToFirstPage) {
        // Use refresh() for first page instead of loadMore() with empty token
        final refreshParams = GetMailsParams.refresh(
          userEmail: userEmail,
          maxResults: currentContext.itemsPerPage,
          labels: currentContext.currentLabels,
          query: currentContext.currentQuery,
        );
        result = await getMailsUseCase.refresh(refreshParams);
      } else {
        // Use loadMore() for other pages with valid token
        final loadMoreParams = GetMailsParams.loadMore(
          userEmail: userEmail,
          pageToken: previousPageToken,
          maxResults: currentContext.itemsPerPage,
          labels: currentContext.currentLabels,
          query: currentContext.currentQuery,
        );
        result = await getMailsUseCase.loadMore(loadMoreParams);
      }

      result.when(
        success: (paginatedResult) {
          // Remove the last token from stack (the one that got us to current page)
          final updatedTokenStack = [...currentContext.pageTokenStack];
          if (updatedTokenStack.isNotEmpty) {
            updatedTokenStack.removeLast();
          }

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
        },
        failure: (failure) {
          final errorContext = currentContext.copyWith(
            isLoadingMore: false,
            error: failure.message,
          );
          state = state.updateContext(state.currentFolder, errorContext);
        },
      );
    } catch (e) {
      final errorContext = currentContext.copyWith(
        isLoadingMore: false,
        error: 'Önceki sayfa yüklenirken hata oluştu',
      );
      state = state.updateContext(state.currentFolder, errorContext);
    }
  }


// Mevcut goToNextPage ve goToPreviousPage metodlarının yanına bu iki metodu ekle:

/// Go to next page with highlight support (search mode)
Future<void> goToNextPageWithHighlight({required String userEmail}) async {
  final currentContext = state.currentContext;
  
  if (currentContext == null || !currentContext.hasMore) {
    return;
  }

  // Set loading state
  final loadingContext = currentContext.copyWith(
    isLoadingMore: true,
    error: null,
  );
  state = state.updateContext(state.currentFolder, loadingContext);

  try {
    final tokenForAPI = currentContext.nextPageToken ?? '';
    
    // Enable highlight for search mode pagination
    final params = GetMailsParams.loadMore(
      userEmail: userEmail,
      pageToken: tokenForAPI,
      maxResults: currentContext.itemsPerPage,
      labels: currentContext.currentLabels,
      query: currentContext.currentQuery,
      enableHighlight: true, // Always true for search mode
    );

    final result = await getMailsUseCase.loadMore(params);

    result.when(
      success: (paginatedResult) {
        final updatedTokenStack = [...currentContext.pageTokenStack];
        
        final currentPageToken = tokenForAPI;
        if (currentPageToken.isNotEmpty) {
          updatedTokenStack.add(currentPageToken);
        }

        final updatedContext = currentContext.copyWith(
          mails: paginatedResult.items,
          isLoadingMore: false,
          error: null,
          nextPageToken: paginatedResult.nextPageToken,
          hasMore: paginatedResult.hasMore,
          currentPage: currentContext.currentPage + 1,
          pageTokenStack: updatedTokenStack,
          lastUpdated: DateTime.now(),
        );

        state = state.updateContext(state.currentFolder, updatedContext);
      },
      failure: (failure) {
        final errorContext = currentContext.copyWith(
          isLoadingMore: false,
          error: failure.message,
        );
        state = state.updateContext(state.currentFolder, errorContext);
      },
    );
  } catch (e) {
    final errorContext = currentContext.copyWith(
      isLoadingMore: false,
      error: 'Sonraki sayfa yüklenirken hata oluştu',
    );
    state = state.updateContext(state.currentFolder, errorContext);
  }
}

/// Go to previous page with highlight support (search mode)
Future<void> goToPreviousPageWithHighlight({required String userEmail}) async {
  final currentContext = state.currentContext;
  
  if (currentContext == null || currentContext.pageTokenStack.isEmpty) {
    return;
  }

  final stackCopy = [...currentContext.pageTokenStack];
  final previousPageToken = stackCopy.length > 1 
      ? stackCopy[stackCopy.length - 2]
      : (stackCopy.isNotEmpty ? '' : '');
  
  final isGoingToFirstPage = previousPageToken.isEmpty;

  final loadingContext = currentContext.copyWith(
    isLoadingMore: true,
    error: null,
  );
  state = state.updateContext(state.currentFolder, loadingContext);

  try {
    late final result;
    
    if (isGoingToFirstPage) {
      final refreshParams = GetMailsParams.refresh(
        userEmail: userEmail,
        maxResults: currentContext.itemsPerPage,
        labels: currentContext.currentLabels,
        query: currentContext.currentQuery,
        enableHighlight: true, // Always true for search mode
      );
      result = await getMailsUseCase.refresh(refreshParams);
    } else {
      final loadMoreParams = GetMailsParams.loadMore(
        userEmail: userEmail,
        pageToken: previousPageToken,
        maxResults: currentContext.itemsPerPage,
        labels: currentContext.currentLabels,
        query: currentContext.currentQuery,
        enableHighlight: true, // Always true for search mode
      );
      result = await getMailsUseCase.loadMore(loadMoreParams);
    }

    result.when(
      success: (paginatedResult) {
        final updatedTokenStack = [...currentContext.pageTokenStack];
        if (updatedTokenStack.isNotEmpty) {
          updatedTokenStack.removeLast();
        }

        final updatedContext = currentContext.copyWith(
          mails: paginatedResult.items,
          isLoadingMore: false,
          error: null,
          nextPageToken: paginatedResult.nextPageToken,
          hasMore: paginatedResult.hasMore,
          currentPage: currentContext.currentPage - 1,
          pageTokenStack: updatedTokenStack,
          lastUpdated: DateTime.now(),
        );

        state = state.updateContext(state.currentFolder, updatedContext);
      },
      failure: (failure) {
        final errorContext = currentContext.copyWith(
          isLoadingMore: false,
          error: failure.message,
        );
        state = state.updateContext(state.currentFolder, errorContext);
      },
    );
  } catch (e) {
    final errorContext = currentContext.copyWith(
      isLoadingMore: false,
      error: 'Önceki sayfa yüklenirken hata oluştu',
    );
    state = state.updateContext(state.currentFolder, errorContext);
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