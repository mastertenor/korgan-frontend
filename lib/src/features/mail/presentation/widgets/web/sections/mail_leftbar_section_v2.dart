// lib/src/features/mail/presentation/widgets/web/sections/mail_leftbar_section_v2.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/mail_context_provider.dart';
import '../../../providers/mail_tree_provider.dart';
import '../../../../../organization/presentation/providers/organization_providers.dart';
import '../tree/mail_tree_widget.dart';
import '../tree/tree_loading_skeleton.dart';
import '../tree/tree_error_widget.dart';
import '../dialogs/folder_crud_dialog.dart';
import '../../../../domain/entities/tree_node.dart';
import '../../../../domain/entities/mail_recipient.dart';

/// Mail Left Bar Section V2 - Tree-based folder navigation
///
/// Features:
/// - Dynamic tree structure from backend API
/// - Context-based folder management
/// - CRUD operations (create, update, delete, move)
/// - Drag & drop support
/// - Expandable/collapsible tree
/// - Organization and context switching
class MailLeftBarSectionV2 extends ConsumerWidget {
  final String userEmail;
  final Function(TreeNode)? onFolderSelected;

  const MailLeftBarSectionV2({
    super.key,
    required this.userEmail,
    this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final selectedOrg = ref.watch(selectedOrganizationProvider);
    final selectedContext = ref.watch(selectedMailContextProvider);
    final treeState = ref.watch(mailTreeProvider);

    AppLogger.debug(
      '🗂️ MailLeftBarV2: org=${selectedOrg?.slug}, ctx=${selectedContext?.emailAddress}',
    );

    return Container(
      width: 260, // Slightly wider than V1 for tree indentation
      decoration: _buildSidebarDecoration(),
      child: Column(
        children: [
          // Header with compose button
          _buildHeader(context, ref),
          //const SizedBox(height: 8),
          // Main tree section
          Expanded(child: _buildTreeSection(context, ref, treeState)),

          // System folders (Spam, Trash) - always at bottom
          //_buildSystemFolders(context, ref),
        ],
      ),
    );
  }

  // ========== UI BUILDERS ==========

  /// Sidebar decoration
  BoxDecoration _buildSidebarDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: Colors.grey[300]!, width: 1)),
    );
  }

  /// Header section with compose button
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _onComposePressed(context, ref),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Oluştur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  /// Tree section with loading, error, and data states
  Widget _buildTreeSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TreeNode>> treeState,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(context, ref, 'Klasörler'),

          const SizedBox(height: 8),

          // Tree content
          Expanded(
            child: treeState.when(
              loading: () => const TreeLoadingSkeleton(),
              error: (error, stack) => TreeErrorWidget(
                error: error,
                onRetry: () => _refreshTree(ref),
              ),
              data: (nodes) => _buildTreeContent(context, ref, nodes),
            ),
          ),
        ],
      ),
    );
  }

  /// Section header with actions
  Widget _buildSectionHeader(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          // Add folder button
          IconButton(
            onPressed: () => _createNewFolder(context, ref),
            icon: Icon(Icons.add, size: 14, color: Colors.grey[600]),
            tooltip: 'Yeni Klasör',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          ),
        ],
      ),
    );
  }

  /// Tree content display
  Widget _buildTreeContent(
    BuildContext context,
    WidgetRef ref,
    List<TreeNode> nodes,
  ) {
    if (nodes.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return MailTreeWidget(
      nodes: nodes,
      onNodeTap: (node) => _handleNodeTap(context, ref, node),
      onNodeExpand: (node) => _handleNodeExpand(ref, node),
      //onNodeContextMenu: (node) => _handleNodeContextMenu(context, ref, node),
      onNodeDrop: (draggedNode, targetNode) =>
          _handleNodeDrop(ref, draggedNode, targetNode),
    );
  }

  /// Empty state when no custom folders exist
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz klasör yok',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk klasörünüzü oluşturun',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _createNewFolder(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Klasör Oluştur'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ========== EVENT HANDLERS ==========

  /// Handle compose button press
  void _onComposePressed(BuildContext context, WidgetRef ref) {
    AppLogger.info('🆕 MailLeftBarV2: Compose pressed for user: $userEmail');

    try {
      final composeNotifier = ref.read(mailComposeProvider.notifier);
      composeNotifier.clearAll();

      final userName = _extractUserNameFromEmail(userEmail);
      final sender = MailRecipient(email: userEmail, name: userName);
      composeNotifier.initializeWithSender(sender);

      ref.read(mailComposeModalProvider.notifier).openModal();

      AppLogger.info('✅ MailLeftBarV2: Compose modal opened successfully');
    } catch (e) {
      AppLogger.error('❌ MailLeftBarV2: Failed to open compose modal: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modal açılamadı: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle tree refresh
  void _refreshTree(WidgetRef ref) {
    AppLogger.info('🔄 MailLeftBarV2: Refreshing tree');
    ref.read(treeOperationsProvider).refreshTree();
  }

  /// Handle create new folder
  void _createNewFolder(BuildContext context, WidgetRef ref) {
    AppLogger.info('📂 MailLeftBarV2: Creating new folder');
    showCreateFolderDialog(context, ref);
  }

  /// Handle tree node tap
  void _handleNodeTap(BuildContext context, WidgetRef ref, TreeNode node) {
    AppLogger.info(
      '🎯 MailLeftBarV2: Node tapped: ${node.title} (${node.slug})',
    );

    // Update selection
    ref.read(treeSelectionProvider).selectNode(node);

    // Call callback if provided
    onFolderSelected?.call(node);
  }

  /// Handle tree node expand/collapse
  void _handleNodeExpand(WidgetRef ref, TreeNode node) {
    AppLogger.debug('🔄 MailLeftBarV2: Toggling expansion for: ${node.title}');
    ref.read(treeExpansionProvider).toggleExpansion(node.id);
  }


  /// Handle context menu action selection

  /// Handle node drag & drop
  void _handleNodeDrop(
    WidgetRef ref,
    TreeNode draggedNode,
    TreeNode targetNode,
  ) {
    AppLogger.info(
      '🔄 MailLeftBarV2: Drop ${draggedNode.title} onto ${targetNode.title}',
    );
    // TODO: Implement drag & drop
    // This will be implemented in next phase
  }

  // ========== HELPER METHODS ==========

  /// Extract user name from email
  String _extractUserNameFromEmail(String email) {
    return email.split('@').first;
  }
}
