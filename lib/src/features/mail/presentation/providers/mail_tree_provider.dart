// lib/src/features/mail/presentation/providers/mail_tree_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import 'mail_context_provider.dart';
import '../../domain/entities/tree_node.dart';
import '../../data/datasources/tree_api_service.dart';
import 'notifiers/mail_tree_notifier.dart';
import 'global_search_provider.dart';

// ========== DEPENDENCY INJECTION ==========

/// Tree API Service Provider
final treeApiServiceProvider = Provider<TreeApiService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return TreeApiService(apiClient);
});

// ========== MAIN TREE PROVIDER ==========

/// Mail Tree Provider - Main provider for tree state management
///
/// This provider automatically refreshes the tree when:
/// - Organization changes
/// - Mail context changes
/// - Manual refresh is triggered
/// - Automatically calculates initial expansion states
///
/// Returns AsyncValue<List<TreeNode>> for UI consumption
final mailTreeProvider =
    StateNotifierProvider.autoDispose<
      MailTreeNotifier,
      AsyncValue<List<TreeNode>>
    >((ref) {
      // Watch organization and context changes
      final selectedOrg = ref.watch(selectedOrganizationProvider);
      final selectedContext = ref.watch(selectedMailContextProvider);

      AppLogger.info(
        '🌳 TreeProvider: Creating notifier for org=${selectedOrg?.id}, ctx=${selectedContext?.id}',
      );

      // Create tree loaded callback for expansion state calculation
      void onTreeLoaded(List<TreeNode> nodes) {
        AppLogger.info('🎯 TreeProvider: Tree loaded callback triggered');
        _calculateAndSetInitialExpansionStates(ref, nodes);
      }

      // Create notifier with current organization and context
      final notifier = MailTreeNotifier(
        organizationId: selectedOrg?.id,
        contextId: selectedContext?.id,
        apiService: ref.read(treeApiServiceProvider),
        onTreeLoaded: onTreeLoaded, // 🎯 YENİ: Callback bağlantısı
      );

      // Listen to context changes and refresh tree
      ref.listen(selectedMailContextProvider, (previous, next) {
        if (previous?.id != next?.id) {
          AppLogger.info(
            '🔄 TreeProvider: Context changed ${previous?.emailAddress} → ${next?.emailAddress}',
          );

          // Only refresh if we have valid organization and context
          if (selectedOrg?.id != null && next?.id != null) {
            notifier.refreshTree();
          }
        }
      });

      // Listen to organization changes and refresh tree
      ref.listen(selectedOrganizationProvider, (previous, next) {
        if (previous?.id != next?.id) {
          AppLogger.info(
            '🔄 TreeProvider: Organization changed ${previous?.slug} → ${next?.slug}',
          );

          // Only refresh if we have valid organization and context
          if (next?.id != null && selectedContext?.id != null) {
            notifier.refreshTree();
          }
        }
      });

      // Listen to tree node selection changes and clear search if needed
      ref.listen(selectedTreeNodeProvider, (previous, next) {
        if (previous?.id != next?.id) {
          final isSearchActive = ref.read(globalSearchModeProvider);
          if (isSearchActive) {
            AppLogger.info(
              '🧹 TreeProvider: Node selection changed during search, clearing search',
            );
            ref.read(globalSearchControllerProvider).clearNodeSearch();
          }
        }
      });

      return notifier;
    });

// ========== EXPANSION STATE CALCULATION ==========

