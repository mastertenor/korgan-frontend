// lib/src/features/mail/domain/entities/tree_node.dart

/// Tree node entity for mail folder hierarchy
///
/// Represents a single node in the mail folder tree structure.
/// Supports hierarchical organization with parent-child relationships
/// and provides CRUD capabilities based on node scope.
class TreeNode {
  final String id;
  final String title;
  final String slug;
  final String? parentId;
  final int orderIndex;
  final Map<String, dynamic>? payload;
  final String scope; // 'sys', 'org', 'usr', 'ctx'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // UI state properties
  final List<TreeNode> children;
  final bool isExpanded;
  final bool isSelected;
  final bool isLoading;

  // Mail-specific properties
  final int unreadCount;
  final int totalCount;
  final String? iconName;
  final String? color;

  const TreeNode({
    required this.id,
    required this.title,
    required this.slug,
    this.parentId,
    required this.orderIndex,
    this.payload,
    required this.scope,
    this.createdAt,
    this.updatedAt,
    this.children = const [],
    this.isExpanded = false,
    this.isSelected = false,
    this.isLoading = false,
    this.unreadCount = 0,
    this.totalCount = 0,
    this.iconName,
    this.color,
  });

  // ========== CRUD CAPABILITIES ==========

  /// Can create child nodes
  bool get canCreate {
    switch (scope) {
      case 'sys':
        return false; // System nodes are read-only
      case 'org':
      case 'usr':
      case 'ctx':
        return true; // User can create in their own scope
      default:
        return false;
    }
  }

  /// Can update this node
  bool get canUpdate {
    switch (scope) {
      case 'sys':
        return false; // System nodes are read-only
      case 'org':
      case 'usr':
      case 'ctx':
        return true; // User can update their own nodes
      default:
        return false;
    }
  }

  /// Can delete this node
  bool get canDelete {
    switch (scope) {
      case 'sys':
        return false; // System nodes cannot be deleted
      case 'org':
      case 'usr':
      case 'ctx':
        return true; // User can delete their own nodes
      default:
        return false;
    }
  }

  /// Can move this node
  bool get canMove {
    switch (scope) {
      case 'sys':
        return false; // System nodes cannot be moved
      case 'org':
      case 'usr':
      case 'ctx':
        return true; // User can move their own nodes
      default:
        return false;
    }
  }

  // ========== TREE OPERATIONS ==========

  /// Check if this node has children
  bool get hasChildren => children.isNotEmpty;

  /// Check if this node is a root node
  bool get isRoot => parentId == null;

  /// Check if this node is a leaf node
  bool get isLeaf => children.isEmpty;

  /// Get the depth level in tree (root = 0)
  int get level {
    if (isRoot) return 0;
    // This would need parent reference to calculate accurately
    // For now, return 0 as placeholder
    return 0;
  }

  /// Check if this node is a system folder
  bool get isSystemFolder => scope == 'sys';

  /// Check if this node is a custom folder
  bool get isCustomFolder => scope == 'ctx' || scope == 'usr';

  /// Get display icon based on node type and state
  String get displayIcon {
    if (iconName != null) return iconName!;

    // Default icons based on scope and state
    if (isSystemFolder) {
      switch (slug.toLowerCase()) {
        case 'inbox':
        case 'gelen':
          return 'inbox';
        case 'sent':
        case 'giden':
          return 'send';
        case 'drafts':
        case 'taslaklar':
          return 'drafts';
        case 'starred':
        case 'yildizli':
          return 'star';
        case 'important':
        case 'onemli':
          return 'label_important';
        case 'spam':
          return 'report';
        case 'trash':
        case 'cop':
          return 'delete';
        default:
          return 'folder';
      }
    }

    // Custom folders
    return hasChildren ? 'folder' : 'folder_open';
  }

  /// Get display color for the node
  String? get displayColor {
    if (color != null) return color;

    // Default colors for system folders
    if (isSystemFolder) {
      switch (slug.toLowerCase()) {
        case 'inbox':
        case 'gelen':
          return '#1976D2'; // Blue
        case 'sent':
        case 'giden':
          return '#388E3C'; // Green
        case 'drafts':
        case 'taslaklar':
          return '#F57C00'; // Orange
        case 'starred':
        case 'yildizli':
          return '#FFD600'; // Yellow
        case 'spam':
          return '#D32F2F'; // Red
        case 'trash':
        case 'cop':
          return '#616161'; // Grey
        default:
          return null;
      }
    }

    return null; // Use default theme color
  }

