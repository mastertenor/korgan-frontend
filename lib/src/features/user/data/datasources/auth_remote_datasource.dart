// lib/src/features/auth/data/datasources/auth_remote_datasource.dart

import '../models/auth_login_request_model.dart';
import '../models/auth_login_response_model.dart';
import '../models/auth_refresh_request_model.dart';
import '../models/auth_refresh_response_model.dart';
import '../models/auth_user_response_model.dart';
import '../models/auth_profile_update_request_model.dart';
import '../models/auth_password_change_request_model.dart';

/// Abstract interface for authentication remote data source
///
/// Bu interface Next.js backend'inizdeki auth API endpoints'lerini tanımlar:
/// - POST /api/v1/auth/login
/// - POST /api/v1/auth/refresh
/// - POST /api/v1/auth/logout
/// - GET /api/v1/user/profile
/// - PUT /api/v1/user/profile
/// - PUT /api/v1/user/password
abstract class AuthRemoteDataSource {
  // ========== AUTHENTICATION ==========

  /// Login with email and password
  ///
  /// Endpoint: POST /api/v1/auth/login
  /// Returns: AuthLoginResponseModel with tokens and user data
  Future<AuthLoginResponseModel> login(AuthLoginRequestModel request);

  /// Refresh access token using refresh token
  ///
  /// Endpoint: POST /api/v1/auth/refresh
  /// Returns: AuthRefreshResponseModel with new tokens
  Future<AuthRefreshResponseModel> refreshToken(
    AuthRefreshRequestModel request,
  );

  /// Logout user and invalidate tokens
  ///
  /// Endpoint: POST /api/v1/auth/logout
  /// Returns: void (success/failure handled by exceptions)
  Future<void> logout(String refreshToken);

  // ========== USER PROFILE ==========

  /// Get current authenticated user profile
  ///
  /// Endpoint: GET /api/v1/user/profile
  /// Requires: Valid access token in Authorization header
  /// Returns: AuthUserResponseModel with user data
  Future<AuthUserResponseModel> getCurrentUser();

  /// Update user profile information
  ///
  /// Endpoint: PUT /api/v1/user/profile
  /// Requires: Valid access token in Authorization header
  /// Returns: AuthUserResponseModel with updated user data
  Future<AuthUserResponseModel> updateProfile(
    AuthProfileUpdateRequestModel request,
  );

  /// Change user password
  ///
  /// Endpoint: PUT /api/v1/user/password
  /// Requires: Valid access token in Authorization header
  /// Returns: void (success/failure handled by exceptions)
  Future<void> changePassword(AuthPasswordChangeRequestModel request);

  // ========== UTILITY ==========

  /// Test API connection (health check)
  ///
  /// Endpoint: GET /api/v1/health (or similar public endpoint)
  /// Returns: true if API is reachable
  Future<bool> testConnection();
}
