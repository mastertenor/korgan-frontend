// lib/src/features/mail/presentation/widgets/web/tree/mail_tree_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/tree_node.dart';
import 'tree_node_widget.dart';

/// Mail tree widget for displaying hierarchical folder structure
///
/// Features:
/// - Hierarchical tree display
/// - Expand/collapse functionality
/// - Node selection
/// - Context menu support
/// - Drag & drop support (planned)
class MailTreeWidget extends ConsumerWidget {
  final List<TreeNode> nodes;
  final Function(TreeNode)? onNodeTap;
  final Function(TreeNode)? onNodeExpand;
  final Function(TreeNode)? onNodeContextMenu;
  final Function(TreeNode, TreeNode)? onNodeDrop;

  const MailTreeWidget({
    super.key,
    required this.nodes,
    this.onNodeTap,
    this.onNodeExpand,
    this.onNodeContextMenu,
    this.onNodeDrop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];

        return RepaintBoundary(
          child: TreeNodeWidget(
            key: ValueKey(node.id),
            node: node,
            level: 0,
            onTap: onNodeTap,
            onExpand: onNodeExpand,
            onContextMenu: onNodeContextMenu,
            onDrop: onNodeDrop,
          ),
        );
      },
    );
  }
}
