// lib/src/features/auth/data/models/auth_login_response_model.dart

import '../../domain/entities/user.dart';
import '../../domain/entities/auth_token.dart';

/// Data model for login API response
///
/// Next.js backend endpoint: POST /api/v1/auth/login
/// Response format: {
///   "accessToken": "jwt_access_token",
///   "refreshToken": "jwt_refresh_token",
///   "expiresIn": 900,
///   "user": { "id": "123", "email": "user@example.com", ... }
/// }
class AuthLoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn; // seconds
  final String tokenType;
  final Map<String, dynamic> user;

  const AuthLoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.tokenType = 'Bearer',
    required this.user,
  });

  /// Create from API JSON response
  factory AuthLoginResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponseModel(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn'] as int?,
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      user: json['user'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON (mainly for testing)
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      if (expiresIn != null) 'expiresIn': expiresIn,
      'tokenType': tokenType,
      'user': user,
    };
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain AuthToken entity
  AuthToken toAuthToken() {
    return AuthToken.withExpirySeconds(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresIn,
      tokenType: tokenType,
    );
  }

  /// Convert user data to domain User entity
  User toUser() {
    return User.fromJson(user);
  }

  /// Convert full response to domain objects
  ({AuthToken token, User user}) toDomain() {
    return (token: toAuthToken(), user: toUser());
  }

  // ========== VALIDATION ==========

  /// Check if response contains valid data
  bool get isValid {
    return accessToken.isNotEmpty && refreshToken.isNotEmpty && user.isNotEmpty;
  }

  @override
  String toString() {
    return 'AuthLoginResponseModel('
        'tokenType: $tokenType, '
        'expiresIn: $expiresIn, '
        'hasAccessToken: ${accessToken.isNotEmpty}, '
        'hasRefreshToken: ${refreshToken.isNotEmpty}, '
        'userEmail: ${user['email']}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthLoginResponseModel &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);
}
