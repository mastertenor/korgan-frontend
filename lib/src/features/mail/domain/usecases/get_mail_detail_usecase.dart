// lib/src/features/mail/domain/usecases/get_mail_detail_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../entities/mail_detail.dart';
import '../repositories/mail_repository.dart';

/// Use case for getting detailed mail information by ID
///
/// This use case encapsulates the business logic for fetching a specific email's
/// full details including content, labels, and metadata. It validates input
/// parameters and coordinates with the repository.
class GetMailDetailUseCase {
  final MailRepository _repository;

  GetMailDetailUseCase(this._repository);

  /// Execute the use case to get mail detail
  ///
  /// [params] - Parameters containing mail ID and user email
  ///
  /// Returns a Result containing either a MailDetail entity or a Failure
  Future<Result<MailDetail>> call(GetMailDetailParams params) async {
    // Validate parameters
    final validation = _validateParams(params);
    if (validation != null) {
      return Failure(validation);
    }

    // Call repository to get mail detail
    return await _repository.getMailDetail(
      id: params.mailId,
      email: params.email,
      searchQuery: params.searchQuery,
      enableHighlight: params.enableHighlight,
    );
  }

  /// Refresh mail detail (force reload from server)
  ///
  /// [params] - Parameters containing mail ID and user email
  ///
  /// Returns a Result containing either a MailDetail entity or a Failure
  Future<Result<MailDetail>> refresh(GetMailDetailParams params) async {
    // For now, refresh is the same as regular call
    // In the future, we might add cache invalidation here
    return await call(params);
  }

  /// Validate input parameters
  ///
  /// Returns null if validation passes, or a Failure if validation fails
  failures.Failure? _validateParams(GetMailDetailParams params) {
    // Check if mail ID is provided and not empty
    if (params.mailId.isEmpty) {
      return failures.ValidationFailure.requiredField('Mail ID');
    }

    // Check if email is provided and not empty
    if (params.email.isEmpty) {
      return failures.ValidationFailure.requiredField('E-posta adresi');
    }

    // Validate email format
    if (!_isValidEmail(params.email)) {
      return failures.ValidationFailure.invalidEmail(email: params.email);
    }

    // Additional validation for mail ID format (if needed)
    if (!_isValidMailId(params.mailId)) {
      return failures.ValidationFailure(
        message: 'Geçersiz mail ID formatı',
        code: 'INVALID_MAIL_ID',
        details: {'mailId': params.mailId},
      );
    }

    return null; // Validation passed
  }

  /// Validate email format using regex
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validate mail ID format
  ///
  /// Gmail message IDs are typically alphanumeric strings
  /// This is a basic validation - can be enhanced based on actual ID patterns
  bool _isValidMailId(String mailId) {
    // Basic check: not empty, reasonable length, alphanumeric with some symbols
    if (mailId.length < 5 || mailId.length > 100) {
      return false;
    }

    // Allow alphanumeric characters, hyphens, underscores
    return RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(mailId);
  }
}

/// Parameters for GetMailDetailUseCase
class GetMailDetailParams {
  /// Gmail message ID
  final String mailId;

  /// User's email address
  final String email;

  /// Optional: Force refresh from server (bypass cache)
  final bool forceRefresh;

  /// Optional search query for highlighting
  final String? searchQuery;

  /// Whether to enable search result highlighting
  final bool enableHighlight;

  const GetMailDetailParams({
    required this.mailId,
    required this.email,
    this.forceRefresh = false,
    this.searchQuery,
    this.enableHighlight = false,
  });

  /// Create params for refresh operation
  factory GetMailDetailParams.refresh({
    required String mailId,
    required String email,
  }) {
    return GetMailDetailParams(
      mailId: mailId,
      email: email,
      forceRefresh: true,
    );
  }

  /// Create params for search context (with highlighting)
  factory GetMailDetailParams.withSearch({
    required String mailId,
    required String email,
    required String searchQuery,
    bool forceRefresh = false,
  }) {
    return GetMailDetailParams(
      mailId: mailId,
      email: email,
      forceRefresh: forceRefresh,
      searchQuery: searchQuery,
      enableHighlight: true,
    );
  }

  /// Check if this is a refresh request
  bool get isRefresh => forceRefresh;

  /// Check if this has search context
  bool get hasSearchContext => searchQuery != null && searchQuery!.isNotEmpty;

  /// Copy with method for immutable updates
  GetMailDetailParams copyWith({
    String? mailId,
    String? email,
    bool? forceRefresh,
    String? searchQuery,
    bool? enableHighlight,
  }) {
    return GetMailDetailParams(
      mailId: mailId ?? this.mailId,
      email: email ?? this.email,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      searchQuery: searchQuery ?? this.searchQuery,
      enableHighlight: enableHighlight ?? this.enableHighlight,
    );
  }

  @override
  String toString() {
    return 'GetMailDetailParams(mailId: $mailId, email: $email, forceRefresh: $forceRefresh, '
        'searchQuery: $searchQuery, enableHighlight: $enableHighlight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMailDetailParams &&
        other.mailId == mailId &&
        other.email == email &&
        other.forceRefresh == forceRefresh &&
        other.searchQuery == searchQuery &&
        other.enableHighlight == enableHighlight;
  }

  @override
  int get hashCode =>
      Object.hash(mailId, email, forceRefresh, searchQuery, enableHighlight);
}

/// Extension methods for GetMailDetailParams for convenience
extension GetMailDetailParamsExtension on GetMailDetailParams {
  /// Validate this params instance
  bool get isValid {
    return mailId.isNotEmpty &&
        email.isNotEmpty &&
        RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(email);
  }

  /// Get validation error message if params are invalid
  String? get validationError {
    if (mailId.isEmpty) return 'Mail ID gerekli';
    if (email.isEmpty) return 'E-posta adresi gerekli';
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email)) {
      return 'Geçersiz e-posta formatı';
    }
    return null;
  }

  /// Create a sanitized version for logging (hide sensitive data)
  String toSafeString() {
    final maskedEmail = email.length > 3
        ? '${email.substring(0, 3)}***@${email.split('@').last}'
        : '***';

    final maskedMailId = mailId.length > 6
        ? '${mailId.substring(0, 6)}***'
        : '***';

    return 'GetMailDetailParams(mailId: $maskedMailId, email: $maskedEmail, '
        'forceRefresh: $forceRefresh, searchQuery: $searchQuery, enableHighlight: $enableHighlight)';
  }
}
