// lib/src/features/auth/domain/entities/user.dart

/// User entity representing authenticated user data
///
/// Bu entity Next.js backend'inden gelen user response'ına uygun olarak tasarlandı.
/// Mevcut Mail entity pattern'ine uygun sade yapıda.
class User {
  /// Unique user identifier
  final String id;

  /// User email address (used for login)
  final String email;

  /// User's first name
  final String firstName;

  /// User's last name
  final String lastName;

  /// User role (admin, user, etc.)
  final String role;

  /// Profile picture URL (optional)
  final String? profilePictureUrl;

  /// Account creation date
  final DateTime? createdAt;

  /// Last update date
  final DateTime? updatedAt;

  /// Email verification status
  final bool isEmailVerified;

  /// Account active status
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePictureUrl,
    this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.isActive = true,
  });

  // ========== COMPUTED PROPERTIES ==========

  /// Full name computed property
  String get fullName => '$firstName $lastName';

  /// Display name (full name or email if names are empty)
  String get displayName {
    final name = fullName.trim();
    return name.isNotEmpty ? name : email;
  }

  /// User initials for avatar
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

    if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
      return '$firstInitial$lastInitial';
    } else if (firstInitial.isNotEmpty) {
      return firstInitial;
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    } else {
      return 'U';
    }
  }

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user can manage other users
  bool get canManageUsers => isAdmin;

  /// Check if user profile is complete
  bool get isProfileComplete {
    return firstName.isNotEmpty && lastName.isNotEmpty && email.isNotEmpty;
  }

  // ========== FACTORY CONSTRUCTORS ==========

  /// Create User from JSON (from API response)
  ///
  /// Backend response format'ına uygun parsing
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      isEmailVerified:
          json['isEmailVerified'] ?? json['is_email_verified'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  /// Create empty/guest user
  factory User.empty() {
    return const User(
      id: '',
      email: '',
      firstName: '',
      lastName: '',
      role: 'guest',
    );
  }

  /// Create user for testing
  factory User.test({
    String id = 'test_user_123',
    String email = 'test@example.com',
    String firstName = 'Test',
    String lastName = 'User',
    String role = 'user',
  }) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      isEmailVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ========== SERIALIZATION ==========

  /// Convert User to JSON (for storage/API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
    };
  }

  // ========== COPY WITH METHOD ==========

  /// Create a copy with some fields updated
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  // ========== EQUATABLE IMPLEMENTATION ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $fullName, role: $role)';
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

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Check if this user instance is valid
  bool get isValid {
    return id.isNotEmpty &&
        email.isNotEmpty &&
        isValidEmail(email) &&
        firstName.isNotEmpty &&
        lastName.isNotEmpty;
  }

  /// Check if this is an empty/guest user
  bool get isEmpty => id.isEmpty || email.isEmpty;
}
