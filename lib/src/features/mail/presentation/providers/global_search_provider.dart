// lib/src/features/mail/presentation/providers/global_search_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/tree_node.dart';
import 'mail_providers.dart';


// ========== GLOBAL SEARCH STATE PROVIDERS ==========

/// Global search query provider
/// Holds the current search query from header search widget
final globalSearchQueryProvider = StateProvider<String>((ref) => '');

/// Global search mode provider
/// Indicates if we're currently in global search mode
final globalSearchModeProvider = StateProvider<bool>((ref) => false);

/// Global search node provider
/// Holds the TreeNode that search is being performed on
final globalSearchNodeProvider = StateProvider<TreeNode?>((ref) => null);

/// Global search loading provider
/// Indicates if global search is currently loading
final globalSearchLoadingProvider = Provider<bool>((ref) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final isLoading = ref.watch(currentLoadingProvider);

  // Only consider it "search loading" if we're in search mode AND loading
  return isSearchMode && isLoading;
});

/// Global search results provider
/// Returns the current mail list when in search mode, empty list otherwise
final globalSearchResultsProvider = Provider<List<Mail>>((ref) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final currentMails = ref.watch(currentMailsProvider);

  // Return results only if we're in search mode
  return isSearchMode ? currentMails : [];
});

/// Global search error provider
/// Returns error message if search failed
final globalSearchErrorProvider = Provider<String?>((ref) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final currentError = ref.watch(currentErrorProvider);

  // Return error only if we're in search mode
  return isSearchMode ? currentError : null;
});

/// Has global search results provider
/// Returns true if search mode is active and has results
final hasGlobalSearchResultsProvider = Provider<bool>((ref) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final searchResults = ref.watch(globalSearchResultsProvider);

  return isSearchMode && searchResults.isNotEmpty;
});

/// Is global search empty provider
/// Returns true if search mode is active but no results found
final isGlobalSearchEmptyProvider = Provider<bool>((ref) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final searchResults = ref.watch(globalSearchResultsProvider);
  final isLoading = ref.watch(globalSearchLoadingProvider);

  return isSearchMode && searchResults.isEmpty && !isLoading;
});

/// Can perform node search provider
/// Returns true if a TreeNode is selected and search can be performed
final canPerformNodeSearchProvider = Provider<bool>((ref) {
  final currentNode = ref.watch(currentTreeNodeProvider);
  final isLoading = ref.watch(globalSearchLoadingProvider);

  return currentNode != null && !isLoading;
});

// ========== GLOBAL SEARCH CONTROLLER ==========

/// Global Search Controller
/// Manages global search functionality and state coordination
class GlobalSearchController {
  final Ref ref;

  GlobalSearchController(this.ref);

  /// Perform global search using existing mobile pattern (LEGACY - will be deprecated)
  Future<void> performSearch(String query, {required String userEmail}) async {
    if (query.trim().isEmpty) {
      AppLogger.warning('🔍 GlobalSearch: Empty query provided');
      return;
    }

    AppLogger.info(
      '🔍 GlobalSearch: Starting legacy search for "$query" with highlight enabled',
    );

    try {
      // 1. Set search state
      ref.read(globalSearchQueryProvider.notifier).state = query.trim();
      ref.read(globalSearchModeProvider.notifier).state = true;

      // 2. Use existing mobile pattern - searchInCurrentFolder with highlight enabled
      await ref
          .read(mailProvider.notifier)
          .searchInCurrentFolder(
            query: query.trim(),
            userEmail: userEmail,
            enableHighlight: true, // 🆕 ENABLE HIGHLIGHT FOR GLOBAL SEARCH
          );

      AppLogger.info('✅ GlobalSearch: Legacy search completed successfully');
    } catch (error) {
      AppLogger.error('❌ GlobalSearch: Legacy search failed - $error');
      // Error will be handled by globalSearchErrorProvider
    }
  }

