// lib/src/core/error/exceptions.dart

/// Base exception class for all application exceptions
///
/// Exceptions represent technical errors that occur in the data layer
/// and should be caught and converted to Failures for the presentation layer.
/// They contain raw technical information and are not meant to be shown to users.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${runtimeType}: $message');

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}

/// Network-related exceptions (connection, timeout, etc.)
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalException,
    super.stackTrace,
  });

  /// Factory for connection timeout
  factory NetworkException.connectionTimeout({
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: 'Connection timeout occurred',
      code: 'CONNECTION_TIMEOUT',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for socket exception
  factory NetworkException.socketError({
    required String details,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: 'Socket error: $details',
      code: 'SOCKET_ERROR',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for DNS resolution failure
  factory NetworkException.dnsFailure({
    required String hostname,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: 'DNS resolution failed for: $hostname',
      code: 'DNS_FAILURE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for no internet connection
  factory NetworkException.noConnection({
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: 'No internet connection available',
      code: 'NO_CONNECTION',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for SSL/TLS errors
  factory NetworkException.sslError({
    required String details,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: 'SSL/TLS error: $details',
      code: 'SSL_ERROR',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }
}

/// Server response exceptions (HTTP errors)
class ServerException extends AppException {
  final int statusCode;
  final Map<String, dynamic>? responseData;
  final String? endpoint;

  const ServerException({
    required this.statusCode,
    required super.message,
    this.responseData,
    this.endpoint,
    super.code = 'SERVER_ERROR',
    super.originalException,
    super.stackTrace,
  });

  /// Factory for bad request (400)
  factory ServerException.badRequest({
    required String message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 400,
      message: message,
      endpoint: endpoint,
      responseData: responseData,
      code: 'BAD_REQUEST',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for unauthorized (401)
  factory ServerException.unauthorized({
    String? message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 401,
      message: message ?? 'Unauthorized access',
      endpoint: endpoint,
      responseData: responseData,
      code: 'UNAUTHORIZED',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for forbidden (403)
  factory ServerException.forbidden({
    String? message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 403,
      message: message ?? 'Access forbidden',
      endpoint: endpoint,
      responseData: responseData,
      code: 'FORBIDDEN',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for not found (404)
  factory ServerException.notFound({
    String? message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 404,
      message: message ?? 'Resource not found',
      endpoint: endpoint,
      responseData: responseData,
      code: 'NOT_FOUND',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for validation error (422)
  factory ServerException.validationError({
    String? message,
    String? endpoint,
    Map<String, dynamic>? validationErrors,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 422,
      message: message ?? 'Validation failed',
      endpoint: endpoint,
      responseData: validationErrors,
      code: 'VALIDATION_ERROR',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for rate limiting (429)
  factory ServerException.rateLimited({
    String? message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 429,
      message: message ?? 'Rate limit exceeded',
      endpoint: endpoint,
      responseData: responseData,
      code: 'RATE_LIMITED',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for internal server error (500)
  factory ServerException.internalError({
    String? message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 500,
      message: message ?? 'Internal server error',
      endpoint: endpoint,
      responseData: responseData,
      code: 'INTERNAL_ERROR',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for service unavailable (503)
  factory ServerException.serviceUnavailable({
    String? message,
    String? endpoint,
    Map<String, dynamic>? responseData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ServerException(
      statusCode: 503,
      message: message ?? 'Service unavailable',
      endpoint: endpoint,
      responseData: responseData,
      code: 'SERVICE_UNAVAILABLE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('ServerException($statusCode): $message');

    if (endpoint != null) {
      buffer.write(' [Endpoint: $endpoint]');
    }

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    if (responseData != null) {
      buffer.write('\nResponse Data: $responseData');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}

/// Local storage/cache exceptions
class CacheException extends AppException {
  final String? operation;
  final String? key;

  const CacheException({
    required super.message,
    this.operation,
    this.key,
    super.code = 'CACHE_ERROR',
    super.originalException,
    super.stackTrace,
  });

  /// Factory for cache read failure
  factory CacheException.readFailure({
    required String key,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return CacheException(
      message: 'Failed to read from cache',
      operation: 'READ',
      key: key,
      code: 'CACHE_READ_FAILURE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for cache write failure
  factory CacheException.writeFailure({
    required String key,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return CacheException(
      message: 'Failed to write to cache',
      operation: 'WRITE',
      key: key,
      code: 'CACHE_WRITE_FAILURE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for cache corruption
  factory CacheException.corrupted({
    required String key,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return CacheException(
      message: 'Cache data is corrupted',
      operation: 'READ',
      key: key,
      code: 'CACHE_CORRUPTED',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for cache not found
  factory CacheException.notFound({required String key}) {
    return CacheException(
      message: 'Cache entry not found',
      operation: 'READ',
      key: key,
      code: 'CACHE_NOT_FOUND',
    );
  }

  /// Factory for cache storage full
  factory CacheException.storageFull({
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return CacheException(
      message: 'Cache storage is full',
      operation: 'WRITE',
      code: 'CACHE_STORAGE_FULL',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('CacheException: $message');

    if (operation != null && key != null) {
      buffer.write(' [Operation: $operation, Key: $key]');
    } else if (operation != null) {
      buffer.write(' [Operation: $operation]');
    } else if (key != null) {
      buffer.write(' [Key: $key]');
    }

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}

/// Data parsing/serialization exceptions
class ParseException extends AppException {
  final String? data;
  final Type? expectedType;

  const ParseException({
    required super.message,
    this.data,
    this.expectedType,
    super.code = 'PARSE_ERROR',
    super.originalException,
    super.stackTrace,
  });

  /// Factory for JSON parsing failure
  factory ParseException.jsonParsingFailure({
    required String jsonString,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ParseException(
      message: 'Failed to parse JSON data',
      data: jsonString.length > 200
          ? '${jsonString.substring(0, 200)}...'
          : jsonString,
      code: 'JSON_PARSE_FAILURE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for type conversion failure
  factory ParseException.typeConversionFailure({
    required Type expectedType,
    required String actualData,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ParseException(
      message: 'Failed to convert data to $expectedType',
      data: actualData,
      expectedType: expectedType,
      code: 'TYPE_CONVERSION_FAILURE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for missing required field
  factory ParseException.missingRequiredField({
    required String fieldName,
    String? data,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ParseException(
      message: 'Missing required field: $fieldName',
      data: data,
      code: 'MISSING_REQUIRED_FIELD',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for invalid date format
  factory ParseException.invalidDateFormat({
    required String dateString,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return ParseException(
      message: 'Invalid date format: $dateString',
      data: dateString,
      expectedType: DateTime,
      code: 'INVALID_DATE_FORMAT',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('ParseException: $message');

    if (expectedType != null) {
      buffer.write(' [Expected: $expectedType]');
    }

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    if (data != null) {
      buffer.write('\nData: $data');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}

/// Authentication-related exceptions
class AuthException extends AppException {
  final String? token;
  final String? endpoint;

  const AuthException({
    required super.message,
    this.token,
    this.endpoint,
    super.code = 'AUTH_ERROR',
    super.originalException,
    super.stackTrace,
  });

  /// Factory for token expired
  factory AuthException.tokenExpired({
    String? token,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'Authentication token has expired',
      token: token != null
          ? '${token.substring(0, 10)}...'
          : null, // Hide sensitive token
      code: 'TOKEN_EXPIRED',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for invalid token
  factory AuthException.invalidToken({
    String? token,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'Invalid authentication token',
      token: token != null ? '${token.substring(0, 10)}...' : null,
      code: 'INVALID_TOKEN',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for token refresh failure
  factory AuthException.refreshFailure({
    String? endpoint,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'Failed to refresh authentication token',
      endpoint: endpoint,
      code: 'TOKEN_REFRESH_FAILURE',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('AuthException: $message');

    if (endpoint != null) {
      buffer.write(' [Endpoint: $endpoint]');
    }

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    if (token != null) {
      buffer.write(' [Token: $token]');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}

/// Platform-specific exceptions
class PlatformException extends AppException {
  final String platform;
  final String? feature;

  const PlatformException({
    required this.platform,
    required super.message,
    this.feature,
    super.code = 'PLATFORM_ERROR',
    super.originalException,
    super.stackTrace,
  });

  /// Factory for unsupported platform
  factory PlatformException.unsupported({
    required String platform,
    required String feature,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return PlatformException(
      platform: platform,
      message: 'Feature "$feature" is not supported on $platform',
      feature: feature,
      code: 'PLATFORM_UNSUPPORTED',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Factory for permission denied
  factory PlatformException.permissionDenied({
    required String platform,
    required String permission,
    Exception? originalException,
    StackTrace? stackTrace,
  }) {
    return PlatformException(
      platform: platform,
      message: 'Permission "$permission" denied on $platform',
      feature: permission,
      code: 'PLATFORM_PERMISSION_DENIED',
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('PlatformException($platform): $message');

    if (feature != null) {
      buffer.write(' [Feature: $feature]');
    }

    if (code != null) {
      buffer.write(' (Code: $code)');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}

/// Generic application exception for unknown errors
class GenericAppException extends AppException {
  const GenericAppException({
    required super.message,
    super.code = 'GENERIC_ERROR',
    super.originalException,
    super.stackTrace,
  });
}

/// Extension for easy exception creation from common error types
extension ExceptionFactory on Exception {
  /// Convert any exception to a concrete AppException with context
  AppException toAppException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) {
    return GenericAppException(
      message: message,
      code: code,
      originalException: this,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }
}
