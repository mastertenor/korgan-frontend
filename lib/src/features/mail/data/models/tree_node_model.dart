// lib/src/features/mail/data/models/tree_node_model.dart

import '../../domain/entities/tree_node.dart';

/// Data model for tree node API responses
///
/// Handles JSON serialization/deserialization for tree node data
/// from the backend tree API as documented in the implementation report.
///
/// Expected API response format (based on backend report):
/// {
///   "id": "tnd_xyz123",
///   "title": "Gelen Kutusu",
///   "slug": "gelen",
///   "parentId": null,
///   "orderIndex": 0,
///   "payload": {"description": "Inbox folder"},
///   "scope": "sys",
///   "createdAt": "2025-09-21T...",
///   "updatedAt": "2025-09-21T...",
///   "children": [...] // Nested children if any
/// }
class TreeNodeModel {
  final String id;
  final String title;
  final String slug;
  final String? parentId;
  final int orderIndex;
  final Map<String, dynamic>? payload;
  final String scope;
  final String? createdAt;
  final String? updatedAt;

  const TreeNodeModel({
    required this.id,
    required this.title,
    required this.slug,
    this.parentId,
    required this.orderIndex,
    this.payload,
    required this.scope,
    this.createdAt,
    this.updatedAt,
  });

  // ========== JSON SERIALIZATION ==========

  /// Create from JSON response
  factory TreeNodeModel.fromJson(Map<String, dynamic> json) {
    return TreeNodeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      parentId: json['parent_id']?.toString(), // Backend uses snake_case
      orderIndex:
          (json['order_index'] as num?)?.toInt() ??
          0, // Backend uses snake_case
      payload: json['payload'] as Map<String, dynamic>?,
      scope:
          json['effective_scope']?.toString() ??
          'usr', // Backend uses effective_scope
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'title': title,
      'slug': slug,
      'orderIndex': orderIndex,
      'scope': scope,
    };

    if (parentId != null) data['parentId'] = parentId!;
    if (payload != null) data['payload'] = payload!;
    if (createdAt != null) data['createdAt'] = createdAt!;
    if (updatedAt != null) data['updatedAt'] = updatedAt!;

    return data;
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain TreeNode entity
  TreeNode toDomain() {
    return TreeNode(
      id: id,
      title: title,
      slug: slug,
      parentId: parentId,
      orderIndex: orderIndex,
      payload: payload,
      scope: scope,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      // UI state properties default to false/empty
      children: const [],
      isExpanded: false,
      isSelected: false,
      isLoading: false,
      unreadCount: _extractUnreadCount(),
      totalCount: _extractTotalCount(),
      iconName: _extractIconName(),
      color: _extractColor(),
    );
  }

  /// Create model from domain entity
  factory TreeNodeModel.fromDomain(TreeNode entity) {
    return TreeNodeModel(
      id: entity.id,
      title: entity.title,
      slug: entity.slug,
      parentId: entity.parentId,
      orderIndex: entity.orderIndex,
      payload: _buildPayloadFromEntity(entity),
      scope: entity.scope,
      createdAt: entity.createdAt?.toIso8601String(),
      updatedAt: entity.updatedAt?.toIso8601String(),
    );
  }

  // ========== PAYLOAD EXTRACTION HELPERS ==========

  /// Extract unread count from payload
  int _extractUnreadCount() {
    if (payload == null) return 0;
    return (payload!['unreadCount'] as num?)?.toInt() ?? 0;
  }

  /// Extract total count from payload
  int _extractTotalCount() {
    if (payload == null) return 0;
    return (payload!['totalCount'] as num?)?.toInt() ?? 0;
  }

  /// Extract icon name from payload
  String? _extractIconName() {
    if (payload == null) return null;
    return payload!['iconName']?.toString();
  }

  /// Extract color from payload
  String? _extractColor() {
    if (payload == null) return null;
    return payload!['color']?.toString();
  }

  /// Build payload from domain entity
  static Map<String, dynamic>? _buildPayloadFromEntity(TreeNode entity) {
    final payload = <String, dynamic>{};

    if (entity.unreadCount > 0) {
      payload['unreadCount'] = entity.unreadCount;
    }

    if (entity.totalCount > 0) {
      payload['totalCount'] = entity.totalCount;
    }

    if (entity.iconName != null) {
      payload['iconName'] = entity.iconName;
    }

    if (entity.color != null) {
      payload['color'] = entity.color;
    }

    // Merge with existing payload if any
    if (entity.payload != null) {
      payload.addAll(entity.payload!);
    }

    return payload.isEmpty ? null : payload;
  }

  // ========== VALIDATION ==========

  /// Check if model data is valid
  bool get isValid {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        slug.isNotEmpty &&
        orderIndex >= 0 &&
        ['sys', 'org', 'usr', 'ctx'].contains(scope);
  }

  // ========== EQUALITY & DEBUGGING ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeNodeModel &&
        other.id == id &&
        other.title == title &&
        other.slug == slug &&
        other.scope == scope;
  }

  @override
  int get hashCode => Object.hash(id, title, slug, scope);

  @override
  String toString() {
    return 'TreeNodeModel(id: $id, title: $title, slug: $slug, scope: $scope, orderIndex: $orderIndex)';
  }

  // ========== STATIC HELPERS ==========

  /// Parse list of tree nodes from API response
  static List<TreeNodeModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => TreeNodeModel.fromJson(json as Map<String, dynamic>))
        .where((model) => model.isValid)
        .toList();
  }

  /// Convert list of models to domain entities
  static List<TreeNode> toDomainList(List<TreeNodeModel> models) {
    return models.map((model) => model.toDomain()).toList();
  }

  /// Create copy with updated fields
  TreeNodeModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? parentId,
    int? orderIndex,
    Map<String, dynamic>? payload,
    String? scope,
    String? createdAt,
    String? updatedAt,
  }) {
    return TreeNodeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      parentId: parentId ?? this.parentId,
      orderIndex: orderIndex ?? this.orderIndex,
      payload: payload ?? this.payload,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
