// lib/src/features/organization/data/models/organization_model.dart

import '../../domain/entities/organization.dart';
import '../../../mail/data/models/mail_context_model.dart';

/// Data model for organization API responses
///
/// Handles JSON serialization/deserialization for organization data
/// from the backend API: GET /api/auth/user/organizations/
///
/// Expected API response format (UPDATED):
/// {
///   "success": true,
///   "data": {
///     "organizations": [
///       {
///         "id": "org_v4wmuO3ftqbzo19G",
///         "name": "Argen Bulut ve Yazılım Teknolojileri A.Ş.",
///         "slug": "argen-teknoloji",
///         "role": "user",
///         "modulePermissions": [...],  // UPDATED: permissions → modulePermissions
///         "contexts": [...],           // NEW: contexts array
///         "settings": {},
///         "createdAt": "2025-09-12T09:03:21.513Z"
///       }
///     ]
///   }
/// }
class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String role;
  final List<String>
  modulePermissions; // UPDATED: permissions → modulePermissions
  final List<MailContextModel> contexts; // NEW: contexts array
  final Map<String, dynamic> settings;
  final String createdAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    required this.modulePermissions,
    required this.contexts,
    required this.settings,
    required this.createdAt,
  });

  // ========== JSON SERIALIZATION ==========

  /// Create from JSON response
  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      modulePermissions:
          (json['modulePermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [], // UPDATED: modulePermissions parsing
      contexts:
          (json['contexts'] as List<dynamic>?)
              ?.map((e) => MailContextModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [], // NEW: contexts parsing
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  /// Convert to JSON (for testing purposes)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'role': role,
      'modulePermissions': modulePermissions,
      'contexts': contexts.map((e) => e.toJson()).toList(),
      'settings': settings,
      'createdAt': createdAt,
    };
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain Organization entity
  Organization toDomain() {
    return Organization(
      id: id,
      name: name,
      slug: slug,
      role: role,
      modulePermissions: modulePermissions,
      contexts: contexts.map((e) => e.toDomain()).toList(),
      settings: settings,
      createdAt: createdAt,
    );
  }

  /// Create model from domain entity
  factory OrganizationModel.fromDomain(Organization entity) {
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      role: entity.role,
      modulePermissions: entity.modulePermissions,
      contexts: entity.contexts
          .map((e) => MailContextModel.fromDomain(e))
          .toList(),
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
    return 'OrganizationModel(id: $id, name: $name, slug: $slug, role: $role, contexts: ${contexts.length})';
  }

  // ========== STATIC HELPERS ==========

  /// Parse list of organizations from API response
  static List<OrganizationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>))
        .where((model) => model.isValid)
        .toList();
  }

  /// Convert list of models to domain entities
  static List<Organization> toDomainList(List<OrganizationModel> models) {
    return models.map((model) => model.toDomain()).toList();
  }
}
