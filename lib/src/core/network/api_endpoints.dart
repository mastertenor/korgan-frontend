// lib/src/core/network/api_endpoints.dart

/// Centralized API endpoint management with Gmail filtering support
///
/// This class contains all API endpoints and provides utility methods
/// for building URLs with query parameters including new Gmail filtering features.
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  /// Base API URL - can be changed based on environment
  static const String baseUrl = 'https://3327faf71cfc.ngrok-free.app/api';

  // ========== Gmail API Endpoints ==========

  /// Gmail queue endpoint - single endpoint for all operations
  static const String gmailQueue = '/api/gmail/queue';

  // ========== Gmail Operations ==========

  /// Available Gmail operations
  static const String listOperation = 'list';
  static const String readOperation = 'read';
  static const String deleteOperation = 'delete';
  static const String archiveOperation = 'archive';
  static const String starOperation = 'star';
  static const String unstarOperation = 'unstar';
  static const String markReadOperation = 'markRead';
  static const String markUnreadOperation = 'markUnread';

  // Trash operations
  static const String trashOperation = 'archive';
  static const String restoreOperation = 'restore';
  static const String emptyTrashOperation = 'empty';
  static const String listTrashOperation = 'listTrash';

  // ========== 🆕 Gmail Labels ==========

  /// Common Gmail labels for filtering
  static const String labelInbox = 'INBOX';
  static const String labelSent = 'SENT';
  static const String labelDraft = 'DRAFT';
  static const String labelUnread = 'UNREAD';
  static const String labelImportant = 'IMPORTANT';
  static const String labelStarred = 'STARRED';
  static const String labelSpam = 'SPAM';
  static const String labelTrash = 'TRASH';
  static const String labelCategoryPersonal = 'CATEGORY_PERSONAL';
  static const String labelCategorySocial = 'CATEGORY_SOCIAL';
  static const String labelCategoryPromotions = 'CATEGORY_PROMOTIONS';
  static const String labelCategoryUpdates = 'CATEGORY_UPDATES';
  static const String labelCategoryForums = 'CATEGORY_FORUMS';

  // ========== URL Builder Methods ==========

  /// Build Gmail queue URL with operation and email (ORIGINAL METHOD - UNCHANGED)
  ///
  /// Example: `/gmail/queue?operation=list&email=user@example.com&maxResults=20`
  static String buildGmailQueueUrl({
    required String operation,
    required String email,
    int? maxResults,
    String? pageToken,
    String? query,
  }) {
    final Map<String, dynamic> params = {
      'operation': operation,
      'email': email,
    };

    // Add optional parameters
    if (maxResults != null) {
      params['maxResults'] = maxResults.toString();
    }

    if (pageToken != null && pageToken.isNotEmpty) {
      params['pageToken'] = pageToken;
    }

    if (query != null && query.isNotEmpty) {
      params['query'] = query;
    }

    return '$gmailQueue?${_buildQueryString(params)}';
  }

  /// 🆕 Build Gmail queue URL with label filtering support
  ///
  /// Enhanced version that supports new filtering features:
  /// - labels: Space-separated label list
  /// - query: Gmail query string (overrides other filters)
  ///
  /// Examples:
  /// - INBOX only: `labels: 'INBOX'`
  /// - Unread in INBOX: `labels: 'INBOX UNREAD'`
  /// - Custom query: `query: 'is:unread has:attachment'`
  static String buildGmailQueueUrlWithFilters({
    required String operation,
    String? email,
    String? userEmail,
    int? maxResults,
    String? pageToken,
    List<String>? labels,
    String? query,
  }) {
    final Map<String, dynamic> params = {'operation': operation};

    // Add email parameter if provided (for backward compatibility)
    if (email != null && email.isNotEmpty) {
      params['email'] = email;
    }

    // Add userEmail parameter for queue tracking
    if (userEmail != null && userEmail.isNotEmpty) {
      params['userEmail'] = userEmail;
    }

    // Add optional parameters
    if (maxResults != null) {
      params['maxResults'] = maxResults.toString();
    }

    if (pageToken != null && pageToken.isNotEmpty) {
      params['pageToken'] = pageToken;
    }

    // 🆕 New filtering parameters
    if (query != null && query.isNotEmpty) {
      // Query overrides other filters according to backend documentation
      params['query'] = query;
    } else if (labels != null && labels.isNotEmpty) {
      // Space-separated labels
      params['labels'] = labels.join(' ');
    }

    return '$gmailQueue?${_buildQueryString(params)}';
  }

  /// Build Gmail action URL for specific email operations (using single queue endpoint)
  ///
  /// Example: `/api/gmail/queue?operation=markRead&messageId=123&email=user@example.com`
  static String buildGmailActionUrl({
    required String operation,
    required String emailId,
    required String email,
    Map<String, dynamic>? additionalParams,
  }) {
    final Map<String, dynamic> params = {
      'operation': operation,
      'messageId': emailId,
      'email': email,
    };

    // Add additional parameters if provided
    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    return '$gmailQueue?${_buildQueryString(params)}';
  }

  /// Build Gmail trash URL for trash operations (UNCHANGED)
  static String buildGmailTrashUrl({
    required String operation,
    required String email,
    String? emailId,
    int? maxResults,
    String? pageToken,
  }) {
    final Map<String, dynamic> params = {
      'operation': operation,
      'email': email,
    };

    // Add messageId for specific email operations
    if (emailId != null && emailId.isNotEmpty) {
      params['messageId'] = emailId;
    }

    // Add optional parameters for list operations
    if (maxResults != null) {
      params['maxResults'] = maxResults.toString();
    }

    if (pageToken != null && pageToken.isNotEmpty) {
      params['pageToken'] = pageToken;
    }

    return '$gmailQueue?${_buildQueryString(params)}';
  }

  // ========== Utility Methods (UNCHANGED) ==========

  /// Build query string from parameters map
  static String _buildQueryString(Map<String, dynamic> params) {
    final List<String> queryParts = [];

    params.forEach((key, value) {
      if (value != null) {
        queryParts.add(
          '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}',
        );
      }
    });

    return queryParts.join('&');
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Get full URL by combining base URL with endpoint
  static String getFullUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint; // Already a full URL
    }

    return '$baseUrl$endpoint';
  }

  // ========== Environment-based Configuration (UNCHANGED) ==========

  /// Update base URL for different environments
  static String _currentBaseUrl = baseUrl;

  static String get currentBaseUrl => _currentBaseUrl;

  static void setBaseUrl(String newBaseUrl) {
    _currentBaseUrl = newBaseUrl.endsWith('/')
        ? newBaseUrl.substring(0, newBaseUrl.length - 1)
        : newBaseUrl;
  }

  /// Environment-specific URLs
  static void setDevelopmentMode() {
    setBaseUrl('http://192.168.0.23:3000/api');
  }

  static void setStagingMode() {
    setBaseUrl('https://staging-api.yourapp.com/api');
  }

  static void setProductionMode() {
    setBaseUrl('https://api.yourapp.com/api');
  }
}