  /// Perform search on specific TreeNode (NEW)
  Future<void> performNodeSearch({
    required TreeNode node,
    required String query,
    required String userEmail,
  }) async {
    if (query.trim().isEmpty) {
      AppLogger.warning(
        '🔍 GlobalSearch: Empty query provided for node search',
      );
      return;
    }

    AppLogger.info(
      '🔍 GlobalSearch: Starting node search for "${node.title}" with query "$query"',
    );

    try {
      // 1. Set search state including node
      ref.read(globalSearchQueryProvider.notifier).state = query.trim();
      ref.read(globalSearchModeProvider.notifier).state = true;
      ref.read(globalSearchNodeProvider.notifier).state = node;

      // 2. Call TreeNode search method
      await ref
          .read(mailProvider.notifier)
          .searchInTreeNode(
            node: node,
            query: query.trim(),
            userEmail: userEmail,
          );

      AppLogger.info('✅ GlobalSearch: Node search completed successfully');
    } catch (error) {
      AppLogger.error('❌ GlobalSearch: Node search failed - $error');
      // Error will be handled by globalSearchErrorProvider
    }
  }

  /// Clear global search and return to folder view (LEGACY)
  void clearSearch() {
    AppLogger.info('🧹 GlobalSearch: Clearing legacy search');

    // Clear search state
    ref.read(globalSearchQueryProvider.notifier).state = '';
    ref.read(globalSearchModeProvider.notifier).state = false;

    // Exit search mode using existing pattern
    ref.read(mailProvider.notifier).exitSearch();

    AppLogger.info('✅ GlobalSearch: Legacy search cleared successfully');
  }

  /// Clear global search and reset TreeNode context (NEW)
Future<void> clearNodeSearch() async {
    AppLogger.info('🧹 GlobalSearch: Clearing node search');

    // Clear search state including node
    ref.read(globalSearchQueryProvider.notifier).state = '';
    ref.read(globalSearchModeProvider.notifier).state = false;
    ref.read(globalSearchNodeProvider.notifier).state = null;

    // Reset to original TreeNode state
    final currentNode = ref.read(currentTreeNodeProvider);
    if (currentNode != null) {
      // 🔥 EKLENDİ: Search cache'ini temizle
      ref.read(mailProvider.notifier).clearNodeCache(currentNode.id);

      AppLogger.info('🧹 Cleared search cache for node: ${currentNode.title}');
      AppLogger.info('🔄 Reloading original TreeNode: ${currentNode.title}');

      await ref
          .read(mailProvider.notifier)
          .loadTreeNodeMails(
            node: currentNode,
            userEmail: getCurrentUserEmail(),
            forceRefresh: true,
          );
    }

    AppLogger.info('✅ GlobalSearch: Node search cleared successfully');
  }
/// Get current user email from mail provider
  String getCurrentUserEmail() {
    final mailState = ref.read(mailProvider);
    return mailState.currentUserEmail ?? 'unknown@example.com';
  }
  /// Get current search summary for debugging
  String getSearchSummary() {
    final query = ref.read(globalSearchQueryProvider);
    final isSearchMode = ref.read(globalSearchModeProvider);
    final resultsCount = ref.read(globalSearchResultsProvider).length;
    final isLoading = ref.read(globalSearchLoadingProvider);
    final currentNode = ref.read(globalSearchNodeProvider);

    return 'GlobalSearch(query: "$query", mode: $isSearchMode, results: $resultsCount, loading: $isLoading, node: ${currentNode?.title ?? "none"})';
  }

  /// Check if currently in search mode
  bool get isInSearchMode => ref.read(globalSearchModeProvider);

  /// Get current search query
  String get currentQuery => ref.read(globalSearchQueryProvider);

  /// Get current search query (reactive - watches for changes)
  String watchCurrentQuery() => ref.watch(globalSearchQueryProvider);

  /// Check if currently in search mode (reactive - watches for changes)
  bool watchIsInSearchMode() => ref.watch(globalSearchModeProvider);

  /// Check if we have an active search query
  bool get hasActiveQuery => currentQuery.trim().isNotEmpty;

  /// Get current search node
  TreeNode? get currentSearchNode => ref.read(globalSearchNodeProvider);

  /// Get current search node (reactive - watches for changes)
  TreeNode? watchCurrentSearchNode() => ref.watch(globalSearchNodeProvider);

