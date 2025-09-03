// lib/src/core/network/auth_interceptor.dart

import 'package:dio/dio.dart';
import '../storage/simple_token_storage.dart';
import '../../utils/app_logger.dart';
import 'package:flutter/foundation.dart';

/// HTTP Interceptor for automatic token injection and refresh
///
/// Bu interceptor tüm API çağrılarında otomatik olarak:
/// - Authorization header'ına Bearer token ekler
/// - 401 Unauthorized durumunda token refresh yapar
/// - Token refresh başarısızsa kullanıcıyı logout eder
///
/// Mevcut ApiClient'a eklenerek kullanılır.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Future<bool> Function()? _refreshTokenCallback;
  final VoidCallback? _onTokenRefreshFailed;

  /// Constructor
  ///
  /// [_dio] Dio instance for making refresh requests
  /// [_refreshTokenCallback] Function to refresh tokens (return true if successful)
  /// [_onTokenRefreshFailed] Callback when token refresh fails (logout user)
  AuthInterceptor(
    this._dio, {
    Future<bool> Function()? refreshTokenCallback,
    VoidCallback? onTokenRefreshFailed,
  }) : _refreshTokenCallback = refreshTokenCallback,
       _onTokenRefreshFailed = onTokenRefreshFailed;

  // ========== REQUEST INTERCEPTOR ==========

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Skip auth for certain endpoints
      if (_shouldSkipAuth(options)) {
        AppLogger.debug('⏭️ Skipping auth for ${options.path}');
        handler.next(options);
        return;
      }

      // Get access token
      final accessToken = await SimpleTokenStorage.getAccessToken();

      if (accessToken == null) {
        AppLogger.debug('🔍 No access token available for ${options.path}');
        handler.next(options);
        return;
      }

      // Add Bearer token to headers
      options.headers['Authorization'] = 'Bearer $accessToken';
      AppLogger.debug(
        '🔑 Added auth token to ${options.method} ${options.path}',
      );

      handler.next(options);
    } catch (e) {
      AppLogger.error('❌ Auth interceptor request error: $e');
      handler.next(options); // Continue without token on error
    }
  }

  // ========== RESPONSE INTERCEPTOR ==========

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log successful authenticated requests
    if (response.requestOptions.headers.containsKey('Authorization')) {
      AppLogger.debug(
        '✅ Authenticated request success: ${response.statusCode} ${response.requestOptions.path}',
      );
    }

    handler.next(response);
  }

  // ========== ERROR INTERCEPTOR ==========

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if this is a 401 Unauthorized error
    if (err.response?.statusCode == 401) {
      AppLogger.warning('🚫 401 Unauthorized - attempting token refresh');

      // Attempt to refresh token and retry request
      final success = await _attemptTokenRefreshAndRetry(err, handler);

      if (success) {
        return; // Request was retried successfully
      }
    }

    // If not 401 or refresh failed, continue with original error
    handler.next(err);
  }

  // ========== TOKEN REFRESH LOGIC ==========

  /// Attempt to refresh tokens and retry the failed request
  ///
  /// Returns true if refresh was successful and request was retried
  /// Returns false if refresh failed
  Future<bool> _attemptTokenRefreshAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      // Skip refresh for auth endpoints to prevent infinite loops
      if (_isAuthEndpoint(err.requestOptions)) {
        AppLogger.debug('⏭️ Skipping refresh for auth endpoint');
        return false;
      }

      // Check if we have a refresh callback
      if (_refreshTokenCallback == null) {
        AppLogger.warning('⚠️ No refresh callback configured');
        return false;
      }

      // Attempt token refresh
      AppLogger.info('🔄 Attempting token refresh...');
      final refreshSuccess = await _refreshTokenCallback();

      if (!refreshSuccess) {
        AppLogger.error('❌ Token refresh failed');
        _handleRefreshFailure();
        return false;
      }

      // Refresh successful - retry original request
      AppLogger.info('✅ Token refresh successful - retrying request');
      final retrySuccess = await _retryOriginalRequest(err, handler);

      return retrySuccess;
    } catch (e) {
      AppLogger.error('❌ Token refresh attempt failed: $e');
      _handleRefreshFailure();
      return false;
    }
  }

  /// Retry the original failed request with new tokens
  Future<bool> _retryOriginalRequest(
    DioException originalError,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      // Get new access token
      final newAccessToken = await SimpleTokenStorage.getAccessToken();

      if (newAccessToken == null) {
        AppLogger.error('❌ No new access token after refresh');
        return false;
      }

      // Clone original request options
      final retryOptions = originalError.requestOptions;

      // Update Authorization header with new token
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      AppLogger.debug(
        '🔄 Retrying with new token: ${retryOptions.method} ${retryOptions.path}',
      );

      // Make the retry request
      final retryResponse = await _dio.fetch(retryOptions);

      // Return successful response
      handler.resolve(retryResponse);
      AppLogger.info('✅ Retry request successful');

      return true;
    } catch (retryError) {
      AppLogger.error('❌ Retry request failed: $retryError');

      // If retry fails, return the original error
      if (retryError is DioException) {
        handler.next(retryError);
      } else {
        handler.next(originalError);
      }

      return false;
    }
  }

  // ========== HELPER METHODS ==========

  /// Handle token refresh failure - notify callback to logout user
  void _handleRefreshFailure() {
    AppLogger.warning('⚠️ Token refresh failed - triggering logout');

    // Clear stored tokens
    SimpleTokenStorage.clearAll().catchError((e) {
      AppLogger.error('❌ Failed to clear tokens on refresh failure: $e');
    });

    // Notify callback to logout user
    _onTokenRefreshFailed?.call();
  }

  /// Check if request should skip authentication
  bool _shouldSkipAuth(RequestOptions options) {
    final path = options.path.toLowerCase();

    // Skip auth for these paths
    final skipPaths = [
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/forgot-password',
      '/api/auth/reset-password',
      '/api/health',
      '/api/public',
    ];

    return skipPaths.any((skipPath) => path.contains(skipPath));
  }

  /// Check if this is an auth-related endpoint
  bool _isAuthEndpoint(RequestOptions options) {
    final path = options.path.toLowerCase();

    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');
  }

  // ========== FACTORY METHODS ==========

  /// Create AuthInterceptor with default refresh logic
  ///
  /// This factory method will be connected to the auth service later
  static AuthInterceptor create({
    required Dio dio,
    Future<bool> Function()? refreshTokenCallback,
    VoidCallback? onTokenRefreshFailed,
  }) {
    return AuthInterceptor(
      dio,
      refreshTokenCallback: refreshTokenCallback,
      onTokenRefreshFailed: onTokenRefreshFailed,
    );
  }

  // ========== DEBUG METHODS ==========

  /// Get interceptor statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'hasRefreshCallback': _refreshTokenCallback != null,
      'hasFailureCallback': _onTokenRefreshFailed != null,
      'interceptor': 'AuthInterceptor',
      'created': DateTime.now().toIso8601String(),
    };
  }
}

/// Extension to add auth interceptor to existing ApiClient
extension ApiClientAuthExtension on Dio {
  /// Add auth interceptor to this Dio instance
  void addAuthInterceptor({
    Future<bool> Function()? refreshTokenCallback,
    VoidCallback? onTokenRefreshFailed,
  }) {
    final authInterceptor = AuthInterceptor.create(
      dio: this,
      refreshTokenCallback: refreshTokenCallback,
      onTokenRefreshFailed: onTokenRefreshFailed,
    );

    interceptors.add(authInterceptor);
    AppLogger.info('✅ Auth interceptor added to ApiClient');
  }
}