/// Tree yüklendikten sonra initial expansion state'leri hesapla ve set et
void _calculateAndSetInitialExpansionStates(Ref ref, List<TreeNode> nodes) {
  AppLogger.info('📂 TreeProvider: Calculating initial expansion states...');

  final expansionStates = <String, bool>{};
  _collectExpansionStates(nodes, expansionStates);

  // Mevcut expansion state'leri al
  final currentStates = ref.read(treeExpansionStateProvider);

  // Yeni hesaplanan state'lerle merge et (kullanıcının manual değişiklikleri korunur)
  final mergedStates = {...currentStates};

  // Sadece yeni node'lar için expansion state'i set et
  expansionStates.forEach((nodeId, shouldExpand) {
    if (!mergedStates.containsKey(nodeId)) {
      mergedStates[nodeId] = shouldExpand;
    }
  });

  // Expansion state provider'ı güncelle
  ref.read(treeExpansionStateProvider.notifier).state = mergedStates;

  AppLogger.info(
    '✅ TreeProvider: Set ${expansionStates.length} initial expansion states, total: ${mergedStates.length}',
  );

  // Debug: Hangi node'lar expand edildi?
  expansionStates.forEach((nodeId, shouldExpand) {
    if (shouldExpand) {
      final node = _findNodeById(nodes, nodeId);
      if (node != null) {
        AppLogger.debug('📂 Auto-expanding: ${node.title} (depth calculated)');
      }
    }
  });
}

/// Recursive olarak expansion state'leri topla
void _collectExpansionStates(
  List<TreeNode> nodes,
  Map<String, bool> expansionStates, {
  int currentDepth = 1,
}) {
  for (final node in nodes) {
    if (node.hasChildren) {
      final shouldExpand = _shouldNodeBeExpanded(node, currentDepth);
      expansionStates[node.id] = shouldExpand;

      // Çocuk node'ları da kontrol et (depth+1)
      _collectExpansionStates(
        node.children,
        expansionStates,
        currentDepth: currentDepth + 1,
      );
    }
  }
}

/// Node'un varsayılan olarak expand edilip edilmeyeceğini belirle
/// Depth-based expansion logic
bool _shouldNodeBeExpanded(TreeNode node, int currentDepth) {
  if (!node.hasChildren) return false;

  // Konfigurasyon: İlk 3 seviyeyi expand et (BANKALAR depth 3'te)
  const int maxAutoExpandDepth = 3;

  final shouldExpand = currentDepth <= maxAutoExpandDepth;

  AppLogger.debug(
    '📂 Expansion check: ${node.title} (depth=$currentDepth) → $shouldExpand',
  );

  return shouldExpand;
}

// ========== DERIVED PROVIDERS ==========

/// Selected tree node provider
final selectedTreeNodeProvider = StateProvider<TreeNode?>((ref) => null);

/// Current TreeNode provider (alias for selectedTreeNodeProvider)
/// Used by global search to determine which node is currently active
final currentTreeNodeProvider = Provider<TreeNode?>((ref) {
  return ref.watch(selectedTreeNodeProvider);
});

/// Tree expansion state provider
final treeExpansionStateProvider = StateProvider<Map<String, bool>>(
  (ref) => {},
);

/// Tree loading state provider
final treeLoadingStateProvider = Provider<bool>((ref) {
  final treeState = ref.watch(mailTreeProvider);
  return treeState.isLoading;
});

/// Tree error state provider
final treeErrorStateProvider = Provider<String?>((ref) {
  final treeState = ref.watch(mailTreeProvider);
  return treeState.hasError ? treeState.error.toString() : null;
});

/// Tree data provider (non-null when loaded successfully)
final treeDataProvider = Provider<List<TreeNode>>((ref) {
  final treeState = ref.watch(mailTreeProvider);
  return treeState.valueOrNull ?? [];
});

/// Tree node count provider
final treeNodeCountProvider = Provider<int>((ref) {
  final nodes = ref.watch(treeDataProvider);
  return _countAllNodes(nodes);
});

/// Root nodes provider (only top-level nodes)
final rootNodesProvider = Provider<List<TreeNode>>((ref) {
  final nodes = ref.watch(treeDataProvider);
  return nodes.where((node) => node.isRoot).toList();
});

/// System folders provider
final systemFoldersProvider = Provider<List<TreeNode>>((ref) {
  final nodes = ref.watch(treeDataProvider);
  return _getAllNodes(nodes).where((node) => node.isSystemFolder).toList();
});

/// Custom folders provider
final customFoldersProvider = Provider<List<TreeNode>>((ref) {
  final nodes = ref.watch(treeDataProvider);
  return _getAllNodes(nodes).where((node) => node.isCustomFolder).toList();
});

