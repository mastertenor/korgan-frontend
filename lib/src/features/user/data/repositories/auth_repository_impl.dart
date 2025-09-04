// lib/src/features/auth/data/repositories/auth_repository_impl.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/simple_token_storage.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_login_request_model.dart';
import '../models/auth_refresh_request_model.dart';
import '../models/auth_profile_update_request_model.dart';
import '../models/auth_password_change_request_model.dart';

/// Implementation of authentication repository
///
/// Bu class domain layer ile data layer arasındaki koordinasyonu sağlar.
/// Mevcut mail pattern'inize uygun olarak:
/// - Exception'ları Failure'lara çevirir
/// - Token storage koordinasyonu yapar
/// - Business logic uygular
/// - Result pattern kullanır
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  // ========== AUTHENTICATION ==========

  @override
  Future<Result<({AuthToken token, User user})>> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔐 Auth Repository: Login attempt for $email');

      // Validate input
      if (!_isValidEmail(email)) {
        return Failure(failures.ValidationFailure.invalidEmail(email: email));
      }

      if (password.isEmpty || password.length < 6) {
        return Failure(failures.ValidationFailure.invalidPassword());
      }

      // Create request model
      final request = AuthLoginRequestModel(email: email, password: password);

      // Call remote data source
      final response = await _remoteDataSource.login(request);

      // Validate response
      if (!response.isValid) {
        return Failure(failures.AuthFailure.invalidCredentials());
      }

      // Convert to domain objects
      final domainObjects = response.toDomain();
      final authToken = domainObjects.token;
      final user = domainObjects.user;

      // Store tokens securely
      await SimpleTokenStorage.storeTokens(
        accessToken: authToken.accessToken,
        refreshToken: authToken.refreshToken,
        expiresInSeconds: authToken.remainingSeconds > 0
            ? authToken.remainingSeconds
            : null,
      );

      // Store user data
      await SimpleTokenStorage.storeUserData(user.toJson());

      AppLogger.info('✅ Auth Repository: Login successful for $email');

      return Success((token: authToken, user: user));
    } on ServerException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Server error during login - ${e.message}',
      );
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Network error during login - ${e.message}',
      );
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      AppLogger.error('❌ Auth Repository: Unexpected login error - $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Giriş yapılamadı: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<bool>> refreshToken() async {
    try {
      AppLogger.info('🔄 Auth Repository: Token refresh attempt');

      // Get stored refresh token
      final storedRefreshToken = await SimpleTokenStorage.getRefreshToken();
      if (storedRefreshToken == null) {
        AppLogger.warning('⚠️ Auth Repository: No refresh token available');
        return Failure(failures.AuthFailure.noRefreshToken());
      }

      // Create request model
      final request = AuthRefreshRequestModel(refreshToken: storedRefreshToken);

      // Call remote data source
      final response = await _remoteDataSource.refreshToken(request);

      // Validate response
      if (!response.isValid) {
        AppLogger.error('❌ Auth Repository: Invalid refresh token response');
        return Failure(failures.AuthFailure.invalidRefreshToken());
      }

      // Convert to domain object
      final authToken = response.toAuthToken(
        existingRefreshToken: storedRefreshToken,
      );

      // Update stored tokens
      if (response.hasRefreshTokenRotation) {
        // Full token rotation - store both new tokens
        await SimpleTokenStorage.storeTokens(
          accessToken: authToken.accessToken,
          refreshToken: authToken.refreshToken,
          expiresInSeconds: authToken.remainingSeconds > 0
              ? authToken.remainingSeconds
              : null,
        );
        AppLogger.info(
          '✅ Auth Repository: Token refresh successful (with rotation)',
        );
      } else {
        // Only access token updated - keep existing refresh token
        await SimpleTokenStorage.updateAccessToken(
          accessToken: authToken.accessToken,
          expiresInSeconds: authToken.remainingSeconds > 0
              ? authToken.remainingSeconds
              : null,
        );
        AppLogger.info(
          '✅ Auth Repository: Token refresh successful (access token only)',
        );
      }

      return const Success(true);
    } on ServerException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Server error during token refresh - ${e.message}',
      );
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Network error during token refresh - ${e.message}',
      );
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      AppLogger.error('❌ Auth Repository: Unexpected token refresh error - $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Token yenilenemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      AppLogger.info('🚪 Auth Repository: Logout attempt');

      // Get refresh token for server logout
      final refreshToken = await SimpleTokenStorage.getRefreshToken();

      // Clear local storage first (even if server call fails)
      await SimpleTokenStorage.clearAll();
      AppLogger.info('🗑️ Auth Repository: Local tokens cleared');

      // Attempt server logout (best effort)
      if (refreshToken != null) {
        await _remoteDataSource.logout(refreshToken);
      }

      AppLogger.info('✅ Auth Repository: Logout completed');
      return const Success(null);
    } catch (e) {
      AppLogger.warning(
        '⚠️ Auth Repository: Logout error (local logout successful) - $e',
      );
      // Even on error, local logout succeeded - return success
      return const Success(null);
    }
  }

  // ========== USER PROFILE ==========

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      AppLogger.info('👤 Auth Repository: Fetching current user');

      // Call remote data source
      final response = await _remoteDataSource.getCurrentUser();

      // Validate response
      if (!response.isValid) {
        return Failure(failures.AuthFailure.invalidUserData());
      }

      // Convert to domain object
      final user = response.toDomain();

      // Update stored user data
      await SimpleTokenStorage.storeUserData(user.toJson());

      AppLogger.info('✅ Auth Repository: Current user fetched successfully');
      return Success(user);
    } on ServerException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Server error fetching user - ${e.message}',
      );
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Network error fetching user - ${e.message}',
      );
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      AppLogger.error('❌ Auth Repository: Unexpected error fetching user - $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Kullanıcı bilgileri getirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
  }) async {
    try {
      AppLogger.info('📝 Auth Repository: Updating user profile');

      // Create request model
      final request = AuthProfileUpdateRequestModel(
        firstName: firstName,
        lastName: lastName,
        profilePictureUrl: profilePictureUrl,
      );

      // Validate request
      if (!request.hasUpdates) {
        return Failure(failures.ValidationFailure.noUpdates());
      }

      // Call remote data source
      final response = await _remoteDataSource.updateProfile(request);

      // Validate response
      if (!response.isValid) {
        return Failure(failures.AuthFailure.invalidUserData());
      }

      // Convert to domain object
      final user = response.toDomain();

      // Update stored user data
      await SimpleTokenStorage.storeUserData(user.toJson());

      AppLogger.info('✅ Auth Repository: Profile updated successfully');
      return Success(user);
    } on ServerException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Server error updating profile - ${e.message}',
      );
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Network error updating profile - ${e.message}',
      );
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Unexpected error updating profile - $e',
      );
      return Failure(
        failures.AppFailure.unknown(
          message: 'Profil güncellenemedi: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('🔒 Auth Repository: Changing password');

      // Create request model
      final request = AuthPasswordChangeRequestModel(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Validate request
      if (!request.isValid) {
        return Failure(failures.ValidationFailure.invalidPassword());
      }

      // Call remote data source
      await _remoteDataSource.changePassword(request);

      AppLogger.info('✅ Auth Repository: Password changed successfully');
      return const Success(true);
    } on ServerException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Server error changing password - ${e.message}',
      );
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Network error changing password - ${e.message}',
      );
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      AppLogger.error(
        '❌ Auth Repository: Unexpected error changing password - $e',
      );
      return Failure(
        failures.AppFailure.unknown(
          message: 'Şifre değiştirilemedi: ${e.toString()}',
        ),
      );
    }
  }

  // ========== AUTH STATE ==========

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      // Check local storage first
      final isLoggedIn = await SimpleTokenStorage.isLoggedIn();
      if (!isLoggedIn) {
        return const Success(false);
      }

      // Check token validity
      final hasValidTokens = await SimpleTokenStorage.hasValidTokens();
      if (!hasValidTokens) {
        AppLogger.warning(
          '⚠️ Auth Repository: Invalid tokens - clearing auth state',
        );
        await SimpleTokenStorage.clearAll();
        return const Success(false);
      }

      return const Success(true);
    } catch (e) {
      AppLogger.error('❌ Auth Repository: Error checking auth state - $e');
      return const Success(false);
    }
  }

  @override
  Future<Result<bool>> testConnection() async {
    try {
      final isHealthy = await _remoteDataSource.testConnection();
      return Success(isHealthy);
    } catch (e) {
      AppLogger.error('❌ Auth Repository: Connection test failed - $e');
      return const Success(false);
    }
  }

  // ========== HELPER METHODS ==========

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Map ServerException to appropriate Failure
  failures.Failure _mapServerExceptionToFailure(ServerException exception) {
    switch (exception.statusCode) {
      case 401:
        return failures.AuthFailure.invalidCredentials();
      case 403:
        return failures.AuthFailure.accessDenied();
      case 404:
        return failures.AuthFailure.userNotFound();
      case 422:
        return failures.ValidationFailure.invalidData(
          message: exception.message,
        );
      case 429:
        return failures.NetworkFailure.tooManyRequests();
      case 500:
      case 502:
      case 503:
      case 504:
        return failures.ServerFailure.internalError(message: exception.message);
      default:
        return failures.AppFailure.unknown(message: exception.message);
    }
  }

  /// Map NetworkException to appropriate Failure
  failures.Failure _mapNetworkExceptionToFailure(NetworkException exception) {
    return failures.NetworkFailure.connectionError(message: exception.message);
  }
}
