// lib/src/features/mail/presentation/providers/mixins/mail_search_mixin.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../utils/app_logger.dart';
import '../state/mail_state.dart';

/// Mixin for search-related operations in mail provider
/// 
/// This mixin provides search functionality including:
/// - Search in current folder
/// - Exit search mode
/// - Folder type conversions (base ↔ search)
/// - Label management for folders
mixin MailSearchMixin on StateNotifier<MailState> {
  
  /// Load mails with filters - must be implemented by the class using this mixin
  Future<void> loadMailsWithFilters({
    required MailFolder folder,
    String? userEmail,
    List<String>? labels,
    String? query,
    bool refresh = true,
    int maxResults = 20,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  });

  // ========== SEARCH OPERATIONS ==========

  /// Search in current folder
  /// 
  /// Switches to search mode and performs search with the given query.
  /// Creates a separate search context to preserve original folder state.
  Future<void> searchInCurrentFolder({
    required String query,
    String? userEmail,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  }) async {
    AppLogger.info('🚀 API: searchInCurrentFolder BAŞLADI');

    // 1. Determine target folders
    final baseFolder = getBaseFolder(state.currentFolder);
    final searchFolder = getSearchFolder(baseFolder);
    final labels = getFolderLabels(baseFolder);

    // 2. Switch to search mode
    state = state.copyWith(currentFolder: searchFolder, isSearchMode: true);

    // 3. Create loading context immediately
    final loadingContext = const MailContext().copyWith(
      isLoading: true,
      error: null,
      currentQuery: query,
      currentLabels: labels,
    );
    state = state.updateContext(searchFolder, loadingContext);

    // 4. Perform API call (loading already visible)
    try {
      await loadMailsWithFilters(
        folder: searchFolder,
        userEmail: userEmail,
        query: query,
        labels: labels,
        refresh: true,
        enableHighlight: enableHighlight, // 🆕 PASS HIGHLIGHT TO LOAD MAILS
      );
    } catch (error) {
      // Handle error - stop loading
      final errorContext = loadingContext.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      state = state.updateContext(searchFolder, errorContext);
      rethrow;
    }

    AppLogger.info('✅ API: searchInCurrentFolder BİTTİ');
  }

  /// Exit search mode - return to base folder
  /// 
  /// Switches back from search context to the original folder.
  /// Preserves the original folder's state and data.
  void exitSearch() {
    if (state.isSearchMode) {
      final baseFolder = getBaseFolder(state.currentFolder);
      switchToFolder(baseFolder);
    }
  }

  /// Switch to specific folder - must be implemented by the class using this mixin
  void switchToFolder(MailFolder folder);

  // ========== FOLDER TYPE CONVERSIONS ==========

  /// Get base folder from search folder
  /// 
  /// Converts search folder types back to their base equivalents.
  /// Example: MailFolder.inboxSearch → MailFolder.inbox
  MailFolder getBaseFolder(MailFolder searchFolder) {
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
        return searchFolder; // Already a base folder
    }
  }

  /// Get search folder for base folder
  /// 
  /// Converts base folder types to their search equivalents.
  /// Example: MailFolder.inbox → MailFolder.inboxSearch
  MailFolder getSearchFolder(MailFolder baseFolder) {
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
        return baseFolder; // Already a search folder or no equivalent
    }
  }

  /// Check if folder is a search context
  /// 
  /// Returns true if the folder is a search variant of a base folder.
  bool isSearchFolder(MailFolder folder) {
    return [
      MailFolder.inboxSearch,
      MailFolder.sentSearch,
      MailFolder.draftsSearch,
      MailFolder.spamSearch,
      MailFolder.starredSearch,
      MailFolder.importantSearch,
    ].contains(folder);
  }

  // ========== FOLDER LABEL MANAGEMENT ==========

  /// Get folder-specific labels
  /// 
  /// Returns the API labels associated with each folder type.
  /// Used for filtering mails by folder when making API calls.
  List<String>? getFolderLabels(MailFolder folder) {
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
        return null; // No labels (uses query instead, like important)
    }
  }

  /// Get folder-specific query
  /// 
  /// Returns the API query string for folders that use queries instead of labels.
  /// Example: Important folder uses 'is:important' query.
  String? getFolderQuery(MailFolder folder) {
    switch (folder) {
      case MailFolder.important:
        return 'is:important';
      default:
        return null; // Most folders use labels instead of queries
    }
  }

  // ========== SEARCH UTILITIES ==========

  /// Check if currently in search mode
  bool get isInSearchMode => state.isSearchMode;

  /// Get current search query
  String? get currentSearchQuery {
    final currentContext = state.currentContext;
    return currentContext?.currentQuery;
  }

  /// Get current search labels
  List<String>? get currentSearchLabels {
    final currentContext = state.currentContext;
    return currentContext?.currentLabels;
  }

  /// Check if current folder has active filters
  bool get hasActiveFilters {
    final currentContext = state.currentContext;
    return currentContext?.isFiltered ?? false;
  }

  /// Get filter description for current context
  String get currentFilterDescription {
    final currentContext = state.currentContext;
    return currentContext?.filterDescription ?? 'No filters';
  }

  /// Clear search and return to base folder
  void clearSearchAndReturnToBase() {
    if (isInSearchMode) {
      exitSearch();
    }
  }

  /// Get search context for folder
  MailContext? getSearchContext(MailFolder baseFolder) {
    final searchFolder = getSearchFolder(baseFolder);
    return state.contexts[searchFolder];
  }

  /// Check if folder has search results
  bool hasSearchResults(MailFolder baseFolder) {
    final searchContext = getSearchContext(baseFolder);
    return searchContext != null && searchContext.mails.isNotEmpty;
  }

  /// Get search results count for folder
  int getSearchResultsCount(MailFolder baseFolder) {
    final searchContext = getSearchContext(baseFolder);
    return searchContext?.mails.length ?? 0;
  }
}