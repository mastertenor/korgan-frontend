// lib/src/features/mail/data/repositories/mail_repository_impl.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/repositories/mail_repository.dart';
import '../datasources/mail_remote_datasource.dart';
import 'dart:typed_data';
import '../../domain/entities/mail_compose_request.dart';
import '../../domain/entities/compose_result.dart';
import '../models/mail_send_request_model.dart';



/// Implementation of mail repository with enhanced filtering support
///
/// This class coordinates between the data sources and domain layer,
/// converting exceptions to failures and data models to domain entities.
/// Enhanced version includes Gmail API filtering capabilities.
class MailRepositoryImpl implements MailRepository {
  final MailRemoteDataSource _remoteDataSource;

  MailRepositoryImpl(this._remoteDataSource);

  // ========== 🆕 MAIL SEND IMPLEMENTATION ==========

  @override
  Future<Result<ComposeResult>> sendMail(MailComposeRequest request) async {
    try {
      print('📧 Repository: Converting domain request to data model');
      
      // Convert domain entity to data model
      final requestModel = MailSendRequestModel.fromDomain(request);
      
      print('📧 Repository: Calling remote data source');
      
      // Call remote data source
      final responseModel = await _remoteDataSource.sendMail(requestModel);
      
      print('📧 Repository: Converting response to domain entity');
      
      // Convert data model to domain entity
      final composeResult = responseModel.toDomain();
      
      print('📧 Repository: Mail send successful - ${composeResult.requestId}');
      
      return Success(composeResult);
    } on ServerException catch (e) {
      print('📧 Repository: ServerException - ${e.message}');
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      print('📧 Repository: NetworkException - ${e.message}');
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      print('📧 Repository: Unexpected error - ${e.toString()}');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Mail gönderilemedi: ${e.toString()}',
        ),
      );
    }
  }

  // ========== ORIGINAL METHODS (UNCHANGED) ==========

  @override
  Future<Result<Uint8List>> downloadAttachment({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
    String? mimeType,
  }) async {
    try {
      final bytes = await _remoteDataSource.downloadAttachment(
        messageId: messageId,
        attachmentId: attachmentId,
        filename: filename,
        email: email,
        mimeType: mimeType,
      );

      return Success(bytes);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'Attachment download failed: ${e.toString()}',
        ),
      );
    }
  }

  @override
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

  @override
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

  @override
  Future<Result<PaginatedResult<Mail>>> getMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
    bool includeDeleted = false,
  }) async {
    try {
      final response = await _remoteDataSource.getMails(
        email: email,
        maxResults: maxResults,
        pageToken: pageToken,
        includeDeleted: includeDeleted,
      );

      // Convert models to domain entities
      final mails = response.messages.map((model) => model.toDomain()).toList();

      // Create paginated result
      final paginatedResult = PaginatedResult<Mail>(
        items: mails,
        nextPageToken: response.nextPageToken,
        totalEstimate: response.resultSizeEstimate,
        hasMore: response.hasNextPage,
      );

      return Success(paginatedResult);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'Beklenmeyen hata: ${e.toString()}',
        ),
      );
    }
  }

  // ========== 🆕 ENHANCED METHODS WITH FILTERING SUPPORT ==========

  @override
  Future<Result<PaginatedResult<Mail>>> getMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    List<String>? labels,
    String? query,
    bool enableHighlight = false, // 🆕 HIGHLIGHT PARAMETER
  }) async {
    try {
      final response = await _remoteDataSource.getMailsWithFilters(
        email: email,
        userEmail: userEmail,
        maxResults: maxResults,
        pageToken: pageToken,
        labels: labels,
        query: query,
        enableHighlight: enableHighlight, // 🆕 PASS HIGHLIGHT TO DATA SOURCE
      );

      // Convert models to domain entities
      final mails = response.messages.map((model) => model.toDomain()).toList();

      // Create paginated result
      final paginatedResult = PaginatedResult<Mail>(
        items: mails,
        nextPageToken: response.nextPageToken,
        totalEstimate: response.resultSizeEstimate,
        hasMore: response.hasNextPage,
      );

      return Success(paginatedResult);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'Filtrelenmiş e-postalar getirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
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

  @override
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

  // ========== 🆕 MAIL DETAIL METHODS ==========

  @override
Future<Result<MailDetail>> getMailDetail({
    required String id,
    required String email,
    String? searchQuery,
    bool enableHighlight = false,
  }) async {
    try {
      final mailDetailModel = await _remoteDataSource.getMailDetail(
        id: id,
        email: email,
        searchQuery: searchQuery,
        enableHighlight: enableHighlight,
      );

      return Success(mailDetailModel.toDomain());
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'E-posta detayı getirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  // ========== ORIGINAL METHODS CONTINUE (UNCHANGED) ==========

  @override
  Future<Result<PaginatedResult<Mail>>> getTrashMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
  }) async {
    try {
      final response = await _remoteDataSource.getTrashMails(
        email: email,
        maxResults: maxResults,
        pageToken: pageToken,
      );

      // Convert models to domain entities
      final mails = response.messages.map((model) => model.toDomain()).toList();

      // Create paginated result
      final paginatedResult = PaginatedResult<Mail>(
        items: mails,
        nextPageToken: response.nextPageToken,
        totalEstimate: response.resultSizeEstimate,
        hasMore: response.hasNextPage,
      );

      return Success(paginatedResult);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'Çöp kutusu e-postaları getirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<Mail>> getMailById({
    required String id,
    required String email,
  }) async {
    try {
      final mailModel = await _remoteDataSource.getMailById(
        id: id,
        email: email,
      );

      return Success(mailModel.toDomain());
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'E-posta getirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> markAsRead({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.markAsRead(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta okundu olarak işaretlenemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> markAsUnread({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.markAsUnread(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta okunmadı olarak işaretlenemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> moveToTrash({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.moveToTrash(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta çöp kutusuna taşınamadı: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> restoreFromTrash({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.restoreFromTrash(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta çöp kutusundan geri getirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteMail({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.deleteMail(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta kalıcı olarak silinemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> emptyTrash({required String email}) async {
    try {
      await _remoteDataSource.emptyTrash(email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'Çöp kutusu boşaltılamadı: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> archiveMail({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.archiveMail(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(message: 'E-posta arşivlenemedi: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> starMail({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.starMail(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta yıldızlanamadı: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> unstarMail({
    required String id,
    required String email,
  }) async {
    try {
      await _remoteDataSource.unstarMail(id: id, email: email);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.MailFailure(
          message: 'E-posta yıldızı kaldırılamadı: ${e.toString()}',
        ),
      );
    }
  }

  /// Map ServerException to appropriate Failure
  failures.Failure _mapServerExceptionToFailure(ServerException exception) {
    switch (exception.statusCode) {
      case 400:
        return failures.ValidationFailure(
          message: exception.message,
          code: 'INVALID_REQUEST',
        );
      case 401:
        return failures.AuthFailure.tokenExpired();
      case 403:
        return failures.AuthFailure.permissionDenied();
      case 404:
        return failures.MailFailure.notFound('unknown');
      case 422:
        return failures.ValidationFailure(
          message: exception.message,
          code: 'VALIDATION_ERROR',
        );
      case 429:
        return failures.ServerFailure.rateLimited(message: exception.message);
      case 500:
      case 502:
      case 503:
      case 504:
        return failures.ServerFailure.internalError(message: exception.message);
      default:
        return failures.ServerFailure(
          message: exception.message,
          statusCode: exception.statusCode,
        );
    }
  }

  /// Map NetworkException to appropriate Failure
  failures.Failure _mapNetworkExceptionToFailure(NetworkException exception) {
    if (exception.message.toLowerCase().contains('timeout')) {
      return failures.NetworkFailure.connectionTimeout();
    }

    if (exception.message.toLowerCase().contains('connection')) {
      return failures.NetworkFailure.noConnection();
    }

    if (exception.message.toLowerCase().contains('ssl')) {
      return failures.NetworkFailure.sslError();
    }

    return failures.NetworkFailure(message: exception.message);
  }
}