// lib/src/features/mail/data/models/organization_model.dart

import '../../domain/entities/organization.dart';

/// Data model for organization API responses
///
/// Handles JSON serialization/deserialization for organization data
/// from the backend API: GET /api/auth/user/organizations/
///
/// Expected API response format:
/// {
///   "success": true,
///   "data": [
///     {"id": "org1", "name": "Acme Corp", "role": "admin"},
///     {"id": "org2", "name": "Tech Inc", "role": "user"}
///   ]
/// }
class OrganizationModel {
  final String id;
  final String name;
  final String role;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.role,
  });

  // ========== JSON SERIALIZATION ==========

  /// Create from JSON response
  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  /// Convert to JSON (for testing purposes)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role};
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain Organization entity
  Organization toEntity() {
    return Organization(id: id, name: name, role: role);
  }

  /// Create model from domain entity
  factory OrganizationModel.fromEntity(Organization entity) {
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      role: entity.role,
    );
  }

  // ========== VALIDATION ==========

  /// Check if model data is valid
  bool get isValid {
    return id.isNotEmpty && name.isNotEmpty && role.isNotEmpty;
  }

  // ========== EQUALITY & DEBUGGING ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizationModel &&
        other.id == id &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, name, role);

  @override
  String toString() {
    return 'OrganizationModel(id: $id, name: $name, role: $role)';
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
