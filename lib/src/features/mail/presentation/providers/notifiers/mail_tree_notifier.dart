// lib/src/features/mail/presentation/providers/notifiers/mail_tree_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/app_logger.dart';
import '../../../domain/entities/tree_node.dart';
import '../../../data/datasources/tree_api_service.dart';

/// Mail tree state notifier
///
/// Manages the tree state for mail folders including:
/// - Loading tree data from API
/// - CRUD operations on tree nodes
/// - State management for UI
/// - Error handling and recovery
class MailTreeNotifier extends StateNotifier<AsyncValue<List<TreeNode>>> {
  final String? organizationId;
  final String? contextId;
  final TreeApiService apiService;

  MailTreeNotifier({
    required this.organizationId,
    required this.contextId,
    required this.apiService,
  }) : super(const AsyncValue.loading()) {
    AppLogger.info(
      '🌳 MailTreeNotifier: Initialized with org=$organizationId, ctx=$contextId',
    );
    _loadTree();
  }

  // ========== TREE LOADING ==========

  /// Load tree from API
  Future<void> _loadTree() async {
    if (organizationId == null || contextId == null) {
      AppLogger.warning(
        '🌳 MailTreeNotifier: Missing org or context, setting empty tree',
      );
      state = const AsyncValue.data([]);
      return;
    }

    try {
      AppLogger.info('🌳 MailTreeNotifier: Loading tree...');
      state = const AsyncValue.loading();

      final nodes = await apiService.getMailTree(
        organizationId: organizationId!,
        contextId: contextId!,
      );

      state = AsyncValue.data(nodes);
      AppLogger.info(
        '✅ MailTreeNotifier: Tree loaded successfully with ${nodes.length} root nodes',
      );

      _logTreeStructure(nodes);
    } catch (e, stackTrace) {
      AppLogger.error('❌ MailTreeNotifier: Failed to load tree - $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh tree data
  Future<void> refreshTree() async {
    AppLogger.info('🔄 MailTreeNotifier: Refreshing tree...');
    await _loadTree();
  }

  /// Load subtree from specific root
  Future<void> loadSubtree(String rootSlug) async {
    if (organizationId == null || contextId == null) {
      AppLogger.warning(
        '🌳 MailTreeNotifier: Missing org or context for subtree',
      );
      return;
    }

    try {
      AppLogger.info(
        '🌳 MailTreeNotifier: Loading subtree from root: $rootSlug',
      );
      state = const AsyncValue.loading();

      final nodes = await apiService.getMailTree(
        organizationId: organizationId!,
        contextId: contextId!,
        rootSlug: rootSlug,
      );

      state = AsyncValue.data(nodes);
      AppLogger.info(
        '✅ MailTreeNotifier: Subtree loaded with ${nodes.length} nodes',
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ MailTreeNotifier: Failed to load subtree - $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // ========== CRUD OPERATIONS ==========

  /// Create new tree node
  Future<void> createNode({
    required String title,
    String? parentSlug,
    Map<String, dynamic>? payload,
  }) async {
    if (organizationId == null || contextId == null) {
      throw Exception('Organization or context not available');
    }

    try {
      AppLogger.info('🆕 MailTreeNotifier: Creating node "$title"');

      // Generate slug from title
      final slug = apiService.generateSlug(title);

      // Create node via API
      final newNode = await apiService.createNode(
        title: title,
        slug: slug,
        organizationId: organizationId!,
        contextId: contextId!,
        parentSlug: parentSlug,
        payload: payload,
      );

      AppLogger.info('✅ MailTreeNotifier: Node created: ${newNode.id}');

      // Refresh tree to show new node
      await refreshTree();
    } catch (e) {
      AppLogger.error(
        '❌ MailTreeNotifier: Failed to create node "$title" - $e',
      );
      rethrow;
    }
  }

  /// Update existing tree node
  Future<void> updateNode(
    String nodeId, {
    String? title,
    Map<String, dynamic>? payload,
  }) async {
    if (organizationId == null || contextId == null) {
      throw Exception('Organization or context not available');
    }

    try {
      AppLogger.info('🔄 MailTreeNotifier: Updating node $nodeId');

      // Update node via API
      final updatedNode = await apiService.updateNode(
        nodeId: nodeId,
        organizationId: organizationId!,
        contextId: contextId!,
        title: title,
        payload: payload,
      );

      AppLogger.info('✅ MailTreeNotifier: Node updated: ${updatedNode.id}');

      // Update local state with new node
      _updateNodeInState(updatedNode);
    } catch (e) {
      AppLogger.error('❌ MailTreeNotifier: Failed to update node $nodeId - $e');
      rethrow;
    }
  }

  /// Delete tree node
  Future<void> deleteNode(String nodeId) async {
    if (organizationId == null || contextId == null) {
      throw Exception('Organization or context not available');
    }

    try {
      AppLogger.info('🗑️ MailTreeNotifier: Deleting node $nodeId');

      // Optimistic update - remove from local state first
      _removeNodeFromState(nodeId);

      // Delete node via API
      await apiService.deleteNode(
        nodeId: nodeId,
        organizationId: organizationId!,
        contextId: contextId!,
      );

      AppLogger.info('✅ MailTreeNotifier: Node deleted: $nodeId');
    } catch (e) {
      AppLogger.error('❌ MailTreeNotifier: Failed to delete node $nodeId - $e');

      // Revert optimistic update by refreshing
      await refreshTree();
      rethrow;
    }
  }

  /// Move tree node
  Future<void> moveNode(
    String nodeId, {
    String? newParentId,
    int? newOrderIndex,
  }) async {
    if (organizationId == null || contextId == null) {
      throw Exception('Organization or context not available');
    }

    try {
      AppLogger.info(
        '🔄 MailTreeNotifier: Moving node $nodeId to parent=$newParentId, index=$newOrderIndex',
      );

      // Move node via API
      final movedNode = await apiService.moveNode(
        nodeId: nodeId,
        organizationId: organizationId!,
        contextId: contextId!,
        newParentId: newParentId,
        newOrderIndex: newOrderIndex,
      );

      AppLogger.info('✅ MailTreeNotifier: Node moved: ${movedNode.id}');

      // Refresh tree to show new structure
      await refreshTree();
    } catch (e) {
      AppLogger.error('❌ MailTreeNotifier: Failed to move node $nodeId - $e');
      rethrow;
    }
  }

  // ========== LOCAL STATE MANAGEMENT ==========

  /// Update node in current state
  void _updateNodeInState(TreeNode updatedNode) {
    state.whenData((currentNodes) {
      final updatedNodes = _updateNodeInTree(currentNodes, updatedNode);
      state = AsyncValue.data(updatedNodes);
    });
  }

  /// Remove node from current state
  void _removeNodeFromState(String nodeId) {
    state.whenData((currentNodes) {
      final updatedNodes = _removeNodeFromTree(currentNodes, nodeId);
      state = AsyncValue.data(updatedNodes);
    });
  }

  /// Update node in tree structure recursively
  List<TreeNode> _updateNodeInTree(List<TreeNode> nodes, TreeNode updatedNode) {
    return nodes.map((node) {
      if (node.id == updatedNode.id) {
        return updatedNode;
      } else if (node.hasChildren) {
        return node.copyWith(
          children: _updateNodeInTree(node.children, updatedNode),
        );
      }
      return node;
    }).toList();
  }

  /// Remove node from tree structure recursively
  List<TreeNode> _removeNodeFromTree(List<TreeNode> nodes, String nodeId) {
    return nodes.where((node) => node.id != nodeId).map((node) {
      if (node.hasChildren) {
        return node.copyWith(
          children: _removeNodeFromTree(node.children, nodeId),
        );
      }
      return node;
    }).toList();
  }

  // ========== STATE HELPERS ==========

  /// Check if tree is currently loading
  bool get isLoading => state.isLoading;

  /// Check if tree has error
  bool get hasError => state.hasError;

  /// Get current tree data (null if loading or error)
  List<TreeNode>? get currentTree => state.valueOrNull;

  /// Get current error (null if no error)
  Object? get currentError => state.error;

  /// Check if tree is empty
  bool get isEmpty => currentTree?.isEmpty ?? true;

  /// Get total node count
  int get nodeCount {
    final nodes = currentTree;
    if (nodes == null) return 0;
    return _countNodesRecursively(nodes);
  }

  /// Count nodes recursively
  int _countNodesRecursively(List<TreeNode> nodes) {
    int count = nodes.length;
    for (final node in nodes) {
      count += _countNodesRecursively(node.children);
    }
    return count;
  }

  // ========== DEBUGGING ==========

  /// Log tree structure for debugging
  void _logTreeStructure(List<TreeNode> nodes) {
    if (nodes.isEmpty) {
      AppLogger.debug('🌳 Tree structure: Empty');
      return;
    }

    AppLogger.debug('🌳 Tree structure:');
    for (final node in nodes) {
      _logNodeStructure(node, 0);
    }
  }

  /// Log single node structure
  void _logNodeStructure(TreeNode node, int level) {
    final indent = '  ' * level;
    AppLogger.debug('$indent- ${node.title} (${node.slug}) [${node.scope}]');

    for (final child in node.children) {
      _logNodeStructure(child, level + 1);
    }
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'organizationId': organizationId,
      'contextId': contextId,
      'isLoading': isLoading,
      'hasError': hasError,
      'nodeCount': nodeCount,
      'isEmpty': isEmpty,
      'error': currentError?.toString(),
    };
  }

  /// Print debug information
  void printDebugInfo() {
    final info = getDebugInfo();
    AppLogger.debug('🌳 MailTreeNotifier Debug Info: $info');
  }
}
