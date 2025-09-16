// lib/src/features/organization/data/models/organization_model.dart

import '../../domain/entities/organization.dart';

/// Data model for organization API responses
///
/// Handles JSON serialization/deserialization for organization data
/// from the backend API: GET /api/auth/user/organizations/
///
/// Expected API response format:
/// {
///   "success": true,
///   "data": {
///     "organizations": [
///       {
///         "id": "org_v4wmuO3ftqbzo19G",
///         "name": "Argen Bulut ve Yazılım Teknolojileri A.Ş.",
///         "slug": "argen-teknoloji",
///         "role": "user",
///         "permissions": [...],
///         "settings": {},
///         "createdAt": "2025-09-12T09:03:21.513Z"
///       }
///     ]
///   }
/// }
class OrganizationModel {
  final String id;
  final String name;
  final String slug; // ✅ YENİ: URL-safe slug
  final String role;
  final List<String> permissions; // ✅ YENİ: Yetkileri
  final Map<String, dynamic> settings; // ✅ YENİ: Ayarları
  final String createdAt; // ✅ YENİ: Oluşturulma tarihi

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.permissions,
    required this.settings,
    required this.createdAt,
  });

  // ========== JSON SERIALIZATION ==========

  /// Create from JSON response
  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '', // ✅ YENİ: Slug parsing
      role: json['role']?.toString() ?? '',
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [], // ✅ YENİ: Permissions parsing
      settings:
          (json['settings'] as Map<String, dynamic>?) ??
          {}, // ✅ YENİ: Settings parsing
      createdAt:
          json['createdAt']?.toString() ?? '', // ✅ YENİ: CreatedAt parsing
    );
  }

  /// Convert to JSON (for testing purposes)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'role': role,
      'permissions': permissions,
      'settings': settings,
      'createdAt': createdAt,
    };
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain Organization entity
  Organization toEntity() {
    return Organization(
      id: id,
      name: name,
      slug: slug,
      role: role,
      permissions: permissions,
      settings: settings,
      createdAt: createdAt,
    );
  }

  /// Create model from domain entity
  factory OrganizationModel.fromEntity(Organization entity) {
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      role: entity.role,
      permissions: entity.permissions,
      settings: entity.settings,
      createdAt: entity.createdAt,
    );
  }

  // ========== VALIDATION ==========

  /// Check if model data is valid
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        slug.isNotEmpty &&
        role.isNotEmpty;
  }

  // ========== EQUALITY & DEBUGGING ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizationModel &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, slug, role);

  @override
  String toString() {
    return 'OrganizationModel(id: $id, name: $name, slug: $slug, role: $role)';
  }

  // ========== STATIC HELPERS ==========

  /// Parse list of organizations from API response
  static List<OrganizationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>))
        .where((model) => model.isValid) // Filter out invalid models
        .toList();
  }

  /// Convert list of models to domain entities
  static List<Organization> toEntityList(List<OrganizationModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
