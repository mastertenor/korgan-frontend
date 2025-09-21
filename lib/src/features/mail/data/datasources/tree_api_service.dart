// lib/src/features/mail/data/datasources/tree_api_service.dart
import '../../../../core/network/api_client.dart';
import '../../../../utils/app_logger.dart';
import '../models/tree_node_model.dart';
import '../../domain/entities/tree_node.dart';

/// Tree API service for mail folder tree operations
///
/// Handles all CRUD operations for the tree system using the backend API
/// as documented in the implementation report.
///
/// API Endpoints:
/// - GET /api/tree/mails - Get tree structure
/// - POST /api/tree/mails/nodes - Create node
/// - PUT /api/tree/mails/nodes/{id} - Update node
/// - DELETE /api/tree/mails/nodes/{id} - Delete node
/// - PUT /api/tree/mails/nodes/{id}/move - Move node
class TreeApiService {
  final ApiClient _apiClient;

  TreeApiService(this._apiClient);

  // ========== READ OPERATIONS ==========

  /// Get mail tree structure for given organization and context
  ///
  /// GET /api/tree/mails?organizationId={orgId}&contextId={ctxId}&rootSlug={slug}
  Future<List<TreeNode>> getMailTree({
    required String organizationId,
    required String contextId,
    String? rootSlug,
  }) async {
    try {
      AppLogger.info(
        'TreeAPI: Fetching tree for org=$organizationId, ctx=$contextId, root=$rootSlug',
      );

      final queryParams = <String, dynamic>{
        'organizationId': organizationId,
        'contextId': contextId,
      };

      if (rootSlug != null && rootSlug.isNotEmpty) {
        queryParams['rootSlug'] = rootSlug;
      }

      final response = await _apiClient.get(
        '/api/tree/mails',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // DEBUG: Log the full response to see what we're getting
        AppLogger.debug('TreeAPI Raw Response: ${responseData.toString()}');

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> nodesData = responseData['data'] as List<dynamic>;

          // DEBUG: Log each node from backend
          AppLogger.debug(
            'TreeAPI: Received ${nodesData.length} nodes from backend:',
          );
          for (int i = 0; i < nodesData.length; i++) {
            final nodeJson = nodesData[i] as Map<String, dynamic>;
            AppLogger.debug(
              '  [$i] ${nodeJson['title']} (parent: ${nodeJson['parent_id']})',
            );
          }

          final nodes = nodesData
              .map(
                (nodeJson) =>
                    TreeNodeModel.fromJson(nodeJson as Map<String, dynamic>),
              )
              .map((model) => model.toDomain())
              .toList();

          AppLogger.info('TreeAPI: Successfully loaded ${nodes.length} nodes');

          // Log meta information if available
          if (responseData['meta'] != null) {
            final meta = responseData['meta'] as Map<String, dynamic>;
            AppLogger.debug('TreeAPI Meta: $meta');
          }

          return _buildHierarchy(nodes);
        } else {
          throw Exception(
            'Invalid response format: ${responseData['success']}',
          );
        }
      } else {
        throw Exception('Failed to fetch tree: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('TreeAPI: Failed to fetch tree - $e');
      rethrow;
    }
  }

  // ========== CREATE OPERATIONS ==========

  /// Create a new tree node
  ///
  /// POST /api/tree/mails/nodes
  Future<TreeNode> createNode({
    required String title,
    required String slug,
    required String organizationId,
    required String contextId,
    String? parentSlug,
    Map<String, dynamic>? payload,
  }) async {
    try {
      AppLogger.info('TreeAPI: Creating node "$title" with slug "$slug"');

      final requestData = <String, dynamic>{
        'title': title,
        'slug': slug,
        'organizationId': organizationId,
        'contextId': contextId,
      };

      if (parentSlug != null && parentSlug.isNotEmpty) {
        requestData['parentSlug'] = parentSlug;
      }

      if (payload != null && payload.isNotEmpty) {
        requestData['payload'] = payload;
      }

      final response = await _apiClient.post(
        '/api/tree/mails/nodes',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          final responseData = response.data as Map<String, dynamic>;

          if (responseData['success'] == true && responseData['data'] != null) {
            final nodeData = responseData['data'] as Map<String, dynamic>;
            final model = TreeNodeModel.fromJson(nodeData);

            AppLogger.info('TreeAPI: Node created successfully - ${model.id}');
            return model.toDomain();
          } else {
            throw Exception(
              'Invalid create response: ${responseData['success']}',
            );
          }
        } else {
          throw Exception('Create response is null');
        }
      } else {
        throw Exception('Failed to create node: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('TreeAPI: Failed to create node "$title" - $e');
      rethrow;
    }
  }

  // ========== UPDATE OPERATIONS ==========

  /// Update an existing tree node
  ///
  /// PUT /api/tree/mails/nodes/{id}
  Future<TreeNode> updateNode({
    required String nodeId,
    required String organizationId,
    required String contextId,
    String? title,
    Map<String, dynamic>? payload,
  }) async {
    try {
      AppLogger.info('TreeAPI: Updating node $nodeId');

      final requestData = <String, dynamic>{
        'organizationId': organizationId,
        'contextId': contextId,
      };

      if (title != null && title.isNotEmpty) {
        requestData['title'] = title;
      }

      if (payload != null) {
        requestData['payload'] = payload;
      }

      final response = await _apiClient.put(
        '/api/tree/mails/nodes/$nodeId',
        data: requestData,
      );

      if (response.statusCode == 200) {
        if (response.data != null) {
          final responseData = response.data as Map<String, dynamic>;

          if (responseData['success'] == true && responseData['data'] != null) {
            final nodeData = responseData['data'] as Map<String, dynamic>;
            final model = TreeNodeModel.fromJson(nodeData);

            AppLogger.info('TreeAPI: Node updated successfully - ${model.id}');
            return model.toDomain();
          } else {
            throw Exception(
              'Invalid update response: ${responseData['success']}',
            );
          }
        } else {
          throw Exception('Update response is null');
        }
      } else {
        throw Exception('Failed to update node: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('TreeAPI: Failed to update node $nodeId - $e');
      rethrow;
    }
  }

  // ========== DELETE OPERATIONS ==========

  /// Delete a tree node
  ///
  /// DELETE /api/tree/mails/nodes/{id}
  Future<void> deleteNode({
    required String nodeId,
    required String organizationId,
    required String contextId,
  }) async {
    try {
      AppLogger.info('TreeAPI: Deleting node $nodeId');

      final requestData = <String, dynamic>{
        'organizationId': organizationId,
        'contextId': contextId,
      };

      final response = await _apiClient.delete(
        '/api/tree/mails/nodes/$nodeId',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>?;

        if (responseData?['success'] == true) {
          AppLogger.info('TreeAPI: Node deleted successfully - $nodeId');
        } else {
          throw Exception(
            'Invalid delete response: ${responseData?['success']}',
          );
        }
      } else {
        throw Exception('Failed to delete node: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('TreeAPI: Failed to delete node $nodeId - $e');
      rethrow;
    }
  }

  // ========== MOVE OPERATIONS ==========

  /// Move a tree node to new parent and position
  ///
  /// PUT /api/tree/mails/nodes/{id}/move
  Future<TreeNode> moveNode({
    required String nodeId,
    required String organizationId,
    required String contextId,
    String? newParentId,
    int? newOrderIndex,
  }) async {
    try {
      AppLogger.info(
        'TreeAPI: Moving node $nodeId to parent=$newParentId, index=$newOrderIndex',
      );

      final requestData = <String, dynamic>{
        'organizationId': organizationId,
        'contextId': contextId,
      };

      if (newParentId != null) {
        requestData['newParentId'] = newParentId;
      }

      if (newOrderIndex != null) {
        requestData['newOrderIndex'] = newOrderIndex;
      }

      final response = await _apiClient.put(
        '/api/tree/mails/nodes/$nodeId/move',
        data: requestData,
      );

      if (response.statusCode == 200) {
        if (response.data != null) {
          final responseData = response.data as Map<String, dynamic>;

          if (responseData['success'] == true && responseData['data'] != null) {
            final nodeData = responseData['data'] as Map<String, dynamic>;
            final model = TreeNodeModel.fromJson(nodeData);

            AppLogger.info('TreeAPI: Node moved successfully - ${model.id}');
            return model.toDomain();
          } else {
            throw Exception(
              'Invalid move response: ${responseData['success']}',
            );
          }
        } else {
          throw Exception('Move response is null');
        }
      } else {
        throw Exception('Failed to move node: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('TreeAPI: Failed to move node $nodeId - $e');
      rethrow;
    }
  }

  // ========== HIERARCHY BUILDING ==========

  /// Build hierarchical tree structure from flat list
  List<TreeNode> _buildHierarchy(List<TreeNode> flatNodes) {
    if (flatNodes.isEmpty) return [];

    AppLogger.debug(
      'TreeAPI: Building hierarchy from ${flatNodes.length} flat nodes',
    );

    // DEBUG: Log all nodes with their parent relationships
    for (final node in flatNodes) {
      AppLogger.debug(
        'Node: ${node.title} (${node.id}) -> Parent: ${node.parentId}',
      );
    }

    // Step 1: Create a map for quick lookup and prepare working copies
    final Map<String, TreeNode> workingNodes = {};
    final Set<String> processedNodes = {};

    // Initialize working map with clean nodes (no children initially)
    for (final node in flatNodes) {
      workingNodes[node.id] = node.copyWith(children: []);
    }

    // Step 2: Build parent-child relationships
    for (final node in flatNodes) {
      final nodeId = node.id;
      final parentId = node.parentId;

      if (parentId == null || parentId.isEmpty) {
        // Root node - will be collected later
        AppLogger.debug('Root node: ${node.title}');
        continue;
      }

      if (processedNodes.contains(nodeId)) {
        // Already processed this node
        continue;
      }

      final parentNode = workingNodes[parentId];
      final currentNode = workingNodes[nodeId];

      if (parentNode != null && currentNode != null) {
        // Add current node as child to parent
        final updatedParent = parentNode.addChild(currentNode);
        workingNodes[parentId] = updatedParent;
        processedNodes.add(nodeId);

        AppLogger.debug(
          'Added ${currentNode.title} as child of ${parentNode.title}',
        );
      } else {
        if (parentNode == null) {
          AppLogger.warning(
            'Parent $parentId not found for node $nodeId (${node.title})',
          );
        }
      }
    }

    // Step 3: Collect root nodes
    final List<TreeNode> rootNodes = [];
    for (final node in flatNodes) {
      if (node.parentId == null || node.parentId!.isEmpty) {
        final finalNode = workingNodes[node.id] ?? node;
        rootNodes.add(finalNode);
      }
    }

    // Step 4: Sort root nodes by order index
    rootNodes.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    AppLogger.info(
      'TreeAPI: Built hierarchy with ${rootNodes.length} root nodes',
    );

    // Debug log the tree structure
    for (final root in rootNodes) {
      _logTreeStructure(root, 0);
    }

    return rootNodes;
  }

  /// Debug log tree structure
  void _logTreeStructure(TreeNode node, int level) {
    final indent = '  ' * level;
    AppLogger.debug(
      '${indent}├── ${node.title} (${node.id}) [${node.children.length} children]',
    );

    for (final child in node.children) {
      _logTreeStructure(child, level + 1);
    }
  }

  // ========== HELPER METHODS ==========

  /// Generate slug from title
  String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with dashes
        .replaceAll(RegExp(r'-+'), '-') // Remove multiple dashes
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing dashes
  }
}

// ========== REQUEST/RESPONSE MODELS ==========

/// Create node request model
class CreateNodeRequest {
  final String title;
  final String slug;
  final String organizationId;
  final String contextId;
  final String? parentSlug;
  final Map<String, dynamic>? payload;

  const CreateNodeRequest({
    required this.title,
    required this.slug,
    required this.organizationId,
    required this.contextId,
    this.parentSlug,
    this.payload,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'title': title,
      'slug': slug,
      'organizationId': organizationId,
      'contextId': contextId,
    };

    if (parentSlug != null) data['parentSlug'] = parentSlug!;
    if (payload != null) data['payload'] = payload!;

    return data;
  }
}

/// Update node request model
class UpdateNodeRequest {
  final String organizationId;
  final String contextId;
  final String? title;
  final Map<String, dynamic>? payload;

  const UpdateNodeRequest({
    required this.organizationId,
    required this.contextId,
    this.title,
    this.payload,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'organizationId': organizationId,
      'contextId': contextId,
    };

    if (title != null) data['title'] = title!;
    if (payload != null) data['payload'] = payload!;

    return data;
  }
}

/// Delete node request model
class DeleteNodeRequest {
  final String organizationId;
  final String contextId;

  const DeleteNodeRequest({
    required this.organizationId,
    required this.contextId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'contextId': contextId,
    };
  }
}

/// Move node request model
class MoveNodeRequest {
  final String organizationId;
  final String contextId;
  final String? newParentId;
  final int? newOrderIndex;

  const MoveNodeRequest({
    required this.organizationId,
    required this.contextId,
    this.newParentId,
    this.newOrderIndex,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'organizationId': organizationId,
      'contextId': contextId,
    };

    if (newParentId != null) data['newParentId'] = newParentId!;
    if (newOrderIndex != null) data['newOrderIndex'] = newOrderIndex!;

    return data;
  }
}