  // ========== HIERARCHY MANAGEMENT ==========

  /// Add child node and maintain proper hierarchy
  TreeNode addChild(TreeNode child) {
    // Check if child already exists
    final existingIndex = children.indexWhere((c) => c.id == child.id);

    List<TreeNode> updatedChildren;
    if (existingIndex >= 0) {
      // Update existing child in place
      updatedChildren = List.from(children);
      updatedChildren[existingIndex] = child;
    } else {
      // Add new child
      updatedChildren = List.from(children)..add(child);
    }

    // Sort children by order index to maintain hierarchy
    updatedChildren.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return copyWith(children: updatedChildren);
  }

  /// Remove child node
  TreeNode removeChild(String childId) {
    final updatedChildren = children
        .where((child) => child.id != childId)
        .toList();
    return copyWith(children: updatedChildren);
  }

  /// Update child node
  TreeNode updateChild(TreeNode updatedChild) {
    final updatedChildren = children.map((child) {
      return child.id == updatedChild.id ? updatedChild : child;
    }).toList();
    return copyWith(children: updatedChildren);
  }

  /// Replace children with new list
  TreeNode replaceChildren(List<TreeNode> newChildren) {
    final sortedChildren = List<TreeNode>.from(newChildren);
    sortedChildren.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return copyWith(children: sortedChildren);
  }

  // ========== SEARCH & TRAVERSAL ==========

  /// Find node by ID in this subtree
  TreeNode? findById(String nodeId) {
    if (id == nodeId) return this;

    for (final child in children) {
      final found = child.findById(nodeId);
      if (found != null) return found;
    }

    return null;
  }

  /// Find node by slug in this subtree
  TreeNode? findBySlug(String targetSlug) {
    if (slug == targetSlug) return this;

    for (final child in children) {
      final found = child.findBySlug(targetSlug);
      if (found != null) return found;
    }

    return null;
  }

  /// Get all descendant nodes
  List<TreeNode> getAllDescendants() {
    final descendants = <TreeNode>[];

    for (final child in children) {
      descendants.add(child);
      descendants.addAll(child.getAllDescendants());
    }

    return descendants;
  }

  /// Get path from root to this node (slugs only)
  List<String> getPathSlugs() {
    // This would need parent reference to build actual path
    // For now, return current slug
    return [slug];
  }

  /// Count total nodes in subtree (including this node)
  int get totalNodeCount {
    int count = 1; // This node
    for (final child in children) {
      count += child.totalNodeCount;
    }
    return count;
  }

  // ========== STATE MANAGEMENT ==========

  /// Create a copy with updated properties
  TreeNode copyWith({
    String? id,
    String? title,
    String? slug,
    String? parentId,
    int? orderIndex,
    Map<String, dynamic>? payload,
    String? scope,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TreeNode>? children,
    bool? isExpanded,
    bool? isSelected,
    bool? isLoading,
    int? unreadCount,
    int? totalCount,
    String? iconName,
    String? color,
  }) {
    return TreeNode(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      parentId: parentId ?? this.parentId,
      orderIndex: orderIndex ?? this.orderIndex,
      payload: payload ?? this.payload,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
      totalCount: totalCount ?? this.totalCount,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
    );
  }

  /// Toggle expansion state
  TreeNode toggleExpanded() {
    return copyWith(isExpanded: !isExpanded);
  }

  /// Set selection state
  TreeNode setSelected(bool selected) {
    return copyWith(isSelected: selected);
  }

  /// Set loading state
  TreeNode setLoading(bool loading) {
    return copyWith(isLoading: loading);
  }

  /// Update unread count
  TreeNode updateUnreadCount(int count) {
    return copyWith(unreadCount: count);
  }

  /// Update both unread and total counts
  TreeNode updateCounts({int? unread, int? total}) {
    return copyWith(
      unreadCount: unread ?? unreadCount,
      totalCount: total ?? totalCount,
    );
  }

  // ========== VALIDATION ==========

  /// Validate node data
  bool get isValid {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        slug.isNotEmpty &&
        orderIndex >= 0 &&
        ['sys', 'org', 'usr', 'ctx'].contains(scope);
  }

  /// Validate hierarchy (check for circular references)
  bool isValidHierarchy({Set<String>? visited}) {
    visited ??= <String>{};

    if (visited.contains(id)) {
      return false; // Circular reference detected
    }

    visited.add(id);

    for (final child in children) {
      if (!child.isValidHierarchy(visited: Set.from(visited))) {
        return false;
      }
    }

    return true;
  }

