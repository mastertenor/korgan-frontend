// lib/src/core/network/network_exceptions.dart

import 'package:dio/dio.dart';

/// Network exception handler that provides user-friendly error messages
///
/// This class converts technical Dio exceptions into readable messages
/// that can be displayed to users. It handles various network scenarios
/// and provides appropriate Turkish error messages.
class NetworkExceptions {
  // Private constructor to prevent instantiation
  NetworkExceptions._();

  /// Convert DioException to user-friendly error message
  static String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Bağlantı zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';

      case DioExceptionType.sendTimeout:
        return 'İstek gönderilirken zaman aşımı oluştu. Tekrar deneyin.';

      case DioExceptionType.receiveTimeout:
        return 'Sunucudan yanıt alınırken zaman aşımı oluştu.';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return 'İstek iptal edildi.';

      case DioExceptionType.connectionError:
        return _handleConnectionError(error);

      case DioExceptionType.badCertificate:
        return 'SSL sertifika hatası. Güvenli bağlantı kurulamadı.';

      case DioExceptionType.unknown:
        return _handleUnknownError(error);
    }
  }

  /// Handle bad response errors (4xx, 5xx status codes)
  static String _handleBadResponse(Response? response) {
    if (response == null) {
      return 'Sunucudan geçersiz yanıt alındı.';
    }

    final statusCode = response.statusCode ?? 0;
    final customMessage = _extractCustomErrorMessage(response);

    // If server provided a custom message, use it
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    // Otherwise, use default status code messages
    return _getStatusCodeMessage(statusCode);
  }

  /// Extract custom error message from response data
  static String? _extractCustomErrorMessage(Response response) {
    try {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        // Try common error message fields
        return data['message'] as String? ??
            data['error'] as String? ??
            data['detail'] as String? ??
            data['msg'] as String? ??
            _extractNestedErrorMessage(data);
      } else if (data is String && data.isNotEmpty) {
        // Plain text error message
        return data;
      }
    } catch (e) {
      // If parsing fails, return null to use fallback
      return null;
    }

    return null;
  }

  /// Extract error message from nested error objects
  static String? _extractNestedErrorMessage(Map<String, dynamic> data) {
    try {
      // Check for nested error objects
      if (data['error'] is Map<String, dynamic>) {
        final errorObj = data['error'] as Map<String, dynamic>;
        return errorObj['message'] as String? ??
            errorObj['detail'] as String? ??
            errorObj['description'] as String?;
      }

      // Check for errors array
      if (data['errors'] is List) {
        final errors = data['errors'] as List;
        if (errors.isNotEmpty && errors.first is Map) {
          final firstError = errors.first as Map<String, dynamic>;
          return firstError['message'] as String? ??
              firstError['detail'] as String?;
        }
      }
    } catch (e) {
      // If parsing fails, return null
      return null;
    }

    return null;
  }

  /// Get user-friendly message based on HTTP status code
  static String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      // Client errors (4xx)
      case 400:
        return 'Geçersiz istek. Gönderilen veriler hatalı.';
      case 401:
        return 'Yetkisiz erişim. Giriş yapmanız gerekiyor.';
      case 403:
        return 'Erişim engellendi. Bu işlem için yetkiniz bulunmuyor.';
      case 404:
        return 'İstenen kaynak bulunamadı.';
      case 405:
        return 'Bu işlem desteklenmiyor.';
      case 408:
        return 'İstek zaman aşımına uğradı. Tekrar deneyin.';
      case 409:
        return 'Çakışma oluştu. Bu işlem zaten yapılmış olabilir.';
      case 410:
        return 'İstenen kaynak artık mevcut değil.';
      case 413:
        return 'Gönderilen veri çok büyük.';
      case 422:
        return 'Gönderilen veriler geçersiz veya eksik.';
      case 429:
        return 'Çok fazla istek gönderildi. Lütfen biraz bekleyin.';

      // Server errors (5xx)
      case 500:
        return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
      case 501:
        return 'Bu özellik henüz desteklenmiyor.';
      case 502:
        return 'Ağ geçidi hatası. Sunucu geçici olarak erişilemez.';
      case 503:
        return 'Servis şu anda kullanılamıyor. Lütfen daha sonra deneyin.';
      case 504:
        return 'Ağ geçidi zaman aşımı. Sunucu yanıt vermiyor.';
      case 507:
        return 'Sunucu depolama alanı dolu.';
      case 508:
        return 'Sonsuz döngü algılandı.';

      // Default messages
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'İstemci hatası oluştu. (Kod: $statusCode)';
        } else if (statusCode >= 500) {
          return 'Sunucu hatası oluştu. (Kod: $statusCode)';
        } else {
          return 'Bilinmeyen HTTP hatası. (Kod: $statusCode)';
        }
    }
  }

  /// Handle connection errors
  static String _handleConnectionError(DioException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('network is unreachable') ||
        message.contains('no address associated with hostname')) {
      return 'İnternet bağlantınızı kontrol edin. Ağa erişilemiyor.';
    }

    if (message.contains('connection refused') ||
        message.contains('connection failed')) {
      return 'Sunucuya bağlanılamıyor. Lütfen daha sonra tekrar deneyin.';
    }

    if (message.contains('host lookup failed') ||
        message.contains('temporary failure in name resolution')) {
      return 'Sunucu adresi çözümlenemedi. DNS ayarlarınızı kontrol edin.';
    }

    if (message.contains('software caused connection abort')) {
      return 'Bağlantı kesintiye uğradı. İnternet bağlantınızı kontrol edin.';
    }

    // Generic connection error
    return 'İnternet bağlantı hatası. Bağlantınızı kontrol edip tekrar deneyin.';
  }

  /// Handle unknown errors
  static String _handleUnknownError(DioException error) {
    final message = error.message;

    if (message != null && message.isNotEmpty) {
      // Try to provide a more user-friendly version of the technical message
      if (message.toLowerCase().contains('socket')) {
        return 'Ağ bağlantısı problemi. İnternet bağlantınızı kontrol edin.';
      }

      if (message.toLowerCase().contains('format')) {
        return 'Veri formatı hatası. Lütfen tekrar deneyin.';
      }

      // Return the original message if it's not too technical
      if (message.length < 100 && !message.contains('Exception')) {
        return message;
      }
    }

    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  /// Check if error is retryable
  static bool isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        // Retry on server errors and some client errors
        return statusCode >= 500 ||
            statusCode == 408 || // Request timeout
            statusCode == 429; // Too many requests

      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(DioException error, int attemptNumber) {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 2);
    final exponentialDelay = baseDelay * (attemptNumber * attemptNumber);

    // Cap at 30 seconds
    final cappedDelay = exponentialDelay > Duration(seconds: 30)
        ? Duration(seconds: 30)
        : exponentialDelay;

    // Add some jitter (randomness) to prevent thundering herd
    final jitter = Duration(
      milliseconds: (cappedDelay.inMilliseconds * 0.1).round(),
    );

    return cappedDelay + jitter;
  }

  /// Check if error indicates offline status
  static bool isOfflineError(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      final message = error.message?.toLowerCase() ?? '';
      return message.contains('network is unreachable') ||
          message.contains('no address associated with hostname') ||
          message.contains('temporary failure in name resolution');
    }

    return false;
  }

  /// Get error category for analytics/logging
  static String getErrorCategory(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'timeout';

      case DioExceptionType.connectionError:
        return 'connection';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode >= 400 && statusCode < 500) {
          return 'client_error';
        } else if (statusCode >= 500) {
          return 'server_error';
        }
        return 'response_error';

      case DioExceptionType.cancel:
        return 'cancelled';

      case DioExceptionType.badCertificate:
        return 'certificate';

      case DioExceptionType.unknown:
        return 'unknown';
    }
  }
}
