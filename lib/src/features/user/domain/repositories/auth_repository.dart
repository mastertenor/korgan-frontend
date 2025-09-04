// lib/src/features/auth/domain/repositories/auth_repository.dart

import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../entities/auth_token.dart';

/// Abstract repository interface for authentication operations
///
/// Bu interface domain layer'da tanımlı business logic'i temsil eder.
/// Data layer'daki AuthRepositoryImpl bu interface'i implement eder.
/// Mail repository pattern'inize uygun şekilde tasarlanmış.
abstract class AuthRepository {
  // ========== AUTHENTICATION ==========

  /// Login with email and password
  ///
  /// Returns both AuthToken and User on successful login
  /// Business rules:
  /// - Email must be valid format
  /// - Password must be at least 6 characters
  /// - Tokens are automatically stored
  Future<Result<({AuthToken token, User user})>> login({
    required String email,
    required String password,
  });

  /// Refresh access token using stored refresh token
  ///
  /// Returns true on successful refresh
  /// Business rules:
  /// - Must have valid refresh token in storage
  /// - New tokens are automatically stored
  /// - Handles both rotation and non-rotation scenarios
  Future<Result<bool>> refreshToken();

  /// Logout current user
  ///
  /// Business rules:
  /// - Always succeeds (even if server call fails)
  /// - Clears local storage first
  /// - Attempts server logout (best effort)
  Future<Result<void>> logout();

  // ========== USER PROFILE ==========

  /// Get current authenticated user profile
  ///
  /// Business rules:
  /// - Requires valid access token
  /// - Updates stored user data on success
  Future<Result<User>> getCurrentUser();

  /// Update user profile information
  ///
  /// Business rules:
  /// - At least one field must be provided for update
  /// - Updates stored user data on success
  Future<Result<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
  });

  /// Change user password
  ///
  /// Business rules:
  /// - Current password required for verification
  /// - New password must be different from current
  /// - Password must meet strength requirements
  Future<Result<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // ========== AUTH STATE ==========

  /// Check if user is currently authenticated
  ///
  /// Business rules:
  /// - Checks local storage first
  /// - Validates token existence and expiry
  /// - Clears invalid tokens automatically
  Future<Result<bool>> isAuthenticated();

  /// Test API connection
  ///
  /// Used for health checks and connectivity testing
  Future<Result<bool>> testConnection();
}
