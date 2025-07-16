// lib/src/features/mail/data/datasources/mail_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart' hide ServerException;
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/mail_response_model.dart';
import '../models/mail_model.dart';
import '../models/mail_detail_model.dart';
import 'dart:typed_data';

/// Abstract interface for mail remote data source with enhanced filtering support
abstract class MailRemoteDataSource {
  /// Get list of emails (ORIGINAL METHOD - UNCHANGED)
  Future<MailResponseModel> getMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
    bool includeDeleted = false,
  });

  /// 🆕 Get list of emails with enhanced filtering support
  Future<MailResponseModel> getMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    List<String>? labels,
    String? query,
  });

  /// 🆕 Get detailed mail information by ID
  Future<MailDetailModel> getMailDetail({
    required String id,
    required String email,
  });

  /// Get list of emails in trash (UNCHANGED)
  Future<MailResponseModel> getTrashMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
  });

  Future<Uint8List> downloadAttachment({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
    String? mimeType,
  });

  /// Get single email by ID (UNCHANGED)
  Future<MailModel> getMailById({required String id, required String email});

  /// Mark email as read (UNCHANGED)
  Future<void> markAsRead({required String id, required String email});

  /// Mark email as unread (UNCHANGED)
  Future<void> markAsUnread({required String id, required String email});

  /// Move email to trash (soft delete) (UNCHANGED)
  Future<void> moveToTrash({required String id, required String email});

  /// Restore email from trash (UNCHANGED)
  Future<void> restoreFromTrash({required String id, required String email});

  /// Permanently delete email (hard delete) (UNCHANGED)
  Future<void> deleteMail({required String id, required String email});

  /// Empty trash (permanently delete all emails in trash) (UNCHANGED)
  Future<void> emptyTrash({required String email});

  /// Archive email (UNCHANGED)
  Future<void> archiveMail({required String id, required String email});

  /// Star email (UNCHANGED)
  Future<void> starMail({required String id, required String email});

  /// Unstar email (UNCHANGED)
  Future<void> unstarMail({required String id, required String email});
}

/// Implementation of mail remote data source with enhanced filtering support
class MailRemoteDataSourceImpl implements MailRemoteDataSource {
  final ApiClient _apiClient;

  MailRemoteDataSourceImpl(this._apiClient);

  // ========== ORIGINAL METHODS (UNCHANGED) ==========

