// lib/src/features/auth/domain/entities/auth_token.dart

/// Authentication token entity
///
/// JWT token pair'ini temsil eden sade entity.
/// Access token (kısa süreli) ve refresh token (uzun süreli) içerir.
/// Mevcut Mail entity pattern'ine uygun yapıda.
class AuthToken {
  /// JWT access token (typically 15 minutes)
  final String accessToken;

  /// JWT refresh token (typically 30 days)
  final String refreshToken;

  /// Token expiration date
  final DateTime? expiresAt;

  /// Token type (typically "Bearer")
  final String tokenType;

  /// Scope/permissions (optional)
  final List<String>? scopes;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
    this.scopes,
  });

  // ========== COMPUTED PROPERTIES ==========

  /// Check if access token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if token will expire soon (within 5 minutes)
  bool get willExpireSoon {
    if (expiresAt == null) return false;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return expiresAt!.isBefore(fiveMinutesFromNow);
  }

  /// Get remaining time until expiration
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Get remaining seconds until expiration
  int get remainingSeconds {
    final duration = timeUntilExpiry;
    if (duration == null) return -1;
    return duration.inSeconds;
  }

  /// Check if tokens are valid (not empty and not expired)
  bool get isValid {
    return accessToken.isNotEmpty && refreshToken.isNotEmpty && !isExpired;
  }

  /// Full authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  // ========== FACTORY CONSTRUCTORS ==========

  /// Create AuthToken from login API response
  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken:
          json['accessToken']?.toString() ??
          json['access_token']?.toString() ??
          '',
      refreshToken:
          json['refreshToken']?.toString() ??
          json['refresh_token']?.toString() ??
          '',
      expiresAt: _parseExpirationDate(json),
      tokenType:
          json['tokenType']?.toString() ??
          json['token_type']?.toString() ??
          'Bearer',
      scopes: _parseScopes(json['scopes'] ?? json['scope']),
    );
  }

  /// Create AuthToken with expiration in seconds
  factory AuthToken.withExpirySeconds({
    required String accessToken,
    required String refreshToken,
    int? expiresInSeconds,
    String tokenType = 'Bearer',
    List<String>? scopes,
  }) {
    DateTime? expiresAt;
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    }

    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      tokenType: tokenType,
      scopes: scopes,
    );
  }

  /// Create empty/invalid token
  factory AuthToken.empty() {
    return const AuthToken(accessToken: '', refreshToken: '');
  }

  /// Create token for testing
  factory AuthToken.test({
    String accessToken = 'test_access_token_123',
    String refreshToken = 'test_refresh_token_456',
    int expiryMinutes = 15,
  }) {
    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(minutes: expiryMinutes)),
      tokenType: 'Bearer',
    );
  }

  // ========== SERIALIZATION ==========

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'tokenType': tokenType,
      'scopes': scopes,
    };
  }

  // ========== COPY WITH METHOD ==========

  /// Create a copy with some fields updated
  AuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    List<String>? scopes,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      scopes: scopes ?? this.scopes,
    );
  }

  /// Update only access token (for refresh scenarios)
  AuthToken updateAccessToken({
    required String newAccessToken,
    DateTime? newExpiresAt,
  }) {
    return copyWith(accessToken: newAccessToken, expiresAt: newExpiresAt);
  }

  // ========== EQUALITY IMPLEMENTATION ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthToken &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);

  @override
  String toString() {
    return 'AuthToken(type: $tokenType, expired: $isExpired, '
        'remaining: ${remainingSeconds}s)';
  }

  // ========== HELPER METHODS ==========

  /// Parse expiration date from various API response formats
  static DateTime? _parseExpirationDate(Map<String, dynamic> json) {
    // Try different field names
    final expiresAt = json['expiresAt'] ?? json['expires_at'];
    if (expiresAt != null) {
      return _parseDateTime(expiresAt);
    }

    // Try expiresIn field (seconds from now)
    final expiresIn = json['expiresIn'] ?? json['expires_in'];
    if (expiresIn != null) {
      final seconds = _parseInt(expiresIn);
      if (seconds != null && seconds > 0) {
        return DateTime.now().add(Duration(seconds: seconds));
      }
    }

    return null;
  }

  /// Parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    if (value is int) {
      try {
        // Assume timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        // Try seconds
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    return null;
  }

  /// Parse integer from dynamic value
  static int? _parseInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Parse scopes list from various formats
  static List<String>? _parseScopes(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      // Handle space-separated scopes (OAuth standard)
      return value.split(' ').where((s) => s.isNotEmpty).toList();
    }

    return null;
  }

  // ========== VALIDATION ==========

  /// Validate JWT token format (basic check)
  static bool isValidJwtFormat(String token) {
    if (token.isEmpty) return false;

    // JWT has 3 parts separated by dots
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  /// Check if access token format is valid
  bool get hasValidAccessTokenFormat => isValidJwtFormat(accessToken);

  /// Check if refresh token format is valid
  bool get hasValidRefreshTokenFormat => isValidJwtFormat(refreshToken);

  /// Check if both tokens have valid formats
  bool get hasValidFormats =>
      hasValidAccessTokenFormat && hasValidRefreshTokenFormat;

  // ========== DEBUGGING ==========

  /// Get debug info (without exposing actual tokens)
  Map<String, dynamic> get debugInfo {
    return {
      'hasAccessToken': accessToken.isNotEmpty,
      'hasRefreshToken': refreshToken.isNotEmpty,
      'tokenType': tokenType,
      'isExpired': isExpired,
      'willExpireSoon': willExpireSoon,
      'remainingSeconds': remainingSeconds,
      'expiresAt': expiresAt?.toIso8601String(),
      'isValid': isValid,
      'hasValidFormats': hasValidFormats,
      'scopes': scopes,
    };
  }
}
