// lib/src/core/error/failures.dart

import 'package:equatable/equatable.dart';

/// Base failure class for representing business logic errors
///
/// Failures represent errors that occur in the business logic layer
/// and can be presented to the user. They are different from exceptions
/// which are technical errors that should be caught and converted to failures.
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const Failure({required this.message, this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() =>
      'Failure(message: $message, code: $code, details: $details)';
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.details,
  });

  /// Factory for connection timeout
  factory NetworkFailure.connectionTimeout() {
    return const NetworkFailure(
      message: 'Bağlantı zaman aşımına uğradı',
      code: 'CONNECTION_TIMEOUT',
    );
  }

  /// Factory for no internet connection
  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      message: 'İnternet bağlantısı yok',
      code: 'NO_CONNECTION',
    );
  }

  /// Factory for request timeout
  factory NetworkFailure.requestTimeout() {
    return const NetworkFailure(
      message: 'İstek zaman aşımına uğradı',
      code: 'REQUEST_TIMEOUT',
    );
  }

  /// Factory for SSL certificate error
  factory NetworkFailure.sslError() {
    return const NetworkFailure(
      message: 'SSL sertifika hatası',
      code: 'SSL_ERROR',
    );
  }
}

/// Server-related failures (4xx, 5xx HTTP errors)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code = 'SERVER_ERROR',
    super.details,
  });

  /// Factory for authentication failure (401)
  factory ServerFailure.unauthorized({String? message}) {
    return ServerFailure(
      message: message ?? 'Yetkisiz erişim - Giriş yapmanız gerekiyor',
      statusCode: 401,
      code: 'UNAUTHORIZED',
    );
  }

  /// Factory for forbidden access (403)
  factory ServerFailure.forbidden({String? message}) {
    return ServerFailure(
      message: message ?? 'Erişim engellendi - Yetkiniz bulunmuyor',
      statusCode: 403,
      code: 'FORBIDDEN',
    );
  }

  /// Factory for not found (404)
  factory ServerFailure.notFound({String? message}) {
    return ServerFailure(
      message: message ?? 'İstenen kaynak bulunamadı',
      statusCode: 404,
      code: 'NOT_FOUND',
    );
  }

  /// Factory for validation error (422)
  factory ServerFailure.validationError({
    String? message,
    Map<String, dynamic>? validationErrors,
  }) {
    return ServerFailure(
      message: message ?? 'Gönderilen veriler geçersiz',
      statusCode: 422,
      code: 'VALIDATION_ERROR',
      details: validationErrors,
    );
  }

  /// Factory for rate limiting (429)
  factory ServerFailure.rateLimited({String? message}) {
    return ServerFailure(
      message: message ?? 'Çok fazla istek - Lütfen bekleyin',
      statusCode: 429,
      code: 'RATE_LIMITED',
    );
  }

  /// Factory for internal server error (500)
  factory ServerFailure.internalError({String? message}) {
    return ServerFailure(
      message: message ?? 'Sunucu hatası - Lütfen daha sonra deneyin',
      statusCode: 500,
      code: 'INTERNAL_ERROR',
    );
  }

  /// Factory for service unavailable (503)
  factory ServerFailure.serviceUnavailable({String? message}) {
    return ServerFailure(
      message: message ?? 'Servis kullanılamıyor - Lütfen daha sonra deneyin',
      statusCode: 503,
      code: 'SERVICE_UNAVAILABLE',
    );
  }

  @override
  List<Object?> get props => [...super.props, statusCode];

  @override
  String toString() =>
      'ServerFailure(message: $message, statusCode: $statusCode, code: $code)';
}

/// Local cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.details,
  });

  /// Factory for cache not found
  factory CacheFailure.notFound() {
    return const CacheFailure(
      message: 'Önbellek verisi bulunamadı',
      code: 'CACHE_NOT_FOUND',
    );
  }

  /// Factory for cache write error
  factory CacheFailure.writeError() {
    return const CacheFailure(
      message: 'Önbellek yazma hatası',
      code: 'CACHE_WRITE_ERROR',
    );
  }

  /// Factory for cache read error
  factory CacheFailure.readError() {
    return const CacheFailure(
      message: 'Önbellek okuma hatası',
      code: 'CACHE_READ_ERROR',
    );
  }

  /// Factory for cache corruption
  factory CacheFailure.corrupted() {
    return const CacheFailure(
      message: 'Önbellek verisi bozuk',
      code: 'CACHE_CORRUPTED',
    );
  }
}

/// Data validation failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code = 'VALIDATION_ERROR',
    super.details,
  });

  /// Factory for email validation error
  factory ValidationFailure.invalidEmail({String? email}) {
    return ValidationFailure(
      message: 'Geçersiz e-posta adresi',
      code: 'INVALID_EMAIL',
      fieldErrors: {
        'email': ['E-posta adresi geçerli bir format olmalıdır'],
      },
      details: {'invalidEmail': email},
    );
  }

  /// Factory for required field error
  factory ValidationFailure.requiredField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName alanı zorunludur',
      code: 'REQUIRED_FIELD',
      fieldErrors: {
        fieldName: ['Bu alan zorunludur'],
      },
    );
  }

  /// Factory for invalid format error
  factory ValidationFailure.invalidFormat(
    String fieldName,
    String expectedFormat,
  ) {
    return ValidationFailure(
      message: '$fieldName geçersiz formatta',
      code: 'INVALID_FORMAT',
      fieldErrors: {
        fieldName: ['Beklenen format: $expectedFormat'],
      },
    );
  }

  /// Factory for length validation error
  factory ValidationFailure.invalidLength(
    String fieldName,
    int minLength,
    int maxLength,
  ) {
    return ValidationFailure(
      message:
          '$fieldName uzunluğu $minLength-$maxLength karakter arasında olmalıdır',
      code: 'INVALID_LENGTH',
      fieldErrors: {
        fieldName: [
          'Uzunluk $minLength-$maxLength karakter arasında olmalıdır',
        ],
      },
    );
  }

  @override
  List<Object?> get props => [...super.props, fieldErrors];

  @override
  String toString() =>
      'ValidationFailure(message: $message, fieldErrors: $fieldErrors)';
}