  // ========== EQUALITY & DEBUGGING ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeNode &&
        other.id == id &&
        other.title == title &&
        other.slug == slug &&
        other.scope == scope;
  }

  @override
  int get hashCode => Object.hash(id, title, slug, scope);

  @override
  String toString() {
    return 'TreeNode(id: $id, title: $title, slug: $slug, scope: $scope, children: ${children.length})';
  }

  /// Debug representation with tree structure
  String toDebugString({int indent = 0}) {
    final padding = '  ' * indent;
    final buffer = StringBuffer();

    buffer.writeln('${padding}TreeNode(');
    buffer.writeln('${padding}  id: $id,');
    buffer.writeln('${padding}  title: $title,');
    buffer.writeln('${padding}  slug: $slug,');
    buffer.writeln('${padding}  scope: $scope,');
    buffer.writeln('${padding}  parentId: $parentId,');
    buffer.writeln('${padding}  orderIndex: $orderIndex,');
    buffer.writeln('${padding}  unreadCount: $unreadCount,');
    buffer.writeln('${padding}  isExpanded: $isExpanded,');

    if (children.isNotEmpty) {
      buffer.writeln('${padding}  children: [');
      for (final child in children) {
        buffer.write(child.toDebugString(indent: indent + 2));
      }
      buffer.writeln('${padding}  ],');
    }

    buffer.writeln('${padding})');
    return buffer.toString();
  }

  /// Get a visual tree representation
  String toTreeString({String prefix = '', bool isLast = true}) {
    final buffer = StringBuffer();
    final connector = isLast ? '└── ' : '├── ';
    final childPrefix = isLast ? '    ' : '│   ';

    buffer.writeln('$prefix$connector$title ($scope)');

    for (int i = 0; i < children.length; i++) {
      final isLastChild = i == children.length - 1;
      buffer.write(
        children[i].toTreeString(
          prefix: prefix + childPrefix,
          isLast: isLastChild,
        ),
      );
    }

    return buffer.toString();
  }
}

extension TreeNodeGmailExtension on TreeNode {
  /// Get Gmail labels from payload
  List<String> get gmailLabels {
    if (payload == null || payload!['labels'] == null) return [];

    final labelsList = payload!['labels'] as List<dynamic>;
    return labelsList
        .map(
          (label) => (label as Map<String, dynamic>)['gmailLabelId'] as String?,
        )
        .where((labelId) => labelId != null)
        .cast<String>()
        .toList();
  }

  /// Get primary Gmail label (first one)
  String? get primaryGmailLabel {
    final labels = gmailLabels;
    return labels.isNotEmpty ? labels.first : null;
  }

  /// Check if node has Gmail labels
  bool get hasGmailLabels => gmailLabels.isNotEmpty;

  /// Get Gmail label names for display
  List<String> get gmailLabelNames {
    if (payload == null || payload!['labels'] == null) return [];

    final labelsList = payload!['labels'] as List<dynamic>;
    return labelsList
        .map(
          (label) =>
              (label as Map<String, dynamic>)['gmailLabelName'] as String?,
        )
        .where((labelName) => labelName != null)
        .cast<String>()
        .toList();
  }
}

// ========== ENUMS & HELPERS ==========

/// Tree node scope types
enum TreeNodeScope {
  system('sys'),
  organization('org'),
  user('usr'),
  context('ctx');

  const TreeNodeScope(this.value);
  final String value;

  static TreeNodeScope fromString(String value) {
    return TreeNodeScope.values.firstWhere(
      (scope) => scope.value == value,
      orElse: () => TreeNodeScope.user,
    );
  }
}

/// Tree action types for context menu
enum TreeAction {
  createFolder,
  createSubfolder,
  rename,
  edit,
  delete,
  cut,
  copy,
  paste,
  refresh,
  properties,
}

/// Tree operation result
class TreeOperationResult {
  final bool success;
  final String? message;
  final TreeNode? updatedNode;
  final Object? error;

  const TreeOperationResult({
    required this.success,
    this.message,
    this.updatedNode,
    this.error,
  });

  factory TreeOperationResult.success({
    String? message,
    TreeNode? updatedNode,
  }) {
    return TreeOperationResult(
      success: true,
      message: message,
      updatedNode: updatedNode,
    );
  }

  factory TreeOperationResult.failure({
    required String message,
    Object? error,
  }) {
    return TreeOperationResult(success: false, message: message, error: error);
  }
}
