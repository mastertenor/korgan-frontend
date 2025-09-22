// lib/src/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/simple_token_storage.dart';
import '../../routing/app_router.dart';

/// Stateless token refresh fonksiyonu - Riverpod'dan bağımsız
/// Bu fonksiyon F5 sonrası da çalışır çünkü provider'lara bağlı değil
Future<bool> refreshAccessTokenStateless() async {
  try {
    final refreshToken = await SimpleTokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      print('❌ Refresh token bulunamadı');
      return false;
    }

    print('🔄 Attempting token refresh with stateless function...');

    // Dio instance üzerinden direkt çağrı
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiClient.instance._dio.options.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    try {
      final response = await dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      print('🔄 Refresh response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // Backend formatı: data.tokens altında
        final success = responseData['success'] as bool?;
        final tokens = responseData['data']?['tokens'] as Map<String, dynamic>?;

        if (success == true && tokens != null) {
          final newAccessToken = tokens['accessToken'] as String?;
          final newRefreshToken = tokens['refreshToken'] as String?;
          final expiresIn = tokens['expiresIn'] as int?;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            // Token'ları kaydet
            await SimpleTokenStorage.storeTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken ?? refreshToken,
              expiresInSeconds: expiresIn,
            );

            print('✅ Token refresh başarılı (stateless)');
            print('✅ New token expiry: ${expiresIn ?? "unknown"} seconds');
            return true;
          } else {
            print('❌ Refresh response missing accessToken');
            return false;
          }
        } else {
          print('❌ Refresh response success=false or missing tokens');
          print('Response data: $responseData');
          return false;
        }
      } else {
        print('❌ Refresh failed with status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      print('❌ Refresh DioException: ${e.type} - ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return false;
    }
  } catch (e) {
    print('❌ Token refresh exception: $e');
    return false;
  }
}

/// 🆕 Organization storage helper functions
Future<String?> _getSelectedOrganizationId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString('selected_organization_id');

    // 🔍 DEBUG LOG EKLE
    print('🔍 DEBUG - Organization ID from storage: $orgId');
    print('🔍 DEBUG - All SharedPrefs keys: ${prefs.getKeys()}');

    return orgId;
  } catch (e) {
    print('❌ Error getting organization ID: $e');
    return null;
  }
}

Future<void> saveSelectedOrganizationId(String organizationId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_organization_id', organizationId);
    print('💾 Organization saved: $organizationId');
  } catch (e) {
    print('❌ Error saving organization ID: $e');
  }
}

Future<void> clearSelectedOrganizationId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_organization_id');
    print('🧹 Organization ID cleared');
  } catch (e) {
    print('❌ Error clearing organization ID: $e');
  }
}