/// Find node by ID provider
final findNodeByIdProvider = Provider.family<TreeNode?, String>((ref, nodeId) {
  final nodes = ref.watch(treeDataProvider);
  return _findNodeById(nodes, nodeId);
});

/// Find node by slug provider
final findNodeBySlugProvider = Provider.family<TreeNode?, String>((ref, slug) {
  final nodes = ref.watch(treeDataProvider);
  return _findNodeBySlug(nodes, slug);
});

// ========== TREE OPERATION PROVIDERS ==========

/// Tree operations provider for CRUD actions
final treeOperationsProvider = Provider<TreeOperations>((ref) {
  final notifier = ref.read(mailTreeProvider.notifier);
  return TreeOperations(notifier);
});

/// Tree expansion operations provider
final treeExpansionProvider = Provider<TreeExpansionOperations>((ref) {
  return TreeExpansionOperations(ref);
});

/// Tree selection operations provider
final treeSelectionProvider = Provider<TreeSelectionOperations>((ref) {
  return TreeSelectionOperations(ref);
});

// ========== HELPER FUNCTIONS ==========

/// Count all nodes recursively
int _countAllNodes(List<TreeNode> nodes) {
  int count = nodes.length;
  for (final node in nodes) {
    count += _countAllNodes(node.children);
  }
  return count;
}

/// Get all nodes in flat list
List<TreeNode> _getAllNodes(List<TreeNode> nodes) {
  final allNodes = <TreeNode>[];

  void addNodeAndChildren(TreeNode node) {
    allNodes.add(node);
    for (final child in node.children) {
      addNodeAndChildren(child);
    }
  }

  for (final node in nodes) {
    addNodeAndChildren(node);
  }

  return allNodes;
}

/// Find node by ID recursively
TreeNode? _findNodeById(List<TreeNode> nodes, String nodeId) {
  for (final node in nodes) {
    if (node.id == nodeId) return node;

    final found = _findNodeById(node.children, nodeId);
    if (found != null) return found;
  }
  return null;
}

/// Find node by slug recursively
TreeNode? _findNodeBySlug(List<TreeNode> nodes, String slug) {
  for (final node in nodes) {
    if (node.slug == slug) return node;

    final found = _findNodeBySlug(node.children, slug);
    if (found != null) return found;
  }
  return null;
}

// ========== OPERATION CLASSES ==========

/// Tree CRUD operations wrapper
class TreeOperations {
  final MailTreeNotifier _notifier;

  TreeOperations(this._notifier);

  /// Create new node
  Future<TreeOperationResult> createNode({
    required String title,
    String? parentSlug,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _notifier.createNode(
        title: title,
        parentSlug: parentSlug,
        payload: payload,
      );
      return TreeOperationResult.success(
        message: 'Klasör başarıyla oluşturuldu',
      );
    } catch (e) {
      AppLogger.error('❌ TreeOperations: Create failed - $e');
      return TreeOperationResult.failure(message: 'Klasör oluşturulamadı: $e');
    }
  }

  /// Update existing node
  Future<TreeOperationResult> updateNode({
    required String nodeId,
    String? title,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _notifier.updateNode(nodeId, title: title, payload: payload);
      return TreeOperationResult.success(
        message: 'Klasör başarıyla güncellendi',
      );
    } catch (e) {
      AppLogger.error('❌ TreeOperations: Update failed - $e');
      return TreeOperationResult.failure(message: 'Klasör güncellenemedi: $e');
    }
  }

  /// Delete node
  Future<TreeOperationResult> deleteNode(String nodeId) async {
    try {
      await _notifier.deleteNode(nodeId);
      return TreeOperationResult.success(message: 'Klasör başarıyla silindi');
    } catch (e) {
      AppLogger.error('❌ TreeOperations: Delete failed - $e');
      return TreeOperationResult.failure(message: 'Klasör silinemedi: $e');
    }
  }

