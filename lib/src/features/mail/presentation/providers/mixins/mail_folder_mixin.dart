// lib/src/features/mail/presentation/providers/mixins/mail_folder_mixin.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/app_logger.dart';
import '../state/mail_state.dart';

/// Mixin for folder management operations in mail provider
/// 
/// This mixin provides folder-specific functionality including:
/// - Load specific folder types (inbox, sent, drafts, etc.)
/// - Smart folder loading with caching
/// - Folder refresh operations
/// - Context-aware folder switching
mixin MailFolderMixin on StateNotifier<MailState> {
  
  /// Load mails with filters - must be implemented by the class using this mixin
  Future<void> loadMailsWithFilters({
    required MailFolder folder,
    String? userEmail,
    List<String>? labels,
    String? query,
    bool refresh = true,
    int maxResults = 20,
    bool enableHighlight = false,
  });

  /// Get folder labels - must be implemented by the class using this mixin
  List<String>? getFolderLabels(MailFolder folder);

  /// Get folder query - must be implemented by the class using this mixin
  String? getFolderQuery(MailFolder folder);

  /// Switch to folder - must be implemented by the class using this mixin
  void switchToFolder(MailFolder folder);

  // ========== FOLDER LOADING OPERATIONS ==========

  /// Load folder with smart caching
  /// 
  /// Implements intelligent loading strategy:
  /// - Uses cached data if fresh and not forced refresh
  /// - Switches to folder immediately for better UX
  /// - Delegates to specific folder loaders
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
      AppLogger.info('📁 Using cached data for folder: $folder');
      return;
    }

    // Switch to folder and start loading
    switchToFolder(folder);
    AppLogger.info('📁 Loading folder: $folder (forceRefresh: $forceRefresh)');

    try {
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
          AppLogger.warning('📁 Unknown folder type: $folder');
          break;
      }
    } catch (error) {
      AppLogger.error('❌ Failed to load folder $folder: $error');
      rethrow;
    }
  }

  /// Refresh current folder
  /// 
  /// Forces a refresh of the currently active folder.
  /// Useful for pull-to-refresh scenarios.
  Future<void> refreshCurrentFolder({String? userEmail}) async {
    AppLogger.info('🔄 Refreshing current folder: ${state.currentFolder}');
    await loadFolder(
      state.currentFolder,
      userEmail: userEmail,
      forceRefresh: true,
    );
  }

  // ========== FOLDER-SPECIFIC LOADING METHODS ==========

  /// Load INBOX mails
  /// 
  /// Loads mails from the inbox using the INBOX label.
  Future<void> loadInboxMails({String? userEmail, bool refresh = true}) async {
    AppLogger.info('📥 Loading inbox mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.inbox,
      userEmail: userEmail,
      labels: getFolderLabels(MailFolder.inbox),
      refresh: refresh,
    );
  }

  /// Load SENT mails
  /// 
  /// Loads mails from the sent folder using the SENT label.
  Future<void> loadSentMails({String? userEmail, bool refresh = true}) async {
    AppLogger.info('📤 Loading sent mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.sent,
      userEmail: userEmail,
      labels: getFolderLabels(MailFolder.sent),
      refresh: refresh,
    );
  }

  /// Load DRAFT mails
  /// 
  /// Loads mails from the drafts folder using the DRAFT label.
  Future<void> loadDraftMails({String? userEmail, bool refresh = true}) async {
    AppLogger.info('📝 Loading draft mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.drafts,
      userEmail: userEmail,
      labels: getFolderLabels(MailFolder.drafts),
      refresh: refresh,
    );
  }

  /// Load SPAM mails
  /// 
  /// Loads mails from the spam folder using the SPAM label.
  Future<void> loadSpamMails({String? userEmail, bool refresh = true}) async {
    AppLogger.info('🚫 Loading spam mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.spam,
      userEmail: userEmail,
      labels: getFolderLabels(MailFolder.spam),
      refresh: refresh,
    );
  }

  /// Load STARRED mails
  /// 
  /// Loads mails that are starred using the STARRED label.
  Future<void> loadStarredMails({
    String? userEmail,
    bool refresh = true,
  }) async {
    AppLogger.info('⭐ Loading starred mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.starred,
      userEmail: userEmail,
      labels: getFolderLabels(MailFolder.starred),
      refresh: refresh,
    );
  }

  /// Load IMPORTANT mails
  /// 
  /// Loads mails marked as important using the 'is:important' query.
  Future<void> loadImportantMails({
    String? userEmail,
    bool refresh = true,
  }) async {
    AppLogger.info('🔥 Loading important mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.important,
      userEmail: userEmail,
      query: getFolderQuery(MailFolder.important),
      refresh: refresh,
    );
  }

  /// Load TRASH mails
  /// 
  /// Loads mails from the trash folder using the TRASH label.
  Future<void> loadTrashMails({String? userEmail, bool refresh = true}) async {
    AppLogger.info('🗑️ Loading trash mails (refresh: $refresh)');
    await loadMailsWithFilters(
      folder: MailFolder.trash,
      userEmail: userEmail,
      labels: getFolderLabels(MailFolder.trash),
      refresh: refresh,
    );
  }

  // ========== FOLDER UTILITIES ==========

  /// Get all available folders
  List<MailFolder> get availableFolders => [
    MailFolder.inbox,
    MailFolder.starred,
    MailFolder.sent,
    MailFolder.drafts,
    MailFolder.important,
    MailFolder.spam,
    MailFolder.trash,
  ];

  /// Get current folder
  MailFolder get currentFolder => state.currentFolder;

  /// Check if folder is loaded
  bool isFolderLoaded(MailFolder folder) {
    final context = state.contexts[folder];
    return context != null && context.lastUpdated != null;
  }

  /// Check if folder is stale
  bool isFolderStale(MailFolder folder) {
    final context = state.contexts[folder];
    return context?.isStale ?? true;
  }

  /// Check if folder is loading
  bool isFolderLoading(MailFolder folder) {
    final context = state.contexts[folder];
    return context?.isLoading ?? false;
  }

  /// Get folder context
  MailContext? getFolderContext(MailFolder folder) {
    return state.contexts[folder];
  }

  /// Get folder mail count
  int getFolderMailCount(MailFolder folder) {
    final context = state.contexts[folder];
    return context?.mails.length ?? 0;
  }

  /// Get folder unread count
  int getFolderUnreadCount(MailFolder folder) {
    final context = state.contexts[folder];
    return context?.unreadCount ?? 0;
  }

  /// Get folder error
  String? getFolderError(MailFolder folder) {
    final context = state.contexts[folder];
    return context?.error;
  }

  /// Check if folder has error
  bool hasFolderError(MailFolder folder) {
    return getFolderError(folder) != null;
  }

  /// Check if folder has mails
  bool hasFolderMails(MailFolder folder) {
    return getFolderMailCount(folder) > 0;
  }

  /// Check if folder is empty
  bool isFolderEmpty(MailFolder folder) {
    final context = state.contexts[folder];
    if (context == null) return true;
    return context.mails.isEmpty && !context.isLoading;
  }

  /// Get folder loading summary
  FolderLoadingSummary getFolderLoadingSummary() {
    final summary = <MailFolder, bool>{};
    for (final folder in availableFolders) {
      summary[folder] = isFolderLoading(folder);
    }
    
    return FolderLoadingSummary(
      loadingFolders: summary,
      totalFolders: availableFolders.length,
      loadingCount: summary.values.where((loading) => loading).length,
    );
  }

  /// Preload essential folders
  /// 
  /// Loads inbox and starred folders in background for better UX.
  Future<void> preloadEssentialFolders({String? userEmail}) async {
    AppLogger.info('🚀 Preloading essential folders');
    
    final futures = <Future<void>>[];
    
    // Preload inbox if not loaded or stale
    if (!isFolderLoaded(MailFolder.inbox) || isFolderStale(MailFolder.inbox)) {
      futures.add(loadInboxMails(userEmail: userEmail, refresh: false));
    }
    
    // Preload starred if not loaded or stale
    if (!isFolderLoaded(MailFolder.starred) || isFolderStale(MailFolder.starred)) {
      futures.add(loadStarredMails(userEmail: userEmail, refresh: false));
    }
    
    try {
      await Future.wait(futures);
      AppLogger.info('✅ Essential folders preloaded successfully');
    } catch (error) {
      AppLogger.error('❌ Failed to preload essential folders: $error');
    }
  }

  /// Clear folder cache
  /// 
  /// Removes cached data for specific folder or all folders.
  void clearFolderCache([MailFolder? folder]) {
    if (folder != null) {
      // Clear specific folder
      final contexts = Map<MailFolder, MailContext>.from(state.contexts);
      contexts.remove(folder);
      state = state.copyWith(contexts: contexts);
      AppLogger.info('🧹 Cleared cache for folder: $folder');
    } else {
      // Clear all folders
      state = state.copyWith(contexts: {});
      AppLogger.info('🧹 Cleared all folder cache');
    }
  }

  /// Get folder statistics
  FolderStatistics getFolderStatistics() {
    int totalMails = 0;
    int totalUnread = 0;
    int loadedFolders = 0;
    int staleFolders = 0;

    for (final folder in availableFolders) {
      final context = state.contexts[folder];
      if (context != null) {
        if (context.lastUpdated != null) {
          loadedFolders++;
          totalMails += context.mails.length;
          totalUnread += context.unreadCount;
        }
        if (context.isStale) {
          staleFolders++;
        }
      }
    }

    return FolderStatistics(
      totalFolders: availableFolders.length,
      loadedFolders: loadedFolders,
      staleFolders: staleFolders,
      totalMails: totalMails,
      totalUnread: totalUnread,
    );
  }
}

