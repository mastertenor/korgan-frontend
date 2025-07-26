import 'package:dio/dio.dart';

/// Core API client that handles all HTTP requests
///
/// This class provides a centralized way to make API calls with:
/// - Base configuration (timeout, headers)
/// - Interceptor support for logging, auth, etc.
/// - Error handling
/// - Request/Response transformation
class ApiClient {
  late final Dio _dio;

  /// Singleton instance
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  ApiClient._internal() {
    // Use ngrok URL for both web and mobile
    const String baseUrl = 'https://29a5324fbd74.ngrok-free.app';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        //sendTimeout: const Duration(seconds: 30),
        headers: {
          //'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Ngrok için gerekli header
          'ngrok-skip-browser-warning': 'true',
        },
        // Response type'ını JSON olarak ayarla
        responseType: ResponseType.json,
      ),
    );

    // Development mode'da detaylı logging ekle
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (object) {
          // Production'da bu kapatılabilir
          print('🌐 API: $object');
        },
      ),
    );
  }

  /// Factory constructor for easy access
  factory ApiClient() => instance;

  /// GET request
  ///
  /// [path] - API endpoint path
  /// [queryParameters] - URL query parameters
  /// [options] - Additional request options
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST request
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - URL query parameters
  /// [options] - Additional request options
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PUT request
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data
  /// [queryParameters] - URL query parameters
  /// [options] - Additional request options
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DELETE request
  ///
  /// [path] - API endpoint path
  /// [data] - Request body data (optional)
  /// [queryParameters] - URL query parameters
  /// [options] - Additional request options
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Add interceptor to the client
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Remove interceptor from the client
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// Clear all interceptors except the default ones
  void clearInterceptors() {
    _dio.interceptors.clear();
    // Re-add default logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('🌐 API: $object'),
      ),
    );
  }

  /// Update base options (useful for changing base URL, timeouts, etc.)
  void updateBaseOptions({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
  }) {
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl ?? _dio.options.baseUrl,
      connectTimeout: connectTimeout ?? _dio.options.connectTimeout,
      receiveTimeout: receiveTimeout ?? _dio.options.receiveTimeout,
      sendTimeout: sendTimeout ?? _dio.options.sendTimeout,
      headers: headers != null
          ? {..._dio.options.headers, ...headers}
          : _dio.options.headers,
    );
  }

  /// Handle DioException and convert to custom exceptions
  Exception _handleDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ApiTimeoutException('Bağlantı zaman aşımına uğradı');

      case DioExceptionType.sendTimeout:
        return ApiTimeoutException('İstek gönderilirken zaman aşımı');

      case DioExceptionType.receiveTimeout:
        return ApiTimeoutException('Yanıt alınırken zaman aşımı');

      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode ?? 0;
        final message = _extractErrorMessage(dioException.response);
        return ServerException(statusCode, message);

      case DioExceptionType.cancel:
        return CancellationException('İstek iptal edildi');

      case DioExceptionType.connectionError:
        return NetworkException('İnternet bağlantısını kontrol edin');

      case DioExceptionType.badCertificate:
        return NetworkException('SSL sertifika hatası');

      case DioExceptionType.unknown:
        return NetworkException(
          'Bilinmeyen ağ hatası: ${dioException.message ?? "Beklenmeyen hata"}',
        );
    }
  }

  /// Extract error message from response with multiple fallbacks
  String _extractErrorMessage(Response? response) {
    if (response == null) return 'Sunucudan yanıt alınamadı';

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Try to extract message from response data
    String? message;

    try {
      if (data is Map<String, dynamic>) {
        // Standard error response format
        message = data['message'] as String?;

        // Alternative error field names
        message ??= data['error'] as String?;
        message ??= data['detail'] as String?;
        message ??= data['msg'] as String?;

        // Nested error objects
        if (message == null && data['error'] is Map) {
          final errorObj = data['error'] as Map<String, dynamic>;
          message = errorObj['message'] as String?;
          message ??= errorObj['detail'] as String?;
        }
      } else if (data is String) {
        // Plain text error message
        message = data.isNotEmpty ? data : null;
      }
    } catch (e) {
      // If parsing fails, we'll use fallback messages
      print('⚠️ Error parsing response data: $e');
    }

    // Fallback to status message or default message based on status code
    message ??= response.statusMessage;
    message ??= _getDefaultStatusMessage(statusCode);

    return message;
  }

  /// Get default error message based on HTTP status code
  String _getDefaultStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek';
      case 401:
        return 'Yetkisiz erişim - Giriş yapmanız gerekebilir';
      case 403:
        return 'Erişim engellendi - Yetkiniz bulunmuyor';
      case 404:
        return 'Kaynak bulunamadı';
      case 408:
        return 'İstek zaman aşımına uğradı';
      case 409:
        return 'Çakışma - Bu işlem zaten yapılmış olabilir';
      case 422:
        return 'Gönderilen veriler geçersiz';
      case 429:
        return 'Çok fazla istek - Lütfen bekleyin';
      case 500:
        return 'Sunucu içsel hatası';
      case 502:
        return 'Ağ geçidi hatası';
      case 503:
        return 'Servis kullanılamıyor - Lütfen daha sonra deneyin';
      case 504:
        return 'Ağ geçidi zaman aşımı';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'İstemci hatası ($statusCode)';
        } else if (statusCode >= 500) {
          return 'Sunucu hatası ($statusCode)';
        } else {
          return 'HTTP hatası ($statusCode)';
        }
    }
  }

  /// Get the underlying Dio instance (use with caution)
  Dio get dio => _dio;
}

/// Custom exceptions for different error types
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  final int statusCode;
  final String message;

  ServerException(this.statusCode, this.message);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class ApiTimeoutException implements Exception {
  final String message;
  ApiTimeoutException(this.message);

  @override
  String toString() => 'ApiTimeoutException: $message';
}

class CancellationException implements Exception {
  final String message;
  CancellationException(this.message);

  @override
  String toString() => 'CancellationException: $message';
}
