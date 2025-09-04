// lib/src/features/auth/data/models/auth_user_response_model.dart

import '../../domain/entities/user.dart';

/// Data model for user profile API responses
///
/// Used by multiple endpoints:
/// - GET /api/v1/user/profile (get current user)
/// - PUT /api/v1/user/profile (update profile - returns updated user)
///
/// Response format: {
///   "id": "user_123",
///   "email": "user@example.com",
///   "firstName": "John",
///   "lastName": "Doe",
///   "role": "user",
///   "profilePictureUrl": "https://...",
///   "isEmailVerified": true,
///   "isActive": true,
///   "createdAt": "2024-01-01T00:00:00Z",
///   "updatedAt": "2024-01-15T12:00:00Z"
/// }
class AuthUserResponseModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? profilePictureUrl;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthUserResponseModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePictureUrl,
    this.isEmailVerified = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from API JSON response
  factory AuthUserResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthUserResponseModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName:
          json['firstName']?.toString() ?? json['first_name']?.toString() ?? '',
      lastName:
          json['lastName']?.toString() ?? json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      profilePictureUrl:
          json['profilePictureUrl']?.toString() ??
          json['profile_picture_url']?.toString(),
      isEmailVerified:
          json['isEmailVerified'] ?? json['is_email_verified'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  /// Convert to JSON (mainly for testing)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain User entity
  User toDomain() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      profilePictureUrl: profilePictureUrl,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ========== HELPER METHODS ==========

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
        return null;
      }
    }

    return null;
  }

  // ========== VALIDATION ==========

  /// Check if response contains valid user data
  bool get isValid {
    return id.isNotEmpty && email.isNotEmpty;
  }

  /// Full name computed property
  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'AuthUserResponseModel('
        'id: $id, '
        'email: $email, '
        'name: $fullName, '
        'role: $role, '
        'isActive: $isActive'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUserResponseModel &&
        other.id == id &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, email);
}