/// Authentication and authorization failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.details,
  });

  /// Factory for login failure
  factory AuthFailure.loginFailed({String? message}) {
    return AuthFailure(
      message: message ?? 'Giriş başarısız - E-posta veya şifre hatalı',
      code: 'LOGIN_FAILED',
    );
  }

  /// Factory for token expired
  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Oturum süresi doldu - Tekrar giriş yapın',
      code: 'TOKEN_EXPIRED',
    );
  }

  /// Factory for token invalid
  factory AuthFailure.invalidToken() {
    return const AuthFailure(
      message: 'Geçersiz token - Tekrar giriş yapın',
      code: 'INVALID_TOKEN',
    );
  }

  /// Factory for permission denied
  factory AuthFailure.permissionDenied({String? resource}) {
    return AuthFailure(
      message: resource != null
          ? '$resource için yetkiniz bulunmuyor'
          : 'Bu işlem için yetkiniz bulunmuyor',
      code: 'PERMISSION_DENIED',
      details: {'resource': resource},
    );
  }

  /// Factory for account disabled
  factory AuthFailure.accountDisabled() {
    return const AuthFailure(
      message: 'Hesabınız devre dışı bırakılmış',
      code: 'ACCOUNT_DISABLED',
    );
  }
}

/// Mail-specific business logic failures
class MailFailure extends Failure {
  const MailFailure({
    required super.message,
    super.code = 'MAIL_ERROR',
    super.details,
  });

  /// Factory for mail not found
  factory MailFailure.notFound(String mailId) {
    return MailFailure(
      message: 'E-posta bulunamadı',
      code: 'MAIL_NOT_FOUND',
      details: {'mailId': mailId},
    );
  }

  /// Factory for mail send failure
  factory MailFailure.sendFailed({String? reason}) {
    return MailFailure(
      message: reason ?? 'E-posta gönderilemedi',
      code: 'MAIL_SEND_FAILED',
      details: {'reason': reason},
    );
  }

  /// Factory for mailbox access error
  factory MailFailure.accessDenied(String email) {
    return MailFailure(
      message: 'E-posta hesabına erişim reddedildi',
      code: 'MAILBOX_ACCESS_DENIED',
      details: {'email': email},
    );
  }

  /// Factory for quota exceeded
  factory MailFailure.quotaExceeded() {
    return const MailFailure(
      message: 'E-posta kotası aşıldı',
      code: 'QUOTA_EXCEEDED',
    );
  }

  /// Factory for attachment too large
  factory MailFailure.attachmentTooLarge(int maxSize) {
    return MailFailure(
      message: 'Ek dosya çok büyük (Maksimum: ${maxSize}MB)',
      code: 'ATTACHMENT_TOO_LARGE',
      details: {'maxSize': maxSize},
    );
  }

  /// Factory for invalid recipient
  factory MailFailure.invalidRecipient(String email) {
    return MailFailure(
      message: 'Geçersiz alıcı e-posta adresi',
      code: 'INVALID_RECIPIENT',
      details: {'email': email},
    );
  }
}

/// Generic application failures
class AppFailure extends Failure {
  const AppFailure({
    required super.message,
    super.code = 'APP_ERROR',
    super.details,
  });

  /// Factory for unknown error
  factory AppFailure.unknown({String? message}) {
    return AppFailure(
      message: message ?? 'Beklenmeyen bir hata oluştu',
      code: 'UNKNOWN_ERROR',
    );
  }

  /// Factory for feature not implemented
  factory AppFailure.notImplemented(String feature) {
    return AppFailure(
      message: '$feature özelliği henüz desteklenmiyor',
      code: 'NOT_IMPLEMENTED',
      details: {'feature': feature},
    );
  }

  /// Factory for configuration error
  factory AppFailure.configuration(String issue) {
    return AppFailure(
      message: 'Yapılandırma hatası: $issue',
      code: 'CONFIGURATION_ERROR',
      details: {'issue': issue},
    );
  }

  /// Factory for operation cancelled
  factory AppFailure.cancelled() {
    return const AppFailure(
      message: 'İşlem iptal edildi',
      code: 'OPERATION_CANCELLED',
    );
  }
}

/// Utility extension for failure handling
extension FailureExtension on Failure {
  /// Check if failure is retryable
  bool get isRetryable {
    return this is NetworkFailure ||
        (this is ServerFailure &&
            (this as ServerFailure).statusCode != null &&
            [
              (this as ServerFailure).statusCode! >= 500,
              (this as ServerFailure).statusCode == 408,
              (this as ServerFailure).statusCode == 429,
            ].any((condition) => condition));
  }

  /// Check if failure requires authentication
  bool get requiresAuth {
    return this is AuthFailure ||
        (this is ServerFailure && (this as ServerFailure).statusCode == 401);
  }

  /// Check if failure is due to network issues
  bool get isNetworkRelated {
    return this is NetworkFailure;
  }

  /// Check if failure is user actionable
  bool get isUserActionable {
    return this is ValidationFailure ||
        this is AuthFailure ||
        (this is ServerFailure &&
            (this as ServerFailure).statusCode != null &&
            (this as ServerFailure).statusCode! < 500);
  }
}
