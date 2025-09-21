// lib/src/features/mail/presentation/widgets/web/tree/tree_node_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/tree_node.dart';
import '../../../providers/mail_tree_provider.dart';
import '../dialogs/folder_crud_dialog.dart';

/// Tree node widget for displaying individual nodes in the tree
///
/// Features:
/// - Hierarchical indentation
/// - Expand/collapse indicator
/// - Selection state
/// - Context menu
/// - Drag & drop (planned)
/// - Recursive child rendering
class TreeNodeWidget extends ConsumerWidget {
  final TreeNode node;
  final int level;
  final Function(TreeNode)? onTap;
  final Function(TreeNode)? onExpand;
  final Function(TreeNode)? onContextMenu;
  final Function(TreeNode, TreeNode)? onDrop;

  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.level,
    this.onTap,
    this.onExpand,
    this.onContextMenu,
    this.onDrop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(treeExpansionStateProvider)[node.id] ?? false;
    final isSelected = ref.watch(selectedTreeNodeProvider)?.id == node.id;

    return Column(
      children: [
        // Node item
        _buildNodeItem(context, ref, isExpanded, isSelected),

        // Children (if expanded)
        if (isExpanded && node.hasChildren)
          ...node.children.map(
            (child) => TreeNodeWidget(
              key: ValueKey(child.id),
              node: child,
              level: level + 1,
              onTap: onTap,
              onExpand: onExpand,
              onContextMenu: onContextMenu,
              onDrop: onDrop,
            ),
          ),
      ],
    );
  }

  /// Build the main node item
  Widget _buildNodeItem(
    BuildContext context,
    WidgetRef ref,
    bool isExpanded,
    bool isSelected,
  ) {
    const double indentSize = 16.0;
    final double leftPadding = 8.0 + (level * indentSize);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onTap?.call(node),
          onSecondaryTap: () => onContextMenu?.call(node),
          child: Container(
            padding: EdgeInsets.only(
              left: leftPadding,
              right: 8,
              top: 6,
              bottom: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                // Expand/collapse indicator
                _buildExpandIndicator(isExpanded),

                const SizedBox(width: 6),

                // Node icon
                _buildNodeIcon(),

                const SizedBox(width: 8),

                // Node title
                Expanded(child: _buildNodeTitle(isSelected)),

                // Node actions
                _buildNodeActions(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build expand/collapse indicator
  Widget _buildExpandIndicator(bool isExpanded) {
    if (!node.hasChildren) {
      return const SizedBox(width: 16); // Empty space for alignment
    }

    return GestureDetector(
      onTap: () => onExpand?.call(node),
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
          size: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Build node icon
  Widget _buildNodeIcon() {
    IconData iconData;
    Color? iconColor;

    // Get icon based on node type and state
    switch (node.displayIcon) {
      case 'folder':
        iconData = Icons.folder;
        iconColor = Colors.amber[700];
        break;
      case 'folder_open':
        iconData = Icons.folder_open;
        iconColor = Colors.amber[700];
        break;
      case 'inbox':
        iconData = Icons.inbox;
        iconColor = Colors.blue[600];
        break;
      case 'send':
        iconData = Icons.send;
        iconColor = Colors.green[600];
        break;
      case 'drafts':
        iconData = Icons.drafts;
        iconColor = Colors.orange[600];
        break;
      case 'star':
        iconData = Icons.star;
        iconColor = Colors.yellow[700];
        break;
      case 'label_important':
        iconData = Icons.label_important;
        iconColor = Colors.red[600];
        break;
      case 'report':
        iconData = Icons.report;
        iconColor = Colors.orange[600];
        break;
      case 'delete':
        iconData = Icons.delete;
        iconColor = Colors.red[600];
        break;
      default:
        iconData = Icons.folder;
        iconColor = Colors.grey[600];
    }

    // Apply custom color if specified
    if (node.displayColor != null) {
      try {
        iconColor = Color(
          int.parse(node.displayColor!.replaceFirst('#', '0xFF')),
        );
      } catch (e) {
        // Keep default color if parsing fails
      }
    }

    return Icon(iconData, size: 16, color: iconColor);
  }

  /// Build node title with unread count and scope indicator
  Widget _buildNodeTitle(bool isSelected) {
    return Row(
      children: [
        // Title text
        Expanded(
          child: Row(
            children: [
              // Main title
              Flexible(
                child: Text(
                  node.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.blue[700] : Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Scope indicator
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getScopeColor(node.scope).withOpacity(0.1),
                  border: Border.all(
                    color: _getScopeColor(node.scope).withOpacity(0.3),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.scope.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: _getScopeColor(node.scope),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Unread count badge
        if (node.unreadCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              node.unreadCount > 99 ? '99+' : node.unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Get color for scope indicator
  Color _getScopeColor(String scope) {
    switch (scope.toLowerCase()) {
      case 'sys':
        return Colors.blue[600]!; // System folders - blue
      case 'org':
        return Colors.green[600]!; // Organization folders - green
      case 'usr':
        return Colors.purple[600]!; // User folders - purple
      case 'ctx':
        return Colors.orange[600]!; // Context folders - orange
      default:
        return Colors.grey[600]!; // Unknown scope - grey
    }
  }

  /// Build node actions (hover actions)
  Widget _buildNodeActions(BuildContext context, WidgetRef ref) {
    // Only show actions for custom folders
    if (!node.isCustomFolder) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: Icon(Icons.more_vert, size: 14, color: Colors.grey[500]),
        tooltip: 'Klasör İşlemleri',
        itemBuilder: (context) => [
          if (node.canCreate) ...[
            const PopupMenuItem(
              value: 'create_subfolder',
              child: Row(
                children: [
                  Icon(Icons.create_new_folder, size: 16),
                  SizedBox(width: 8),
                  Text('Alt Klasör'),
                ],
              ),
            ),
          ],
          if (node.canUpdate) ...[
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Yeniden Adlandır'),
                ],
              ),
            ),
          ],
          if (node.canDelete) ...[
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ],
        onSelected: (action) => _handleAction(context, ref, action),
      ),
    );
  }

  /// Handle action selection
  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'create_subfolder':
        // Select this node as parent for the new subfolder
        ref.read(treeSelectionProvider).selectNode(node);
        showCreateFolderDialog(context, ref);
        break;
      case 'rename':
        showRenameFolderDialog(context, ref, node);
        break;
      case 'delete':
        showDeleteFolderDialog(context, ref, node);
        break;
    }
  }
}