  /// Move node
  Future<TreeOperationResult> moveNode({
    required String nodeId,
    String? newParentId,
    int? newOrderIndex,
  }) async {
    try {
      await _notifier.moveNode(
        nodeId,
        newParentId: newParentId,
        newOrderIndex: newOrderIndex,
      );
      return TreeOperationResult.success(message: 'Klasör başarıyla taşındı');
    } catch (e) {
      AppLogger.error('❌ TreeOperations: Move failed - $e');
      return TreeOperationResult.failure(message: 'Klasör taşınamadı: $e');
    }
  }

  /// Refresh tree
  Future<void> refreshTree() async {
    await _notifier.refreshTree();
  }
}

/// Tree expansion operations
class TreeExpansionOperations {
  final Ref _ref;

  TreeExpansionOperations(this._ref);

  /// Toggle node expansion
  void toggleExpansion(String nodeId) {
    final currentState = _ref.read(treeExpansionStateProvider);
    final newState = {...currentState};
    newState[nodeId] = !(newState[nodeId] ?? false);
    _ref.read(treeExpansionStateProvider.notifier).state = newState;

    AppLogger.debug('🔄 TreeExpansion: Toggled $nodeId = ${newState[nodeId]}');
  }

  /// Set expansion state
  void setExpansion(String nodeId, bool expanded) {
    final currentState = _ref.read(treeExpansionStateProvider);
    final newState = {...currentState};
    newState[nodeId] = expanded;
    _ref.read(treeExpansionStateProvider.notifier).state = newState;

    AppLogger.debug('🔄 TreeExpansion: Set $nodeId = $expanded');
  }

  /// Check if node is expanded
  bool isExpanded(String nodeId) {
    final state = _ref.read(treeExpansionStateProvider);
    return state[nodeId] ?? false;
  }

  /// Expand all nodes
  void expandAll() {
    final nodes = _ref.read(treeDataProvider);
    final allNodes = _getAllNodes(nodes);

    final newState = <String, bool>{};
    for (final node in allNodes) {
      if (node.hasChildren) {
        newState[node.id] = true;
      }
    }

    _ref.read(treeExpansionStateProvider.notifier).state = newState;
    AppLogger.info('🔄 TreeExpansion: Expanded all nodes');
  }

  /// Collapse all nodes
  void collapseAll() {
    _ref.read(treeExpansionStateProvider.notifier).state = {};
    AppLogger.info('🔄 TreeExpansion: Collapsed all nodes');
  }

  /// Set initial expansion states (for smart defaults)
  void setInitialExpansionStates(Map<String, bool> initialStates) {
    final currentState = _ref.read(treeExpansionStateProvider);
    final mergedState = {...currentState, ...initialStates};
    _ref.read(treeExpansionStateProvider.notifier).state = mergedState;

    AppLogger.info(
      '🔄 TreeExpansion: Set ${initialStates.length} initial states',
    );
  }
}

/// Tree selection operations
class TreeSelectionOperations {
  final Ref _ref;

  TreeSelectionOperations(this._ref);

  /// Select node
  void selectNode(TreeNode? node) {
    _ref.read(selectedTreeNodeProvider.notifier).state = node;

    if (node != null) {
      AppLogger.info('🎯 TreeSelection: Selected ${node.title} (${node.slug})');
    } else {
      AppLogger.info('🎯 TreeSelection: Cleared selection');
    }
  }

  /// Get selected node
  TreeNode? getSelectedNode() {
    return _ref.read(selectedTreeNodeProvider);
  }

  /// Check if node is selected
  bool isSelected(String nodeId) {
    final selected = _ref.read(selectedTreeNodeProvider);
    return selected?.id == nodeId;
  }

  /// Clear selection
  void clearSelection() {
    selectNode(null);
  }

  /// Select node and clear any active global search
  void selectNodeAndClearSearch(TreeNode? node) {
    // First clear any active global search
    if (_ref.read(globalSearchModeProvider)) {
      AppLogger.info(
        '🧹 TreeSelection: Clearing global search before node selection',
      );
      _ref.read(globalSearchControllerProvider).clearNodeSearch();
    }

    // Then select the node
    selectNode(node);
  }
}
