// lib/src/features/mail/domain/repositories/mail_repository.dart

import '../../../../core/utils/result.dart';
import '../entities/mail.dart';
import '../entities/paginated_result.dart';

/// Repository interface for mail operations with enhanced filtering support
///
/// This abstract class defines the contract for mail data operations.
/// Enhanced version includes Gmail API filtering capabilities while
/// maintaining backward compatibility.
abstract class MailRepository {
  /// Get list of emails - Gmail mobile style with pagination (ORIGINAL METHOD - UNCHANGED)
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

  /// 🆕 Get list of emails with enhanced filtering support
  ///
  /// Enhanced version supporting Gmail API filtering features:
  /// - [email] - User's email address (for backward compatibility)
  /// - [userEmail] - User email for queue tracking
  /// - [maxResults] - Maximum number of emails to fetch (default: 20)
  /// - [pageToken] - Token for pagination (null for refresh)
  /// - [labels] - List of Gmail labels for filtering (e.g., ['INBOX', 'UNREAD'])
  /// - [query] - Gmail query string (overrides other filters)
  ///
  /// Examples:
  /// ```dart
  /// // INBOX only
  /// await repository.getMailsWithFilters(labels: ['INBOX']);
  ///
  /// // Unread in INBOX
  /// await repository.getMailsWithFilters(labels: ['INBOX', 'UNREAD']);
  ///
  /// // Custom query
  /// await repository.getMailsWithFilters(query: 'is:unread has:attachment');
  /// ```
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> getMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    List<String>? labels,
    String? query,
  });

  /// Refresh mails (pull to refresh) - gets latest emails (ORIGINAL METHOD - UNCHANGED)
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

  /// Load more mails (infinite scroll) - gets older emails (ORIGINAL METHOD - UNCHANGED)
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

  /// 🆕 Refresh mails with filtering support
  ///
  /// Enhanced refresh method that supports filtering while maintaining
  /// the same refresh semantics (no page token).
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> refreshMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    List<String>? labels,
    String? query,
  }) async {
    return await getMailsWithFilters(
      email: email,
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: null, // No token = fresh data
      labels: labels,
      query: query,
    );
  }

  /// 🆕 Load more mails with filtering support
  ///
  /// Enhanced load more method that supports filtering while maintaining
  /// current filter state.
  ///
  /// Returns a Result containing either a PaginatedResult<Mail> or a Failure
  Future<Result<PaginatedResult<Mail>>> loadMoreMailsWithFilters({
    String? email,
    String? userEmail,
    required String pageToken,
    int maxResults = 20,
    List<String>? labels,
    String? query,
  }) async {
    return await getMailsWithFilters(
      email: email,
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: labels,
      query: query,
    );
  }

  // ========== ORIGINAL METHODS (UNCHANGED) ==========

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