/// Helper class for building common Gmail queries
///
/// Provides pre-built query strings and utility methods for constructing
/// Gmail search queries that can be used with the filtering API.
class GmailQueries {
  const GmailQueries._();

  /// Unread emails in INBOX
  static const String unreadInbox = 'label:INBOX is:unread';

  /// Important emails
  static const String important = 'is:important';

  /// Starred emails
  static const String starred = 'is:starred';

  /// Emails with attachments
  static const String hasAttachment = 'has:attachment';

  /// Emails from specific sender
  static String fromSender(String email) => 'from:$email';

  /// Emails to specific recipient
  static String toRecipient(String email) => 'to:$email';

  /// Emails with specific subject
  static String withSubject(String subject) => 'subject:"$subject"';

  /// Emails newer than specified days
  static String newerThan(int days) => 'newer:${days}d';

  /// Emails older than specified days
  static String olderThan(int days) => 'older:${days}d';

  /// Emails larger than specified size (in MB)
  static String largerThan(int sizeMB) => 'larger:${sizeMB}M';

  /// Emails smaller than specified size (in MB)
  static String smallerThan(int sizeMB) => 'smaller:${sizeMB}M';

  /// Combine multiple queries with AND
  static String combineAnd(List<String> queries) => queries.join(' ');

  /// Combine multiple queries with OR
  static String combineOr(List<String> queries) => '(${queries.join(' OR ')})';
}
