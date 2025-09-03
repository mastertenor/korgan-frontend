// lib/src/features/auth/data/models/auth_refresh_response_model.dart

import '../../domain/entities/auth_token.dart';

/// Data model for token refresh API response
///
/// Next.js backend endpoint: POST /api/v1/auth/refresh
/// Response format: {
///   "accessToken": "new_jwt_access_token",
///   "refreshToken": "new_jwt_refresh_token", // Optional - only if rotation enabled
///   "expiresIn": 900,
///   "tokenType": "Bearer"
/// }
class AuthRefreshResponseModel {
  final String accessToken;
  final String? refreshToken; // Optional - refresh token rotation
  final int? expiresIn; // seconds
  final String tokenType;

  const AuthRefreshResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.tokenType = 'Bearer',
  });

  /// Create from API JSON response
  factory AuthRefreshResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthRefreshResponseModel(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(), // Might be null
      expiresIn: json['expiresIn'] as int?,
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
    );
  }

  /// Convert to JSON (mainly for testing)
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'accessToken': accessToken,
      'tokenType': tokenType,
    };

    if (refreshToken != null) {
      result['refreshToken'] = refreshToken!;
    }

    if (expiresIn != null) {
      result['expiresIn'] = expiresIn!;
    }

    return result;
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain AuthToken entity
  ///
  /// Note: If refreshToken is null, it means no rotation -
  /// the existing refresh token should be kept
  AuthToken toAuthToken({String? existingRefreshToken}) {
    return AuthToken.withExpirySeconds(
      accessToken: accessToken,
      refreshToken: refreshToken ?? existingRefreshToken ?? '',
      expiresInSeconds: expiresIn,
      tokenType: tokenType,
    );
  }

  // ========== VALIDATION ==========

  /// Check if response contains valid access token
  bool get isValid {
    return accessToken.isNotEmpty;
  }

  /// Check if refresh token rotation occurred
  bool get hasRefreshTokenRotation {
    return refreshToken != null && refreshToken!.isNotEmpty;
  }

  @override
  String toString() {
    return 'AuthRefreshResponseModel('
        'tokenType: $tokenType, '
        'expiresIn: $expiresIn, '
        'hasAccessToken: ${accessToken.isNotEmpty}, '
        'hasRefreshTokenRotation: $hasRefreshTokenRotation'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthRefreshResponseModel &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);
}
