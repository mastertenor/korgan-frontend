// lib/src/features/auth/data/models/auth_profile_update_request_model.dart

/// Data model for profile update API request
///
/// Next.js backend endpoint: PUT /api/v1/user/profile
/// Request format: {
///   "firstName": "John",
///   "lastName": "Doe",
///   "profilePictureUrl": "https://..."
/// }
class AuthProfileUpdateRequestModel {
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;

  const AuthProfileUpdateRequestModel({
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    if (firstName != null && firstName!.isNotEmpty) {
      result['firstName'] = firstName!;
    }

    if (lastName != null && lastName!.isNotEmpty) {
      result['lastName'] = lastName!;
    }

    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      result['profilePictureUrl'] = profilePictureUrl!;
    }

    return result;
  }

  /// Create from JSON (mainly for testing)
  factory AuthProfileUpdateRequestModel.fromJson(Map<String, dynamic> json) {
    return AuthProfileUpdateRequestModel(
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      profilePictureUrl: json['profilePictureUrl']?.toString(),
    );
  }

  /// Check if request has any updates
  bool get hasUpdates {
    return (firstName != null && firstName!.isNotEmpty) ||
        (lastName != null && lastName!.isNotEmpty) ||
        (profilePictureUrl != null && profilePictureUrl!.isNotEmpty);
  }

  @override
  String toString() {
    return 'AuthProfileUpdateRequestModel('
        'firstName: $firstName, '
        'lastName: $lastName, '
        'hasProfilePicture: ${profilePictureUrl != null}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthProfileUpdateRequestModel &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.profilePictureUrl == profilePictureUrl;
  }

  @override
  int get hashCode => Object.hash(firstName, lastName, profilePictureUrl);
}
