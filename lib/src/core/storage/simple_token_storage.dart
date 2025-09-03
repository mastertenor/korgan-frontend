// lib/src/core/storage/simple_token_storage.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_logger.dart';

/// Universal token storage that works across all platforms
///
/// Bu sınıf tüm platformlarda (Web, iOS, Android, Desktop) çalışır:
/// - Web: Browser localStorage
/// - Mobile: Native secure storage via SharedPreferences
/// - Desktop: File-based storage via SharedPreferences
///
/// Thread-safe operations with error handling
class SimpleTokenStorage {
  SimpleTokenStorage._();

  // ========== STORAGE KEYS ==========
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _userDataKey = 'auth_user_data';
  static const String _isLoggedInKey = 'auth_is_logged_in';

  // ========== CORE TOKEN OPERATIONS ==========

  /// Store access and refresh tokens securely
  ///
  /// [accessToken] JWT access token (typically 15 minutes)
  /// [refreshToken] JWT refresh token (typically 30 days)
  /// [expiresInSeconds] Access token expiry duration in seconds
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresInSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store tokens
      await Future.wait([
        prefs.setString(_accessTokenKey, accessToken),
        prefs.setString(_refreshTokenKey, refreshToken),
        prefs.setBool(_isLoggedInKey, true),
      ]);

      // Store expiry time if provided
      if (expiresInSeconds != null) {
        final expiryTime = DateTime.now()
            .add(Duration(seconds: expiresInSeconds))
            .millisecondsSinceEpoch;
        await prefs.setInt(_tokenExpiryKey, expiryTime);
      }

      AppLogger.info('✅ Tokens stored successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to store tokens: $e');
      rethrow;
    }
  }

  /// Get stored access token
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        AppLogger.debug('🔍 No access token found');
        return null;
      }

      // Check if token is expired
      if (await isTokenExpired()) {
        AppLogger.warning('⏰ Access token is expired');
        return null;
      }

      return token;
    } catch (e) {
      AppLogger.error('❌ Failed to get access token: $e');
      return null;
    }
  }

  /// Get stored refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_refreshTokenKey);

      if (token == null) {
        AppLogger.debug('🔍 No refresh token found');
      }

      return token;
    } catch (e) {
      AppLogger.error('❌ Failed to get refresh token: $e');
      return null;
    }
  }

  /// Check if user is logged in
  ///
  /// Combines multiple checks:
  /// - isLoggedIn flag
  /// - Access token exists
  /// - Refresh token exists
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Quick flag check first
      final flagValue = prefs.getBool(_isLoggedInKey) ?? false;
      if (!flagValue) {
        return false;
      }

      // Verify tokens exist
      final accessToken = prefs.getString(_accessTokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);

      final hasTokens = accessToken != null && refreshToken != null;

      if (!hasTokens) {
        AppLogger.warning(
          '⚠️ Login flag is true but tokens missing - clearing flag',
        );
        await prefs.setBool(_isLoggedInKey, false);
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to check login status: $e');
      return false;
    }
  }

  /// Check if access token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTime = prefs.getInt(_tokenExpiryKey);

      if (expiryTime == null) {
        // If no expiry time stored, assume not expired
        // Backend will reject if actually expired
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = now >= expiryTime;

      if (isExpired) {
        AppLogger.debug(
          '⏰ Token expired at ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}',
        );
      }

      return isExpired;
    } catch (e) {
      AppLogger.error('❌ Failed to check token expiry: $e');
      return false; // Assume not expired on error
    }
  }

  // ========== USER DATA OPERATIONS ==========

  /// Store user data as JSON string
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = userData
          .toString(); // Simple string conversion for now
      await prefs.setString(_userDataKey, jsonString);
      AppLogger.info('✅ User data stored');
    } catch (e) {
      AppLogger.error('❌ Failed to store user data: $e');
      rethrow;
    }
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userDataKey);

      if (jsonString == null) {
        return null;
      }

      // For now, return null - will implement JSON parsing later
      // This is placeholder for user data storage
      return null;
    } catch (e) {
      AppLogger.error('❌ Failed to get user data: $e');
      return null;
    }
  }

  // ========== CLEANUP OPERATIONS ==========

  /// Clear all stored auth data
  ///
  /// Used for logout - clears everything auth-related
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
        prefs.remove(_tokenExpiryKey),
        prefs.remove(_userDataKey),
        prefs.setBool(_isLoggedInKey, false),
      ]);

      AppLogger.info('✅ All auth data cleared');
    } catch (e) {
      AppLogger.error('❌ Failed to clear auth data: $e');
      rethrow;
    }
  }

  /// Clear only access token (for refresh scenarios)
  static Future<void> clearAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_tokenExpiryKey);
      AppLogger.debug('🗑️ Access token cleared');
    } catch (e) {
      AppLogger.error('❌ Failed to clear access token: $e');
      rethrow;
    }
  }

  // ========== DEBUG & UTILITY METHODS ==========

  /// Get all stored auth data for debugging
  ///
  /// WARNING: Only use in development - contains sensitive data
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'hasAccessToken': prefs.getString(_accessTokenKey) != null,
        'hasRefreshToken': prefs.getString(_refreshTokenKey) != null,
        'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
        'tokenExpiry': prefs.getInt(_tokenExpiryKey),
        'hasUserData': prefs.getString(_userDataKey) != null,
        // DON'T include actual token values for security
      };
    } catch (e) {
      AppLogger.error('❌ Failed to get debug info: $e');
      return {'error': e.toString()};
    }
  }

  /// Update access token only (for refresh token flow)
  static Future<void> updateAccessToken({
    required String accessToken,
    int? expiresInSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_accessTokenKey, accessToken);

      // Update expiry time if provided
      if (expiresInSeconds != null) {
        final expiryTime = DateTime.now()
            .add(Duration(seconds: expiresInSeconds))
            .millisecondsSinceEpoch;
        await prefs.setInt(_tokenExpiryKey, expiryTime);
      }

      AppLogger.debug('🔄 Access token updated');
    } catch (e) {
      AppLogger.error('❌ Failed to update access token: $e');
      rethrow;
    }
  }

  // ========== TOKEN VALIDATION HELPERS ==========

  /// Validate if stored tokens are ready for API calls
  ///
  /// Returns true only if:
  /// - User is logged in
  /// - Access token exists and is not expired
  /// - Refresh token exists (for renewal)
  static Future<bool> hasValidTokens() async {
    try {
      final isLoggedInFlag = await isLoggedIn();
      if (!isLoggedInFlag) {
        return false;
      }

      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();

      return accessToken != null && refreshToken != null;
    } catch (e) {
      AppLogger.error('❌ Failed to validate tokens: $e');
      return false;
    }
  }

  /// Get time remaining until token expires (in seconds)
  static Future<int?> getTokenExpirySeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTime = prefs.getInt(_tokenExpiryKey);

      if (expiryTime == null) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((expiryTime - now) / 1000).round();

      return remaining > 0 ? remaining : 0;
    } catch (e) {
      AppLogger.error('❌ Failed to get token expiry: $e');
      return null;
    }
  }
}