  // 🆕 Download attachment implementation - BUNU EKLEYİN
  @override
  Future<Uint8List> downloadAttachment({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
    String? mimeType,
  }) async {
    try {
      // Debug log to track the download request
      print('📎 Downloading attachment:');
      print('  messageId: $messageId');
      print('  attachmentId: $attachmentId');
      print('  filename: $filename');
      print('  email: $email');

      // Build URL matching your backend's getfile operation
      final url =
          '${ApiEndpoints.gmailQueue}?operation=getfile'
          '&messageId=${Uri.encodeComponent(messageId)}'
          '&attachmentId=${Uri.encodeComponent(attachmentId)}'
          '&filename=${Uri.encodeComponent(filename)}'
          '&email=${Uri.encodeComponent(email)}'
          '${mimeType != null ? '&mimeType=${Uri.encodeComponent(mimeType)}' : ''}';

      print('📎 Request URL: $url');

      // Make the API call with binary response type
      final response = await _apiClient.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );

      print('📎 Response status: ${response.statusCode}');
      print('📎 Response data length: ${response.data?.length ?? 0}');

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data);
      } else {
        throw ServerException.internalError(
          message: 'Attachment download failed: Invalid response',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'downloadAttachment');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to download attachment: ${e.toString()}',
      );
    }
  }

  @override
  Future<MailResponseModel> getMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
    bool includeDeleted = false,
  }) async {
    try {
      final url = ApiEndpoints.buildGmailQueueUrl(
        operation: ApiEndpoints.listOperation,
        email: email,
        maxResults: maxResults,
        pageToken: pageToken,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return MailResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ServerException.internalError(
          message: 'Invalid response from server',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'getMails');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to get mails: ${e.toString()}',
      );
    }
  }

  // ========== 🆕 ENHANCED METHODS WITH FILTERING SUPPORT ==========

  @override
  Future<MailResponseModel> getMailsWithFilters({
    String? email,
    String? userEmail,
    int maxResults = 20,
    String? pageToken,
    List<String>? labels,
    String? query,
  }) async {
    try {
      final url = ApiEndpoints.buildGmailQueueUrlWithFilters(
        operation: ApiEndpoints.listOperation,
        email: email,
        userEmail: userEmail,
        maxResults: maxResults,
        pageToken: pageToken,
        labels: labels,
        query: query,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return MailResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ServerException.internalError(
          message: 'Invalid response from server',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'getMailsWithFilters');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to get filtered mails: ${e.toString()}',
      );
    }
  }

  // ========== 🆕 MAIL DETAIL METHODS ==========

  @override
  Future<MailDetailModel> getMailDetail({
    required String id,
    required String email,
  }) async {
    try {
      final url = ApiEndpoints.buildGmailDetailUrl(emailId: id, email: email);

      final response = await _apiClient.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return MailDetailModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException.notFound(
          message: 'Mail detail not found',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'getMailDetail');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to get mail detail: ${e.toString()}',
      );
    }
  }

  // ========== ORIGINAL METHODS CONTINUE (UNCHANGED) ==========

  @override
  Future<MailResponseModel> getTrashMails({
    required String email,
    int maxResults = 20,
    String? pageToken,
  }) async {
    try {
      final url = ApiEndpoints.buildGmailQueueUrl(
        operation: ApiEndpoints.listTrashOperation,
        email: email,
        maxResults: maxResults,
        pageToken: pageToken,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return MailResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ServerException.internalError(
          message: 'Invalid response from server',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'getTrashMails');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to get trash mails: ${e.toString()}',
      );
    }
  }

  @override
  Future<MailModel> getMailById({
    required String id,
    required String email,
  }) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: 'get',
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return MailModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException.notFound(
          message: 'Email not found',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'getMailById');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to get mail: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markAsRead({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.markReadOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to mark email as read',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'markAsRead');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to mark as read: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markAsUnread({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.markUnreadOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to mark email as unread',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'markAsUnread');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to mark as unread: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> moveToTrash({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.trashOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to move email to trash',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'moveToTrash');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to move to trash: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> restoreFromTrash({
    required String id,
    required String email,
  }) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.restoreOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to restore email from trash',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'restoreFromTrash');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to restore from trash: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteMail({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.deleteOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to permanently delete email',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'deleteMail');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to permanently delete mail: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> emptyTrash({required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailQueueUrl(
        operation: ApiEndpoints.emptyTrashOperation,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to empty trash',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'emptyTrash');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to empty trash: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> archiveMail({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.archiveOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to archive email',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'archiveMail');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to archive mail: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> starMail({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.starOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to star email',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'starMail');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to star mail: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> unstarMail({required String id, required String email}) async {
    try {
      final url = ApiEndpoints.buildGmailActionUrl(
        operation: ApiEndpoints.unstarOperation,
        emailId: id,
        email: email,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException.internalError(
          message: 'Failed to unstar email',
          endpoint: url,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'unstarMail');
    } catch (e) {
      throw ServerException.internalError(
        message: 'Failed to unstar mail: ${e.toString()}',
      );
    }
  }

  /// Handle Dio exceptions and convert to appropriate ServerExceptions
  ServerException _handleDioException(
    DioException dioException,
    String operation,
  ) {
    final statusCode = dioException.response?.statusCode ?? 0;
    final message =
        dioException.response?.data?['message'] ?? dioException.message;
    final endpoint = dioException.requestOptions.path;

    switch (statusCode) {
      case 400:
        return ServerException.badRequest(
          message: 'Invalid request for $operation: $message',
          endpoint: endpoint,
          originalException: dioException,
        );
      case 401:
        return ServerException.unauthorized(
          message: 'Unauthorized access for $operation',
          endpoint: endpoint,
          originalException: dioException,
        );
      case 403:
        return ServerException.forbidden(
          message: 'Access forbidden for $operation',
          endpoint: endpoint,
          originalException: dioException,
        );
      case 404:
        return ServerException.notFound(
          message: 'Resource not found for $operation',
          endpoint: endpoint,
          originalException: dioException,
        );
      case 422:
        return ServerException.validationError(
          message: 'Validation failed for $operation: $message',
          endpoint: endpoint,
          originalException: dioException,
        );
      case 429:
        return ServerException.rateLimited(
          message: 'Rate limit exceeded for $operation',
          endpoint: endpoint,
          originalException: dioException,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException.internalError(
          message: 'Server error for $operation: $message',
          endpoint: endpoint,
          originalException: dioException,
        );
      default:
        // Handle network errors
        switch (dioException.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            return ServerException(
              statusCode: 408,
              message: 'Request timeout for $operation',
              endpoint: endpoint,
              code: 'TIMEOUT',
              originalException: dioException,
            );
          case DioExceptionType.connectionError:
            return ServerException(
              statusCode: 0,
              message: 'Connection error for $operation',
              endpoint: endpoint,
              code: 'CONNECTION_ERROR',
              originalException: dioException,
            );
          default:
            return ServerException.internalError(
              message: 'Unknown error for $operation: $message',
              endpoint: endpoint,
              originalException: dioException,
            );
        }
    }
  }
}
