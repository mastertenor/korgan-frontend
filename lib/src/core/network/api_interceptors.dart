// lib/src/core/network/api_interceptors.dart

import 'package:dio/dio.dart';
import 'dart:developer' as developer;

/// Logging interceptor for API requests and responses
///
/// This interceptor logs all HTTP requests, responses, and errors
/// with detailed information for debugging purposes.
class LoggingInterceptor extends Interceptor {
  final bool logRequests;
  final bool logResponses;
  final bool logErrors;
  final bool logHeaders;
  final bool logRequestBody;
  final bool logResponseBody;

  LoggingInterceptor({
    this.logRequests = true,
    this.logResponses = true,
    this.logErrors = true,
    this.logHeaders = false,
    this.logRequestBody = true,
    this.logResponseBody = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (logRequests) {
      final uri = options.uri;
      developer.log('🚀 REQUEST: ${options.method} $uri', name: 'ApiClient');

      if (logHeaders && options.headers.isNotEmpty) {
        developer.log(
          '📋 Headers: ${_formatHeaders(options.headers)}',
          name: 'ApiClient',
        );
      }

      if (logRequestBody && options.data != null) {
        developer.log(
          '📦 Body: ${_formatData(options.data)}',
          name: 'ApiClient',
        );
      }

      if (options.queryParameters.isNotEmpty) {
        developer.log(
          '🔍 Query: ${options.queryParameters}',
          name: 'ApiClient',
        );
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (logResponses) {
      final statusCode = response.statusCode;
      final method = response.requestOptions.method;
      final uri = response.requestOptions.uri;

      developer.log('✅ RESPONSE: $statusCode $method $uri', name: 'ApiClient');

      if (logHeaders && response.headers.map.isNotEmpty) {
        developer.log(
          '📋 Response Headers: ${_formatHeaders(response.headers.map)}',
          name: 'ApiClient',
        );
      }

      if (logResponseBody && response.data != null) {
        developer.log(
          '📥 Response Body: ${_formatData(response.data)}',
          name: 'ApiClient',
        );
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (logErrors) {
      final statusCode = err.response?.statusCode;
      final method = err.requestOptions.method;
      final uri = err.requestOptions.uri;

      developer.log(
        '❌ ERROR: ${err.type} $statusCode $method $uri',
        name: 'ApiClient',
        error: err,
      );

      if (err.response?.data != null) {
        developer.log(
          '💥 Error Response: ${_formatData(err.response!.data)}',
          name: 'ApiClient',
        );
      }

      developer.log('🔍 Error Message: ${err.message}', name: 'ApiClient');
    }

    super.onError(err, handler);
  }

  /// Format headers for logging
  String _formatHeaders(Map<String, dynamic> headers) {
    final buffer = StringBuffer();
    headers.forEach((key, value) {
      // Hide sensitive headers
      if (_isSensitiveHeader(key)) {
        buffer.writeln('  $key: [HIDDEN]');
      } else {
        buffer.writeln('  $key: $value');
      }
    });
    return buffer.toString();
  }

  /// Format request/response data for logging
  String _formatData(dynamic data) {
    if (data == null) return 'null';

    try {
      final String dataString = data.toString();

      // Limit log size to prevent overwhelming console
      if (dataString.length > 1000) {
        return '${dataString.substring(0, 1000)}... [TRUNCATED]';
      }

      return dataString;
    } catch (e) {
      return 'Unable to format data: $e';
    }
  }

  /// Check if header contains sensitive information
  bool _isSensitiveHeader(String headerName) {
    final sensitive = [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'x-auth-token',
      'access-token',
      'refresh-token',
    ];

    return sensitive.contains(headerName.toLowerCase());
  }
}

/// Authentication interceptor for adding auth tokens to requests
///
/// This interceptor automatically adds authentication headers
/// to outgoing requests when available.
class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getAccessToken;
  final Future<String?> Function()? getRefreshToken;
  final Future<void> Function(String refreshToken)? refreshTokenCallback;
  final bool autoRefresh;

  AuthInterceptor({
    required this.getAccessToken,
    this.getRefreshToken,
    this.refreshTokenCallback,
    this.autoRefresh = true,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Skip auth for certain endpoints
      if (_shouldSkipAuth(options)) {
        return handler.next(options);
      }

      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      developer.log(
        'Error adding auth token: $e',
        name: 'AuthInterceptor',
        error: e,
      );
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized responses
    if (err.response?.statusCode == 401 && autoRefresh) {
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request with new token
          final retryResponse = await _retryRequest(err.requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (refreshError) {
        developer.log(
          'Token refresh failed: $refreshError',
          name: 'AuthInterceptor',
          error: refreshError,
        );
      }
    }

    super.onError(err, handler);
  }

  /// Check if request should skip authentication
  bool _shouldSkipAuth(RequestOptions options) {
    final skipAuthPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/public',
    ];

    return skipAuthPaths.any((path) => options.path.contains(path));
  }

  /// Attempt to refresh the access token
  Future<bool> _refreshToken() async {
    if (getRefreshToken == null || refreshTokenCallback == null) {
      return false;
    }

    try {
      final refreshToken = await getRefreshToken!();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await refreshTokenCallback!(refreshToken);
        return true;
      }
    } catch (e) {
      developer.log(
        'Token refresh error: $e',
        name: 'AuthInterceptor',
        error: e,
      );
    }

    return false;
  }

  /// Retry the original request with new token
  Future<Response> _retryRequest(RequestOptions options) async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final dio = Dio();
    return await dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: options.headers,
        contentType: options.contentType,
        responseType: options.responseType,
        followRedirects: options.followRedirects,
        maxRedirects: options.maxRedirects,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
      ),
    );
  }
}

/// Cache interceptor for caching GET requests
///
/// This interceptor caches GET responses to improve performance
/// and provide offline capabilities.
class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration defaultCacheDuration;
  final int maxCacheSize;

