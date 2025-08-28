// lib/src/features/mail/domain/usecases/get_mails_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../core/network/api_endpoints.dart';
import '../entities/mail.dart';
import '../entities/paginated_result.dart';
import '../repositories/mail_repository.dart';

/// Use case for getting list of emails with pagination and filtering support
///
/// Enhanced version that supports Gmail API filtering features:
/// - Label-based filtering (INBOX, UNREAD, IMPORTANT, etc.)
/// - Gmail query string support
/// - Backward compatibility with existing functionality
class GetMailsUseCase {
  final MailRepository _repository;

  GetMailsUseCase(this._repository);

  /// Execute the use case with enhanced filtering support
  ///
  /// [params] - Parameters for getting emails with optional filtering
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> call(GetMailsParams params) async {
    // Validate parameters
    final validation = _validateParams(params);
    if (validation != null) {
      return Failure(validation);
    }

    // Call repository with enhanced parameters
    return await _repository.getMailsWithFilters(
      email: params.email,
      userEmail: params.userEmail,
      maxResults: params.maxResults,
      pageToken: params.pageToken,
      labels: params.labels,
      query: params.query,
      enableHighlight: params.enableHighlight, // 🆕 HIGHLIGHT PARAMETER
    );
  }

  /// Refresh mails (pull to refresh) with optional filtering
  ///
  /// [params] - Parameters for refreshing emails
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> refresh(GetMailsParams params) async {
    // Create refresh params (no page token)
    final refreshParams = params.copyWith(pageToken: null);
    return await call(refreshParams);
  }

  /// Load more mails (infinite scroll) with current filters
  ///
  /// [params] - Parameters for loading more emails
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> loadMore(GetMailsParams params) async {
    // Validate that pageToken is provided for load more
    if (params.pageToken == null || params.pageToken!.isEmpty) {
      return Failure(
        failures.ValidationFailure(
          message: 'Daha fazla yüklemek için sayfa token\'ı gerekli',
          code: 'MISSING_PAGE_TOKEN',
        ),
      );
    }

    return await call(params);
  }

  /// 🆕 Get INBOX mails (convenience method)
  Future<Result<PaginatedResult<Mail>>> getInboxMails({
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
  }) async {
    final params = GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: [ApiEndpoints.labelInbox],
    );
    return await call(params);
  }

  /// 🆕 Get unread mails in INBOX (convenience method)
  Future<Result<PaginatedResult<Mail>>> getUnreadInboxMails({
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
  }) async {
    final params = GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: [ApiEndpoints.labelInbox, ApiEndpoints.labelUnread],
    );
    return await call(params);
  }

  /// 🆕 Get starred mails (convenience method)
  Future<Result<PaginatedResult<Mail>>> getStarredMails({
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
  }) async {
    final params = GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: [ApiEndpoints.labelStarred],
    );
    return await call(params);
  }

  /// 🆕 Get mails with custom query (convenience method)
  Future<Result<PaginatedResult<Mail>>> getMailsWithQuery({
    required String query,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  }) async {
    final params = GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      query: query,
      enableHighlight: enableHighlight,
    );
    return await call(params);
  }

  /// Validate parameters
  failures.Failure? _validateParams(GetMailsParams params) {
    // Validate email format if provided
    if (params.email != null && !_isValidEmail(params.email!)) {
      return failures.ValidationFailure.invalidEmail(email: params.email!);
    }

    // Validate userEmail format if provided
    if (params.userEmail != null && !_isValidEmail(params.userEmail!)) {
      return failures.ValidationFailure.invalidEmail(email: params.userEmail!);
    }

    // Validate max results
    if (params.maxResults <= 0 || params.maxResults > 100) {
      return failures.ValidationFailure(
        message: 'Maksimum sonuç sayısı 1-100 arasında olmalıdır',
        code: 'INVALID_MAX_RESULTS',
      );
    }

    // At least one of email, userEmail, labels, or query must be provided
    if (params.email == null &&
        params.userEmail == null &&
        (params.labels == null || params.labels!.isEmpty) &&
        (params.query == null || params.query!.isEmpty)) {
      return failures.ValidationFailure(
        message:
            'En az bir filtre parametresi gerekli (email, userEmail, labels veya query)',
        code: 'MISSING_FILTER_PARAMS',
      );
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }
}

