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
import '../../../../domain/entities/tree_node.dart';
import '../../../../domain/entities/mail_context.dart';
import '../../../../domain/entities/mail_recipient.dart';
import '../../../providers/state/mail_state.dart' hide MailContext;

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

          const SizedBox(height: 8),

          // Context information
          _buildContextInfo(context, ref, selectedContext),

          const SizedBox(height: 8),

          // Main tree section
          Expanded(child: _buildTreeSection(context, ref, treeState)),

          // System folders (Spam, Trash) - always at bottom
          _buildSystemFolders(context, ref),
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

  /// Context information display
  Widget _buildContextInfo(
    BuildContext context,
    WidgetRef ref,
    MailContext? mailContext,
  ) {
    if (mailContext == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bağlam seçilmedi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.email, size: 14, color: Colors.blue[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mailContext.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  mailContext.emailAddress,
                  style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tree refresh button
          IconButton(
            onPressed: () => _refreshTree(ref),
            icon: Icon(Icons.refresh, size: 16, color: Colors.blue[600]),
            tooltip: 'Klasörleri Yenile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
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
          _buildSectionHeader('Klasörler', ref),

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
  Widget _buildSectionHeader(String title, WidgetRef ref) {
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
            onPressed: () => _createNewFolder(ref),
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
      return _buildEmptyState(ref);
    }

    return MailTreeWidget(
      nodes: nodes,
      onNodeTap: (node) => _handleNodeTap(context, ref, node),
      onNodeExpand: (node) => _handleNodeExpand(ref, node),
      onNodeContextMenu: (node) => _handleNodeContextMenu(context, ref, node),
      onNodeDrop: (draggedNode, targetNode) =>
          _handleNodeDrop(ref, draggedNode, targetNode),
    );
  }

  /// Empty state when no custom folders exist
  Widget _buildEmptyState(WidgetRef ref) {
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
              onPressed: () => _createNewFolder(ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Klasör Oluştur'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// System folders section (Spam, Trash)
  Widget _buildSystemFolders(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        children: [
          _buildSystemFolderItem(
            context,
            ref,
            icon: Icons.report,
            title: 'Spam',
            folder: MailFolder.spam,
            color: Colors.orange[600],
          ),
          _buildSystemFolderItem(
            context,
            ref,
            icon: Icons.delete,
            title: 'Çöp',
            folder: MailFolder.trash,
            color: Colors.red[600],
          ),
        ],
      ),
    );
  }

  /// System folder item
  Widget _buildSystemFolderItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required MailFolder folder,
    Color? color,
  }) {
    final currentFolder = ref.watch(currentFolderProvider);
    final isSelected = currentFolder == folder;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : (color ?? Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      selectedTileColor: color?.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => _handleSystemFolderTap(context, ref, folder),
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
  void _createNewFolder(WidgetRef ref) {
    AppLogger.info('🆕 MailLeftBarV2: Creating new folder');
    // TODO: Implement create folder dialog
    // This will be implemented in next phase
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

  /// Handle tree node context menu
  void _handleNodeContextMenu(
    BuildContext context,
    WidgetRef ref,
    TreeNode node,
  ) {
    AppLogger.info('📋 MailLeftBarV2: Context menu for: ${node.title}');
    // TODO: Implement context menu
    // This will be implemented in next phase
  }

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

  /// Handle system folder tap
  void _handleSystemFolderTap(
    BuildContext context,
    WidgetRef ref,
    MailFolder folder,
  ) {
    AppLogger.info('📁 MailLeftBarV2: System folder tapped: $folder');

    // Create a TreeNode representation for consistency
    final systemNode = TreeNode(
      id: folder.toString(),
      title: _getSystemFolderTitle(folder),
      slug: _getSystemFolderSlug(folder),
      orderIndex: 0,
      scope: 'sys',
    );

    // Update selection
    ref.read(treeSelectionProvider).selectNode(systemNode);

    // Call callback if provided
    onFolderSelected?.call(systemNode);
  }

  // ========== HELPER METHODS ==========

  /// Extract user name from email
  String _extractUserNameFromEmail(String email) {
    return email.split('@').first;
  }

  /// Get system folder title
  String _getSystemFolderTitle(MailFolder folder) {
    switch (folder) {
      case MailFolder.spam:
        return 'Spam';
      case MailFolder.trash:
        return 'Çöp';
      default:
        return folder.toString();
    }
  }

  /// Get system folder slug
  String _getSystemFolderSlug(MailFolder folder) {
    switch (folder) {
      case MailFolder.spam:
        return 'spam';
      case MailFolder.trash:
        return 'trash';
      default:
        return folder.toString().toLowerCase();
    }
  }
}
