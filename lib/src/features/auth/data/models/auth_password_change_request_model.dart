// lib/src/features/auth/data/models/auth_password_change_request_model.dart

/// Data model for password change API request
///
/// Next.js backend endpoint: PUT /api/v1/user/password
/// Request format: {
///   "currentPassword": "old_password",
///   "newPassword": "new_password"
/// }
class AuthPasswordChangeRequestModel {
  final String currentPassword;
  final String newPassword;

  const AuthPasswordChangeRequestModel({
    required this.currentPassword,
    required this.newPassword,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'currentPassword': currentPassword, 'newPassword': newPassword};
  }

  /// Create from JSON (mainly for testing)
  factory AuthPasswordChangeRequestModel.fromJson(Map<String, dynamic> json) {
    return AuthPasswordChangeRequestModel(
      currentPassword: json['currentPassword']?.toString() ?? '',
      newPassword: json['newPassword']?.toString() ?? '',
    );
  }

  /// Validate request data
  bool get isValid {
    return currentPassword.isNotEmpty &&
        newPassword.isNotEmpty &&
        currentPassword != newPassword;
  }

  @override
  String toString() {
    return 'AuthPasswordChangeRequestModel('
        'hasCurrentPassword: ${currentPassword.isNotEmpty}, '
        'hasNewPassword: ${newPassword.isNotEmpty}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthPasswordChangeRequestModel &&
        other.currentPassword == currentPassword &&
        other.newPassword == newPassword;
  }

  @override
  int get hashCode => Object.hash(currentPassword, newPassword);
}
