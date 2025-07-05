// lib/src/core/network/api_endpoints.dart

/// Centralized API endpoint management
///
/// This class contains all API endpoints and provides utility methods
/// for building URLs with query parameters. It helps maintain consistency
/// and makes it easy to update endpoints when needed.
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  /// Base API URL - can be changed based on environment
  static const String baseUrl = 'https://60ad-94-55-176-45.ngrok-free.app/api';

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
  static const String trashOperation = 'trash';
  static const String restoreOperation = 'restore';
  static const String emptyTrashOperation = 'empty';
  static const String listTrashOperation =
      'listTrash'; // For listing trash emails

  // ========== URL Builder Methods ==========

  /// Build Gmail queue URL with operation and email
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

  /// Build Gmail trash URL for trash operations
  /// All operations use the same /api/gmail/queue endpoint with different operation parameters
  ///
  /// Examples:
  /// - List trash: `/api/gmail/queue?operation=listTrash&email=user@example.com`
  /// - Move to trash: `/api/gmail/queue?operation=trash&messageId=123&email=user@example.com`
  /// - Restore: `/api/gmail/queue?operation=restore&messageId=123&email=user@example.com`
  /// - Empty trash: `/api/gmail/queue?operation=empty&email=user@example.com`
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

  // ========== Utility Methods ==========

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

  // ========== Environment-based Configuration ==========

  /// Update base URL for different environments
  /// This method would be used in main.dart or app initialization
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
