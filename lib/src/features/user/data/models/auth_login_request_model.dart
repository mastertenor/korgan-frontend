// lib/src/features/auth/data/models/auth_login_request_model.dart

/// Data model for login API request
///
/// Next.js backend endpoint: POST /api/v1/auth/login
/// Request format: {"email": "user@example.com", "password": "password123"}
class AuthLoginRequestModel {
  final String email;
  final String password;

  const AuthLoginRequestModel({required this.email, required this.password});

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  /// Create from JSON (mainly for testing)
  factory AuthLoginRequestModel.fromJson(Map<String, dynamic> json) {
    return AuthLoginRequestModel(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'AuthLoginRequestModel(email: $email, password: [HIDDEN])';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthLoginRequestModel &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);
}
