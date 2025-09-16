// lib/src/features/organization/domain/entities/organization.dart

/// Organization domain entity for all modules
///
/// Represents an organization that a user belongs to.
/// Used for organization switching functionality across all application modules.
///
/// Business rules:
/// - ID must be non-empty
/// - Name must be non-empty
/// - Slug must be non-empty and URL-safe
/// - Role determines user permissions (admin, user, etc.)
class Organization {
  final String id;
  final String name;
  final String slug; // ✅ YENİ: URL-safe organizasyon slug'ı
  final String role;
  final List<String> permissions; // ✅ YENİ: Kullanıcı yetkileri
  final Map<String, dynamic> settings; // ✅ YENİ: Organizasyon ayarları
  final String createdAt; // ✅ YENİ: Oluşturulma tarihi

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.permissions,
    required this.settings,
    required this.createdAt,
  });

  // ========== VALIDATION ==========

  /// Check if organization data is valid
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        slug.isNotEmpty &&
        role.isNotEmpty;
  }

  /// Check if slug is URL-safe
  bool get hasValidSlug {
    return RegExp(r'^[a-z0-9-]+$').hasMatch(slug);
  }

  /// Check if user has admin role in this organization
  bool get isAdmin {
    return role.toLowerCase() == 'admin';
  }

  /// Check if user has user role in this organization
  bool get isUser {
    return role.toLowerCase() == 'user';
  }

  // ========== PERMISSION HELPERS ==========

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Check if user has mail access permission
  bool get hasMailAccess {
    return hasPermission('korgan.mail.access');
  }

  /// Check if user can send mail
  bool get canSendMail {
    return hasPermission('korgan.mail.send.self');
  }

  /// Check if user can search organization-wide
  bool get canSearchOrganization {
    return hasPermission('korgan.mail.search.org');
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

  /// Get short display name (for dropdowns)
  String get shortDisplayName {
    if (name.length > 30) {
      return '${name.substring(0, 27)}...';
    }
    return name;
  }

  // ========== EQUALITY & SERIALIZATION ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, slug, role);

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, slug: $slug, role: $role)';
  }

  // ========== COPY METHODS ==========

  /// Create a copy with optional field updates
  Organization copyWith({
    String? id,
    String? name,
    String? slug,
    String? role,
    List<String>? permissions,
    Map<String, dynamic>? settings,
    String? createdAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
