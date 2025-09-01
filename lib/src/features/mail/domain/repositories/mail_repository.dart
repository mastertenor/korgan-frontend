// lib/src/features/mail/domain/repositories/mail_repository.dart

import '../../../../core/utils/result.dart';
import '../entities/mail.dart';
import '../entities/mail_detail.dart';
import '../entities/paginated_result.dart';
import 'dart:typed_data';
import '../entities/mail_compose_request.dart';
import '../entities/compose_result.dart';  


abstract class MailRepository {
  Future<Result<PaginatedResult<Mail>>> getMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
    bool includeDeleted = false,
  });

  Future<Result<PaginatedResult<Mail>>> getMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    List<String>? labels,
    String? query,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  });

Future<Result<MailDetail>> getMailDetail({
    required String id,
    required String email,
    String? searchQuery,
    bool enableHighlight = false,
  });

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

  Future<Result<PaginatedResult<Mail>>> refreshMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    List<String>? labels,
    String? query,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  }) async {
    return await getMailsWithFilters(
      email: email,
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: null, // No token = fresh data
      labels: labels,
      query: query,
      enableHighlight: enableHighlight,
    );
  }

  Future<Result<PaginatedResult<Mail>>> loadMoreMailsWithFilters({
    String? email,
    String? userEmail,
    required String pageToken,
    int maxResults = 20,
    List<String>? labels,
    String? query,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  }) async {
    return await getMailsWithFilters(
      email: email,
      userEmail: userEmail,
      maxResults: maxResults,
      pageToken: pageToken,
      labels: labels,
      query: query,
      enableHighlight: enableHighlight,
    );
  }

  Future<Result<PaginatedResult<Mail>>> getTrashMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
  });

  Future<Result<Mail>> getMailById({required String id, required String email});

  Future<Result<void>> markAsRead({required String id, required String email});

  Future<Result<void>> markAsUnread({
    required String id,
    required String email,
  });

  Future<Result<void>> moveToTrash({required String id, required String email});

  Future<Result<void>> restoreFromTrash({
    required String id,
    required String email,
  });

  Future<Result<void>> deleteMail({required String id, required String email});

  Future<Result<void>> emptyTrash({required String email});

  Future<Result<void>> archiveMail({required String id, required String email});

  Future<Result<void>> starMail({required String id, required String email});

  Future<Result<void>> unstarMail({required String id, required String email});

  Future<Result<ComposeResult>> sendMail(MailComposeRequest request);

  Future<Result<Uint8List>> downloadAttachment({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
    String? mimeType,
  });


}