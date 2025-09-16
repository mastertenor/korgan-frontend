// lib/src/features/mail/domain/entities/organization.dart

/// Organization domain entity for mail module
///
/// Represents an organization that a user belongs to.
/// Used for organization switching functionality in the mail web interface.
///
/// Business rules:
/// - ID must be non-empty
/// - Name must be non-empty
/// - Role determines user permissions (admin or user)
class Organization {
  final String id;
  final String name;
  final String role;

  const Organization({
    required this.id,
    required this.name,
    required this.role,
  });

  // ========== VALIDATION ==========

  /// Check if organization data is valid
  bool get isValid {
    return id.isNotEmpty && name.isNotEmpty && role.isNotEmpty;
  }

  /// Check if user has admin role in this organization
  bool get isAdmin {
    return role.toLowerCase() == 'admin';
  }

  /// Check if user has user role in this organization
  bool get isUser {
    return role.toLowerCase() == 'user';
  }

  // ========== DISPLAY HELPERS ==========

  /// Get user-friendly role name
  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Yönetici';
      case 'user':
        return 'Kullanıcı';
      default:
        return role;
    }
  }

  /// Get organization display name with role
  String get displayNameWithRole {
    return '$name ($roleDisplayName)';
  }

  // ========== EQUALITY & SERIALIZATION ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.id == id &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, role);

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, role: $role)';
  }

  // ========== COPY METHODS ==========

  /// Create a copy with optional field updates
  Organization copyWith({String? id, String? name, String? role}) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