/// Core API client - Stateless interceptor + Self-healing kombinasyonu
class ApiClient {
  late final Dio _dio;
  InterceptorsWrapper? _authInterceptor;

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  ApiClient._internal() {
    // Platform bazlı base URL
    final String baseUrl = kIsWeb
        ? const String.fromEnvironment(
            'WEB_API_BASE',
            defaultValue: 'http://192.168.0.242:3000',
          )
        : const String.fromEnvironment(
            'MOBILE_API_BASE',
            defaultValue: 'http://192.168.0.242:3000',
          );

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        responseType: ResponseType.json,
      ),
    );

    // Development logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (object) => print('🌐 API: $object'),
      ),
    );

    // Otomatik interceptor kurulumu
    _ensureStatelessInterceptor();
  }

  factory ApiClient() => instance;

  /// Stateless auth interceptor kurulumu
  /// Her request'te token'ı storage'dan okur, 401'de refresh yapar
  void _ensureStatelessInterceptor() {
    // Önceki interceptor'ı kaldır (çift ekleme koruması)
    if (_authInterceptor != null) {
      _dio.interceptors.remove(_authInterceptor!);
      _authInterceptor = null;
      print('🔄 Mevcut auth interceptor kaldırıldı');
    }

    _authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Refresh endpoint'ine dokunma (loop koruması)
        if (options.path.contains('/auth/refresh')) {
          return handler.next(options);
        }

        // Skip auth header flag'i varsa dokunma
        if (options.headers['skipAuthInterceptor'] == 'true') {
          options.headers.remove('skipAuthInterceptor');
          return handler.next(options);
        }

        // 🆕 Organization header injection
        await _injectOrganizationHeader(options);

        // Token'ı HER İSTEKTE storage'dan oku (stale token sorunu yok)
        try {
          final token = await SimpleTokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔐 Added auth header to request: ${options.path}');
          } else {
            print('⚠️ No token available for request: ${options.path}');
          }
        } catch (e) {
          print('❌ Error getting token for request: $e');
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 değilse veya refresh endpoint'i ise dokunma
        if (error.response?.statusCode != 401 ||
            error.requestOptions.path.contains('/auth/refresh')) {
          return handler.next(error);
        }

        print('🔄 401 alındı - Token refresh deneniyor...');

        try {
          // Stateless refresh fonksiyonunu çağır
          final refreshSuccess = await refreshAccessTokenStateless();

          if (!refreshSuccess) {
            print('❌ Token refresh başarısız');
            // Token'ları temizle ve login'e yönlendir
            await SimpleTokenStorage.clearAll();
            AppRouter.goToLogin();
            return handler.next(error);
          }

          print('✅ Token yenilendi - İsteği tekrarlıyorum');

          // Yeni token ile isteği tekrarla
          final newToken = await SimpleTokenStorage.getAccessToken();
          if (newToken != null) {
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            // 🆕 Re-inject organization header on retry
            await _injectOrganizationHeader(error.requestOptions);
          }

          final retryResponse = await _dio.fetch(error.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          print('❌ Token refresh exception: $e');
          await SimpleTokenStorage.clearAll();
          AppRouter.goToLogin(); // Bu satırı ekleyin
          return handler.next(error);
        }
      },
    );

    _dio.interceptors.add(_authInterceptor!);
    print('✅ Stateless auth interceptor kuruldu');
  }

  /// 🆕 Organization header injection
  Future<void> _injectOrganizationHeader(RequestOptions options) async {
    try {
      // Skip organization header for certain endpoints
      if (_shouldSkipOrganizationHeader(options)) {
        return;
      }

      final organizationId = await _getSelectedOrganizationId();
      if (organizationId != null && organizationId.isNotEmpty) {
        options.headers['X-Organization-ID'] = organizationId;
        print(
          '🏢 Added organization header: $organizationId to ${options.path}',
        );
      }
    } catch (e) {
      print('❌ Error injecting organization header: $e');
      // Don't fail request if organization injection fails
    }
  }

  /// 🆕 Check if should skip organization header
  bool _shouldSkipOrganizationHeader(RequestOptions options) {
    final path = options.path.toLowerCase();
    final skipPaths = [
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/refresh',
      '/api/auth/logout',
      '/api/auth/user/organizations',
      '/api/health',
      '/api/public',
    ];
    return skipPaths.any((skipPath) => path.contains(skipPath));
  }

  /// Public method - AuthNotifier için (opsiyonel kullanım)
  void setupAuthInterceptor() {
    _ensureStatelessInterceptor();
  }

  /// Interceptor'ı kaldır (logout için)
  void removeAuthInterceptor() {
    if (_authInterceptor != null) {
      _dio.interceptors.remove(_authInterceptor!);
      _authInterceptor = null;
      print('🗑️ Auth interceptor kaldırıldı');
    }
  }

  /// Interceptor durumunu kontrol et
  bool get hasAuthInterceptor => _authInterceptor != null;

  /// Self-healing mekanizması - Her HTTP çağrısında kontrol
  Future<void> _ensureInterceptorBeforeRequest() async {
    if (_authInterceptor == null) {
      final hasTokens = await SimpleTokenStorage.hasValidTokens();
      if (hasTokens) {
        print('🔧 Interceptor eksik - otomatik kuruluyor...');
        _ensureStatelessInterceptor();
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  // ========== HTTP METHODS ==========

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInterceptorBeforeRequest(); // Self-healing

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

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInterceptorBeforeRequest(); // Self-healing

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

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInterceptorBeforeRequest(); // Self-healing

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

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureInterceptorBeforeRequest(); // Self-healing

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

  // ========== ERROR HANDLING ==========

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

  String _extractErrorMessage(Response? response) {
    if (response == null) return 'Sunucudan yanıt alınamadı';

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    String? message;

    try {
      if (data is Map<String, dynamic>) {
        message = data['message'] as String?;
        message ??= data['error'] as String?;
        message ??= data['detail'] as String?;
        message ??= data['msg'] as String?;

        if (message == null && data['error'] is Map) {
          final errorObj = data['error'] as Map<String, dynamic>;
          message = errorObj['message'] as String?;
          message ??= errorObj['detail'] as String?;
        }
      } else if (data is String) {
        message = data.isNotEmpty ? data : null;
      }
    } catch (e) {
      print('⚠️ Error parsing response data: $e');
    }

    message ??= response.statusMessage;
    message ??= _getDefaultStatusMessage(statusCode);

    return message;
  }

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

  Dio get dio => _dio;
}

// Exception sınıfları
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
