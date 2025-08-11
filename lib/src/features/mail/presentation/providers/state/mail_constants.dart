// lib/src/features/mail/presentation/providers/state/mail_constants.dart

import 'mail_state.dart';

/// Mail-related constants and configuration values
class MailConstants {
  // Prevent instantiation
  MailConstants._();
  
  // ========== PAGINATION CONSTANTS ==========
  
  /// Default number of mails per page
  static const int defaultItemsPerPage = 20;
  
  /// Maximum number of mails per page
  static const int maxItemsPerPage = 100;
  
  /// Minimum number of mails per page
  static const int minItemsPerPage = 5;
  
  // ========== CACHE CONSTANTS ==========
  
  /// Cache duration in minutes before data is considered stale
  static const int cacheStaleMinutes = 5;
  
  /// Maximum number of contexts to keep in memory
  static const int maxContextsInMemory = 10;
  
  /// Maximum number of mails to keep per context
  static const int maxMailsPerContext = 500;
  
  // ========== API CONSTANTS ==========
  
  /// Default timeout for API requests in seconds
  static const int apiTimeoutSeconds = 30;
  
  /// Retry count for failed API requests
  static const int maxRetryCount = 3;
  
  /// Delay between retries in milliseconds
  static const int retryDelayMs = 1000;
  
  // ========== BULK OPERATION CONSTANTS ==========
  
  /// Maximum number of mails that can be bulk processed at once
  static const int maxBulkOperationSize = 100;
  
  /// Batch size for sequential bulk operations
  static const int bulkOperationBatchSize = 10;
  
  /// Delay between bulk operation batches in milliseconds
  static const int bulkOperationDelayMs = 500;
  
  // ========== UI CONSTANTS ==========
  
  /// Debounce delay for search input in milliseconds
  static const int searchDebounceMs = 300;
  
  /// Auto-refresh interval in minutes (0 = disabled)
  static const int autoRefreshMinutes = 0;
  
  /// Maximum search query length
  static const int maxSearchQueryLength = 500;
  
  // ========== ERROR MESSAGES ==========
  
  static const String noUserEmailError = 'User email not available';
  static const String loadMoreFailedError = 'Failed to load more mails';
  static const String nextPageFailedError = 'Failed to load next page';
  static const String previousPageFailedError = 'Failed to load previous page';
  static const String bulkOperationFailedError = 'Bulk operation failed';
  static const String networkError = 'Network connection error';
  static const String unknownError = 'An unknown error occurred';
  
  // ========== SUCCESS MESSAGES ==========
  
  static const String mailMovedToTrashSuccess = 'Mail moved to trash';
  static const String mailArchivedSuccess = 'Mail archived';
  static const String mailMarkedReadSuccess = 'Mail marked as read';
  static const String mailMarkedUnreadSuccess = 'Mail marked as unread';
  static const String mailStarredSuccess = 'Mail starred';
  static const String mailUnstarredSuccess = 'Mail unstarred';
  
  // ========== VALIDATION CONSTANTS ==========
  
  /// Minimum length for search query
  static const int minSearchQueryLength = 2;
  
  /// Maximum number of selected mails for bulk operations
  static const int maxSelectedMails = 100;
  
  // ========== LOGGING CONSTANTS ==========
  
  /// Enable debug logging
  static const bool enableDebugLogging = true;
  
  /// Log level for mail operations
  static const String logLevel = 'INFO';
}

/// Mail folder configuration and labels
class MailFolderConfig {
  // Prevent instantiation
  MailFolderConfig._();
  
  /// Get API labels for folder
  static List<String>? getLabelsForFolder(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return ['INBOX'];
      case MailFolder.sent:
        return ['SENT'];
      case MailFolder.drafts:
        return ['DRAFT'];
      case MailFolder.spam:
        return ['SPAM'];
      case MailFolder.starred:
        return ['STARRED'];
      case MailFolder.trash:
        return ['TRASH'];
      case MailFolder.important:
        return null; // Uses query instead
      default:
        return null;
    }
  }
  
  /// Get API query for folder
  static String? getQueryForFolder(MailFolder folder) {
    switch (folder) {
      case MailFolder.important:
        return 'is:important';
      default:
        return null;
    }
  }
  
  /// Get icon name for folder
  static String getIconForFolder(MailFolder folder) {
    switch (folder.baseFolder) {
      case MailFolder.inbox:
        return 'inbox';
      case MailFolder.sent:
        return 'send';
      case MailFolder.drafts:
        return 'draft';
      case MailFolder.spam:
        return 'report';
      case MailFolder.trash:
        return 'delete';
      case MailFolder.starred:
        return 'star';
      case MailFolder.important:
        return 'priority_high';
      default:
        return 'folder';
    }
  }
  
  /// Get color for folder
  static String getColorForFolder(MailFolder folder) {
    switch (folder.baseFolder) {
      case MailFolder.inbox:
        return '#1976D2'; // Blue
      case MailFolder.sent:
        return '#388E3C'; // Green
      case MailFolder.drafts:
        return '#F57C00'; // Orange
      case MailFolder.spam:
        return '#D32F2F'; // Red
      case MailFolder.trash:
        return '#616161'; // Grey
      case MailFolder.starred:
        return '#FBC02D'; // Yellow
      case MailFolder.important:
        return '#7B1FA2'; // Purple
      default:
        return '#424242'; // Dark Grey
    }
  }
}

/// Performance and optimization settings
class MailPerformanceConfig {
  // Prevent instantiation
  MailPerformanceConfig._();
  
  /// Enable memory optimization
  static const bool enableMemoryOptimization = true;
  
  /// Enable context cleanup
  static const bool enableContextCleanup = true;
  
  /// Cleanup interval in minutes
  static const int cleanupIntervalMinutes = 10;
  
  /// Enable optimistic UI updates
  static const bool enableOptimisticUpdates = true;
  
  /// Enable background refresh
  static const bool enableBackgroundRefresh = false;
  
  /// Maximum concurrent API requests
  static const int maxConcurrentRequests = 3;
}