/// Enhanced parameters for GetMailsUseCase with filtering support
class GetMailsParams {
  final String? email; // For backward compatibility
  final String? userEmail; // 🆕 For queue tracking
  final int maxResults;
  final String? pageToken;
  final List<String>? labels; // 🆕 Gmail labels for filtering
  final String? query; // 🆕 Gmail query string
  final bool enableHighlight; // 🆕 HIGHLIGHT PARAMETER

  const GetMailsParams({
    this.email,
    this.userEmail,
    this.maxResults = 20,
    this.pageToken,
    this.labels,
    this.query,
    this.enableHighlight = false,
  });

  /// Create params for refresh (no page token)
  factory GetMailsParams.refresh({
    String? email,
    String? userEmail,
    int maxResults = 20,
    List<String>? labels,
    String? query,
    bool enableHighlight = false,
  }) {
    return GetMailsParams(
      email: email,
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: null,
      labels: labels,
      query: query,
      enableHighlight: enableHighlight,
    );
  }

  /// Create params for load more
  factory GetMailsParams.loadMore({
    String? email,
    String? userEmail,
    required String pageToken,
    int maxResults = 20,
    List<String>? labels,
    String? query,
    bool enableHighlight = false,
  }) {
    return GetMailsParams(
      email: email,
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: labels,
      query: query,
      enableHighlight: enableHighlight,
    );
  }

  /// 🆕 Create params for INBOX filtering
  factory GetMailsParams.inbox({
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
  }) {
    return GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: [ApiEndpoints.labelInbox],
    );
  }

  /// 🆕 Create params for unread INBOX filtering
  factory GetMailsParams.unreadInbox({
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
  }) {
    return GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: [ApiEndpoints.labelInbox, ApiEndpoints.labelUnread],
    );
  }

  /// 🆕 Create params with custom query
  factory GetMailsParams.withQuery({
    required String query,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    bool enableHighlight = false,
  }) {
    return GetMailsParams(
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      query: query,
      enableHighlight: enableHighlight,
    );
  }

  /// Check if this is a refresh request
  bool get isRefresh => pageToken == null;

  /// Check if this is a load more request
  bool get isLoadMore => pageToken != null;

  /// Check if filtering is enabled
  bool get hasFilters =>
      (labels != null && labels!.isNotEmpty) ||
      (query != null && query!.isNotEmpty);

  /// Copy with method for immutable updates
  GetMailsParams copyWith({
    String? email,
    String? userEmail,
    int? maxResults,
    String? pageToken,
    List<String>? labels,
    String? query,
    bool? enableHighlight,
  }) {
    return GetMailsParams(
      email: email ?? this.email,
      userEmail: userEmail ?? this.userEmail,
      maxResults: maxResults ?? this.maxResults,
      pageToken: pageToken, // Always override pageToken
      labels: labels ?? this.labels,
      query: query ?? this.query,
      enableHighlight: enableHighlight ?? this.enableHighlight,
    );
  }

  @override
  String toString() {
    return 'GetMailsParams(email: $email, userEmail: $userEmail, maxResults: $maxResults, pageToken: $pageToken, labels: $labels, query: $query, enableHighlight: $enableHighlight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMailsParams &&
        other.email == email &&
        other.userEmail == userEmail &&
        other.maxResults == maxResults &&
        other.pageToken == pageToken &&
        _listEquals(other.labels, labels) &&
        other.query == query &&
        other.enableHighlight == enableHighlight;
  }

  @override
  int get hashCode =>
      Object.hash(email, userEmail, maxResults, pageToken, labels, query, enableHighlight);

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}