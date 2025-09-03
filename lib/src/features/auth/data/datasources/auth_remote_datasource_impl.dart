// lib/src/features/auth/data/datasources/auth_remote_datasource_impl.dart

import '../../../../core/network/api_client.dart';
import '../../../../utils/app_logger.dart';
import '../models/auth_login_request_model.dart';
import '../models/auth_login_response_model.dart';
import '../models/auth_refresh_request_model.dart';
import '../models/auth_refresh_response_model.dart';
import '../models/auth_user_response_model.dart';
import '../models/auth_profile_update_request_model.dart';
import '../models/auth_password_change_request_model.dart';
import 'auth_remote_datasource.dart';

/// Concrete implementation of authentication remote data source
///
/// Bu class Next.js backend'inizdeki auth API endpoints'leriyle iletişim kurar.
/// Mevcut mail pattern'inize uygun olarak ApiClient'ı kullanır.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  /// Constructor - ApiClient dependency injection
  AuthRemoteDataSourceImpl(this._apiClient);

  // ========== AUTHENTICATION ENDPOINTS ==========

@override
  Future<AuthLoginResponseModel> login(AuthLoginRequestModel request) async {
    try {
      AppLogger.info(
        '🔐 Auth DataSource: Attempting login for ${request.email}',
      );

      final response = await _apiClient.post(
        '/api/auth/login', // ✅ v1 kaldırıldı
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        AppLogger.info('✅ Auth DataSource: Login successful');

        // 🔧 FIX: Extract data from server response format
        final responseData = response.data as Map<String, dynamic>;

        // Server wraps response in {success: true, data: {...}}
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;

          // Restructure to match model expectation
          final modelData = {
            'accessToken': data['tokens']?['accessToken'],
            'refreshToken': data['tokens']?['refreshToken'],
            'expiresIn': data['tokens']?['expiresIn'],
            'user': data['user'],
          };

          return AuthLoginResponseModel.fromJson(modelData);
        } else {
          throw Exception('Invalid response format: missing success or data');
        }
      } else {
        AppLogger.error(
          '❌ Auth DataSource: Invalid login response - Status: ${response.statusCode}',
        );
        throw Exception('Invalid response from login API');
      }
    } catch (e) {
      AppLogger.error('❌ Auth DataSource: Login failed - $e');
      rethrow;
    }
  }
  
  @override
  Future<AuthRefreshResponseModel> refreshToken(
    AuthRefreshRequestModel request,
  ) async {
    try {
      AppLogger.info('🔄 Auth DataSource: Attempting token refresh');

      final response = await _apiClient.post(
        '/api/v1/auth/refresh',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        AppLogger.info('✅ Auth DataSource: Token refresh successful');
        return AuthRefreshResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        AppLogger.error(
          '❌ Auth DataSource: Invalid refresh response - Status: ${response.statusCode}',
        );
        throw Exception('Invalid response from refresh API');
      }
    } catch (e) {
      AppLogger.error('❌ Auth DataSource: Token refresh failed - $e');
      rethrow;
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      AppLogger.info('🚪 Auth DataSource: Attempting logout');

      final response = await _apiClient.post(
        '/api/v1/auth/logout',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ Auth DataSource: Logout successful');
      } else {
        AppLogger.warning(
          '⚠️ Auth DataSource: Logout response - Status: ${response.statusCode}',
        );
        // Don't throw - logout should succeed even if server call fails
      }
    } catch (e) {
      AppLogger.warning(
        '⚠️ Auth DataSource: Server logout failed (local logout will continue) - $e',
      );
      // Don't rethrow - logout should always succeed locally even if server fails
    }
  }

  // ========== USER PROFILE ENDPOINTS ==========

@override
  Future<AuthUserResponseModel> getCurrentUser() async {
    try {
      AppLogger.info('👤 Auth DataSource: Fetching current user profile');

      final response = await _apiClient.get('/api/auth/user/profile');

      if (response.statusCode == 200 && response.data != null) {
        AppLogger.info('✅ Auth DataSource: User profile fetched successfully');

        // 🔧 FIX: Extract data from server response format
        final responseData = response.data as Map<String, dynamic>;

        // Server wraps response in {success: true, data: {user: {...}}}
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final userData = data['user'] as Map<String, dynamic>;

          return AuthUserResponseModel.fromJson(userData);
        } else {
          throw Exception('Invalid response format: missing success or data');
        }
      } else {
        AppLogger.error(
          '❌ Auth DataSource: Invalid profile response - Status: ${response.statusCode}',
        );
        throw Exception('Invalid response from profile API');
      }
    } catch (e) {
      AppLogger.error('❌ Auth DataSource: Failed to fetch user profile - $e');
      rethrow;
    }
  }

  @override
  Future<AuthUserResponseModel> updateProfile(
    AuthProfileUpdateRequestModel request,
  ) async {
    try {
      AppLogger.info('📝 Auth DataSource: Updating user profile');

      final response = await _apiClient.put(
        '/api/v1/user/profile',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        AppLogger.info('✅ Auth DataSource: Profile updated successfully');
        return AuthUserResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        AppLogger.error(
          '❌ Auth DataSource: Invalid profile update response - Status: ${response.statusCode}',
        );
        throw Exception('Invalid response from profile update API');
      }
    } catch (e) {
      AppLogger.error('❌ Auth DataSource: Profile update failed - $e');
      rethrow;
    }
  }

  @override
  Future<void> changePassword(AuthPasswordChangeRequestModel request) async {
    try {
      AppLogger.info('🔒 Auth DataSource: Attempting password change');

      final response = await _apiClient.put(
        '/api/v1/user/password',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ Auth DataSource: Password changed successfully');
      } else {
        AppLogger.error(
          '❌ Auth DataSource: Invalid password change response - Status: ${response.statusCode}',
        );
        throw Exception('Invalid response from password change API');
      }
    } catch (e) {
      AppLogger.error('❌ Auth DataSource: Password change failed - $e');
      rethrow;
    }
  }

  // ========== UTILITY ENDPOINTS ==========

  @override
  Future<bool> testConnection() async {
    try {
      AppLogger.info('🏥 Auth DataSource: Testing API connection');

      // Try to hit a public health check endpoint
      final response = await _apiClient.get('/api/v1/health');

      final isHealthy = response.statusCode == 200;

      if (isHealthy) {
        AppLogger.info('✅ Auth DataSource: API connection healthy');
      } else {
        AppLogger.warning(
          '⚠️ Auth DataSource: API connection unhealthy - Status: ${response.statusCode}',
        );
      }

      return isHealthy;
    } catch (e) {
      AppLogger.error('❌ Auth DataSource: API connection test failed - $e');
      return false;
    }
  }
}