// ========== DATA CLASSES ==========

/// Summary of folder loading states
class FolderLoadingSummary {
  final Map<MailFolder, bool> loadingFolders;
  final int totalFolders;
  final int loadingCount;

  const FolderLoadingSummary({
    required this.loadingFolders,
    required this.totalFolders,
    required this.loadingCount,
  });

  bool get isAnyLoading => loadingCount > 0;
  bool get isAllLoading => loadingCount == totalFolders;
  double get loadingPercentage => totalFolders > 0 ? loadingCount / totalFolders : 0.0;

  @override
  String toString() {
    return 'FolderLoadingSummary(loading: $loadingCount/$totalFolders, percentage: ${(loadingPercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// Statistics about folder states
class FolderStatistics {
  final int totalFolders;
  final int loadedFolders;
  final int staleFolders;
  final int totalMails;
  final int totalUnread;

  const FolderStatistics({
    required this.totalFolders,
    required this.loadedFolders,
    required this.staleFolders,
    required this.totalMails,
    required this.totalUnread,
  });

  int get unloadedFolders => totalFolders - loadedFolders;
  double get loadedPercentage => totalFolders > 0 ? loadedFolders / totalFolders : 0.0;
  double get stalePercentage => totalFolders > 0 ? staleFolders / totalFolders : 0.0;

  @override
  String toString() {
    return 'FolderStatistics(loaded: $loadedFolders/$totalFolders, stale: $staleFolders, mails: $totalMails, unread: $totalUnread)';
  }
}