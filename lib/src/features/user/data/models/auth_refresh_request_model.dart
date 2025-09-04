// lib/src/features/auth/data/models/auth_refresh_request_model.dart

/// Data model for token refresh API request
///
/// Next.js backend endpoint: POST /api/v1/auth/refresh
/// Request format: {"refreshToken": "jwt_refresh_token"}
class AuthRefreshRequestModel {
  final String refreshToken;

  const AuthRefreshRequestModel({required this.refreshToken});

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }

  /// Create from JSON (mainly for testing)
  factory AuthRefreshRequestModel.fromJson(Map<String, dynamic> json) {
    return AuthRefreshRequestModel(
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'AuthRefreshRequestModel(hasRefreshToken: ${refreshToken.isNotEmpty})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthRefreshRequestModel &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode => refreshToken.hashCode;
}