  /// Check if currently searching in a specific node
  bool get isNodeSearch => currentSearchNode != null;
}

/// Global Search Controller Provider
final globalSearchControllerProvider = Provider<GlobalSearchController>((ref) {
  return GlobalSearchController(ref);
});

// ========== UTILITY PROVIDERS ==========

/// Global search state summary provider (for debugging/UI)
final globalSearchStateSummaryProvider = Provider<String>((ref) {
  final controller = ref.read(globalSearchControllerProvider);
  return controller.getSearchSummary();
});

/// Can perform search provider
/// Returns true if search can be performed (not currently loading)
final canPerformGlobalSearchProvider = Provider<bool>((ref) {
  final isLoading = ref.watch(globalSearchLoadingProvider);
  return !isLoading;
});

/// Should show search results provider
/// Determines if search results should be displayed in mail list
final shouldShowSearchResultsProvider = Provider<bool>((ref) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final hasQuery = ref.watch(globalSearchQueryProvider).trim().isNotEmpty;

  return isSearchMode && hasQuery;
});

// ========== INTEGRATION HELPERS ==========

/// Helper class for integrating global search with existing mail system
class GlobalSearchIntegration {
  const GlobalSearchIntegration._();

  /// Check if global search should override normal mail list behavior
  static bool shouldUseSearchResults(WidgetRef ref) {
    return ref.watch(shouldShowSearchResultsProvider);
  }

  /// Get appropriate mail list based on search state
  static List<Mail> getMailList(WidgetRef ref) {
    final shouldUseSearch = shouldUseSearchResults(ref);

    if (shouldUseSearch) {
      return ref.watch(globalSearchResultsProvider);
    } else {
      return ref.watch(currentMailsProvider);
    }
  }

  /// Get appropriate loading state based on search state
  static bool getLoadingState(WidgetRef ref) {
    final shouldUseSearch = shouldUseSearchResults(ref);

    if (shouldUseSearch) {
      return ref.watch(globalSearchLoadingProvider);
    } else {
      return ref.watch(currentLoadingProvider);
    }
  }

  /// Get appropriate error state based on search state
  static String? getErrorState(WidgetRef ref) {
    final shouldUseSearch = shouldUseSearchResults(ref);

    if (shouldUseSearch) {
      return ref.watch(globalSearchErrorProvider);
    } else {
      return ref.watch(currentErrorProvider);
    }
  }
}

/// Global Search Integration Provider
final globalSearchIntegrationProvider = Provider<GlobalSearchIntegration>((
  ref,
) {
  return const GlobalSearchIntegration._();
});

// ========== MAIL DETAIL SEARCH CONTEXT ==========

/// Mail detail search context provider
/// Provides search context information for mail detail pages
class MailDetailSearchContext {
  final bool isSearchMode;
  final String? searchQuery;
  final bool shouldHighlight;
  final TreeNode? searchNode;

  const MailDetailSearchContext({
    required this.isSearchMode,
    this.searchQuery,
    required this.shouldHighlight,
    this.searchNode,
  });

  /// Factory constructor for non-search mode
  factory MailDetailSearchContext.normal() {
    return const MailDetailSearchContext(
      isSearchMode: false,
      searchQuery: null,
      shouldHighlight: false,
      searchNode: null,
    );
  }

  /// Factory constructor for search mode
  factory MailDetailSearchContext.search(String query, {TreeNode? node}) {
    return MailDetailSearchContext(
      isSearchMode: true,
      searchQuery: query,
      shouldHighlight: true,
      searchNode: node,
    );
  }
}

/// Provider that returns current mail detail search context
final mailDetailSearchContextProvider = Provider<MailDetailSearchContext>((
  ref,
) {
  final isSearchMode = ref.watch(globalSearchModeProvider);
  final searchQuery = ref.watch(globalSearchQueryProvider);
  final searchNode = ref.watch(globalSearchNodeProvider);

  if (isSearchMode && searchQuery.trim().isNotEmpty) {
    return MailDetailSearchContext.search(searchQuery.trim(), node: searchNode);
  }

  return MailDetailSearchContext.normal();
});