  CacheInterceptor({
    this.defaultCacheDuration = const Duration(minutes: 5),
    this.maxCacheSize = 100,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    // Check if response is cached and still valid
    final cacheKey = _generateCacheKey(options);
    final cachedEntry = _cache[cacheKey];

    if (cachedEntry != null && !cachedEntry.isExpired) {
      developer.log(
        '💾 Cache hit for: ${options.uri}',
        name: 'CacheInterceptor',
      );

      // Return cached response
      return handler.resolve(cachedEntry.response);
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Only cache successful GET responses
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      final cacheDuration = _getCacheDuration(response.requestOptions);

      // Clean cache if it's getting too large
      if (_cache.length >= maxCacheSize) {
        _cleanOldEntries();
      }

      _cache[cacheKey] = CacheEntry(
        response: response,
        expiresAt: DateTime.now().add(cacheDuration),
      );

      developer.log(
        '💾 Cached response for: ${response.requestOptions.uri}',
        name: 'CacheInterceptor',
      );
    }

    super.onResponse(response, handler);
  }

  /// Generate cache key from request options
  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final headers = options.headers.toString();
    return '$uri$headers'.hashCode.toString();
  }

  /// Get cache duration for specific request
  Duration _getCacheDuration(RequestOptions options) {
    // You can customize cache duration based on endpoint
    if (options.path.contains('/emails')) {
      return const Duration(minutes: 2); // Emails cache shorter
    }

    return defaultCacheDuration;
  }

  /// Clean old cache entries
  void _cleanOldEntries() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiresAt.isBefore(now));

    // If still too large, remove oldest entries
    if (_cache.length >= maxCacheSize) {
      final entries = _cache.entries.toList();
      entries.sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));

      // Remove oldest 20% of entries
      final toRemove = (maxCacheSize * 0.2).round();
      for (int i = 0; i < toRemove && i < entries.length; i++) {
        _cache.remove(entries[i].key);
      }
    }
  }

  /// Clear all cached entries
  void clearCache() {
    _cache.clear();
    developer.log('🗑️ Cache cleared', name: 'CacheInterceptor');
  }

  /// Clear cache for specific pattern
  void clearCachePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    developer.log(
      '🗑️ Cache cleared for pattern: $pattern',
      name: 'CacheInterceptor',
    );
  }
}

/// Cache entry data structure
class CacheEntry {
  final Response response;
  final DateTime expiresAt;

  CacheEntry({required this.response, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Retry interceptor for handling failed requests
///
/// This interceptor automatically retries failed requests
/// with exponential backoff strategy.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;
  final List<int> retryableStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (retryCount >= maxRetries || !_shouldRetry(err)) {
      return super.onError(err, handler);
    }

    final delay = _calculateDelay(retryCount);
    developer.log(
      '🔄 Retrying request (${retryCount + 1}/$maxRetries) after ${delay.inSeconds}s: ${err.requestOptions.uri}',
      name: 'RetryInterceptor',
    );

    await Future.delayed(delay);

    try {
      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      final dio = Dio();
      final response = await dio.request(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(
          method: options.method,
          headers: options.headers,
          contentType: options.contentType,
          responseType: options.responseType,
          extra: options.extra,
        ),
      );

      return handler.resolve(response);
    } catch (retryError) {
      if (retryError is DioException) {
        return super.onError(retryError, handler);
      } else {
        return super.onError(err, handler);
      }
    }
  }

  /// Check if the error should be retried
  bool _shouldRetry(DioException error) {
    // Don't retry cancelled requests
    if (error.type == DioExceptionType.cancel) {
      return false;
    }

    // Retry network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry specific status codes
    if (error.response?.statusCode != null) {
      return retryableStatusCodes.contains(error.response!.statusCode!);
    }

    return false;
  }

  /// Calculate delay for retry with exponential backoff
  Duration _calculateDelay(int retryCount) {
    final exponentialDelay = baseDelay * (1 << retryCount); // 2^retryCount

    // Add jitter to prevent thundering herd
    final jitter = Duration(
      milliseconds:
          (exponentialDelay.inMilliseconds *
                  0.1 *
                  (DateTime.now().millisecondsSinceEpoch % 100) /
                  100)
              .round(),
    );

    return exponentialDelay + jitter;
  }
}
