// lib/src/features/mail/domain/usecases/get_trash_mails_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../entities/mail.dart';
import '../entities/paginated_result.dart';
import '../repositories/mail_repository.dart';

/// Use case for getting list of emails in trash with pagination
///
/// This use case encapsulates the business logic for fetching deleted emails.
/// It validates input parameters and coordinates with the repository.
class GetTrashMailsUseCase {
  final MailRepository _repository;

  GetTrashMailsUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] - Parameters for getting trash emails
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> call(GetTrashMailsParams params) async {
    // Validate email format
    if (!_isValidEmail(params.email)) {
      return Failure(
        failures.ValidationFailure.invalidEmail(email: params.email),
      );
    }

    // Validate max results
    if (params.maxResults <= 0 || params.maxResults > 100) {
      return Failure(
        failures.ValidationFailure(
          message: 'Maksimum sonuç sayısı 1-100 arasında olmalıdır',
          code: 'INVALID_MAX_RESULTS',
        ),
      );
    }

    // Call repository
    return await _repository.getTrashMails(
      email: params.email,
      maxResults: params.maxResults,
      pageToken: params.pageToken,
    );
  }

  /// Refresh trash mails (pull to refresh)
  ///
  /// [params] - Parameters for refreshing trash emails
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> refresh(
    GetTrashMailsParams params,
  ) async {
    // Create refresh params (no page token)
    final refreshParams = GetTrashMailsParams(
      email: params.email,
      maxResults: params.maxResults,
      pageToken: null, // No token for refresh
    );

    return await call(refreshParams);
  }

  /// Load more trash mails (infinite scroll)
  ///
  /// [params] - Parameters for loading more trash emails
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> loadMore(
    GetTrashMailsParams params,
  ) async {
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

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }
}

/// Parameters for GetTrashMailsUseCase
class GetTrashMailsParams {
  final String email;
  final int maxResults;
  final String? pageToken;

  const GetTrashMailsParams({
    required this.email,
    this.maxResults = 20,
    this.pageToken,
  });

  /// Create params for refresh (no page token)
  factory GetTrashMailsParams.refresh({
    required String email,
    int maxResults = 20,
  }) {
    return GetTrashMailsParams(
      email: email,
      maxResults: maxResults,
      pageToken: null,
    );
  }

  /// Create params for load more
  factory GetTrashMailsParams.loadMore({
    required String email,
    required String pageToken,
    int maxResults = 20,
  }) {
    return GetTrashMailsParams(
      email: email,
      maxResults: maxResults,
      pageToken: pageToken,
    );
  }

  /// Check if this is a refresh request
  bool get isRefresh => pageToken == null;

  /// Check if this is a load more request
  bool get isLoadMore => pageToken != null;

  @override
  String toString() {
    return 'GetTrashMailsParams(email: $email, maxResults: $maxResults, pageToken: $pageToken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetTrashMailsParams &&
        other.email == email &&
        other.maxResults == maxResults &&
        other.pageToken == pageToken;
  }

  @override
  int get hashCode => Object.hash(email, maxResults, pageToken);
}
