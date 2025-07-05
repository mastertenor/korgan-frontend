// lib/src/features/mail/domain/repositories/mail_repository.dart

import '../../../../core/utils/result.dart';
import '../entities/mail.dart';
import '../entities/paginated_result.dart';

/// Repository interface for mail operations
///
/// This abstract class defines the contract for mail data operations.
/// It represents the boundary between the domain and data layers,
/// ensuring the domain layer is independent of data sources.
abstract class MailRepository {
  /// Get list of emails - Gmail mobile style with pagination
  ///
  /// [email] - User's email address
  /// [maxResults] - Maximum number of emails to fetch (default: 20)
  /// [pageToken] - Token for pagination (null for refresh, token for load more)
  /// [includeDeleted] - Whether to include deleted emails (default: false)
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> getMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
    bool includeDeleted = false,
  });

  /// Refresh mails (pull to refresh) - gets latest emails
  ///
  /// [email] - User's email address
  /// [maxResults] - Maximum number of emails to fetch (default: 20)
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> refreshMails({
    required String email,
    int maxResults = 20,
  }) async {
    return await getMails(
      email: email,
      maxResults: maxResults,
      pageToken: null, // No token = fresh data
    );
  }

  /// Load more mails (infinite scroll) - gets older emails
  ///
  /// [email] - User's email address
  /// [pageToken] - Current page token for loading older emails
  /// [maxResults] - Maximum number of emails to fetch (default: 20)
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> loadMoreMails({
    required String email,
    required String pageToken,
    int maxResults = 20,
  }) async {
    return await getMails(
      email: email,
      maxResults: maxResults,
      pageToken: pageToken,
    );
  }

  /// Get list of emails in trash
  ///
  /// [email] - User's email address
  /// [maxResults] - Maximum number of emails to fetch (default: 20)
  /// [pageToken] - Token for pagination (optional)
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> getTrashMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
  });

  /// Get a single email by ID
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either a Mail entity or a Failure
  Future<Result<Mail>> getMailById({required String id, required String email});

  /// Mark email as read
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> markAsRead({required String id, required String email});

  /// Mark email as unread
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> markAsUnread({
    required String id,
    required String email,
  });

  /// Move email to trash (soft delete)
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> moveToTrash({required String id, required String email});

  /// Restore email from trash
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> restoreFromTrash({
    required String id,
    required String email,
  });

  /// Permanently delete an email (hard delete)
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> deleteMail({required String id, required String email});

  /// Empty trash (permanently delete all emails in trash)
  ///
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> emptyTrash({required String email});

  /// Archive an email
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> archiveMail({required String id, required String email});

  /// Star an email
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> starMail({required String id, required String email});

  /// Remove star from an email
  ///
  /// [id] - Email message ID
  /// [email] - User's email address
  ///
  /// Returns a Result containing either void (success) or a Failure
  Future<Result<void>> unstarMail({required String id, required String email});
}
