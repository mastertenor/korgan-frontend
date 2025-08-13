// lib/src/features/mail/presentation/widgets/web/sections/mail_leftbar_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/state/mail_state.dart';
import '../../../../../../routing/route_constants.dart';
import '../../../../../../utils/app_logger.dart';

/// Web mail sayfası için sol sidebar navigasyon widget'ı
/// 
/// ✅ UPDATED: URL-based navigation support added
/// - Direct URL navigation instead of callbacks
/// - Browser history support
/// - Clean separation of concerns
/// 
/// Özellikler:
/// - Folder listesi (Inbox, Starred, Sent, Drafts, Spam, Trash)
/// - Compose button
/// - Unread count indicators
/// - Active folder highlighting
/// - Gmail-benzeri tasarım
/// - URL-based folder navigation
class MailLeftBarSection extends ConsumerWidget {
  final String userEmail;
  
  /// 🔄 DEPRECATED: onFolderSelected callback (kept for backward compatibility)
  /// Use URL-based navigation instead
  final Function(MailFolder)? onFolderSelected;

  const MailLeftBarSection({
    super.key,
    required this.userEmail,
    this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider watches
    final currentFolder = ref.watch(currentFolderProvider);
    final isLoading = ref.watch(currentLoadingProvider);

    AppLogger.debug('🗂️ MailLeftBarSection: currentFolder=$currentFolder, isLoading=$isLoading');

    return Container(
      width: 240,
      decoration: _buildSidebarDecoration(),
      child: Column(
        children: [
          _buildComposeSection(context),
          const SizedBox(height: 8),
          Expanded(
            child: _buildFolderList(
              context,
              currentFolder: currentFolder,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }

  /// Sidebar decoration
  BoxDecoration _buildSidebarDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border(
        right: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
    );
  }

  /// Compose button section - UPDATED with context parameter
  Widget _buildComposeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _onComposePressed(context),
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

  /// Folder list section
  Widget _buildFolderList(
    BuildContext context, {
    required MailFolder currentFolder,
    required bool isLoading,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildFolderItem(
          context,
          folder: MailFolder.inbox,
          icon: Icons.inbox,
          title: 'Gelen Kutusu',
          isSelected: currentFolder == MailFolder.inbox,
          unreadCount: 0, // TODO: Implement
        ),
        _buildFolderItem(
          context,
          folder: MailFolder.starred,
          icon: Icons.star,
          title: 'Yıldızlı',
          isSelected: currentFolder == MailFolder.starred,
          unreadCount: 0, // TODO: Implement
          iconColor: Colors.amber,
        ),
        _buildFolderItem(
          context,
          folder: MailFolder.sent,
          icon: Icons.send,
          title: 'Gönderilmiş',
          isSelected: currentFolder == MailFolder.sent,
          unreadCount: 0, // TODO: Implement
        ),
        _buildFolderItem(
          context,
          folder: MailFolder.drafts,
          icon: Icons.drafts,
          title: 'Taslaklar',
          isSelected: currentFolder == MailFolder.drafts,
          unreadCount: 0, // TODO: Implement
        ),
        const SizedBox(height: 8),
        _buildSectionDivider('Diğer'),
        _buildFolderItem(
          context,
          folder: MailFolder.spam,
          icon: Icons.report,
          title: 'Spam',
          isSelected: currentFolder == MailFolder.spam,
          unreadCount: 0, // TODO: Implement
          iconColor: Colors.orange,
        ),
        _buildFolderItem(
          context,
          folder: MailFolder.trash,
          icon: Icons.delete,
          title: 'Çöp Kutusu',
          isSelected: currentFolder == MailFolder.trash,
          unreadCount: 0, // TODO: Implement
          iconColor: Colors.red[400],
        ),
      ],
    );
  }

  /// Individual folder item - UPDATED with context parameter and URL navigation
  Widget _buildFolderItem(
    BuildContext context, {
    required MailFolder folder,
    required IconData icon,
    required String title,
    required bool isSelected,
    required int unreadCount,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onFolderTap(context, folder),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.grey[100],
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.blue[100]?.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? Colors.blue[700] 
                      : (iconColor ?? Colors.grey[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.blue[700] : Colors.grey[800],
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section divider
  Widget _buildSectionDivider(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // ========== EVENT HANDLERS ==========

  /// Compose button pressed - UPDATED with URL navigation
  void _onComposePressed(BuildContext context) {
    AppLogger.info('🆕 Compose pressed for user: $userEmail');
    
    // TODO: Navigate to compose URL
    // final composePath = MailRoutes.composePath(userEmail);
    // context.go(composePath);
    
    // For now, show placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Compose özelliği yakında eklenecek'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🆕 Folder tapped - URL-based navigation
  void _onFolderTap(BuildContext context, MailFolder folder) {
    AppLogger.info('📁 Folder tapped: $folder for user: $userEmail');
    
    // Convert MailFolder enum to URL string
    final folderName = _mailFolderToUrlString(folder);
    
    // Generate folder path
    final folderPath = MailRoutes.folderPath(userEmail, folderName);
    
    // Navigate via URL
    context.go(folderPath);
    
    AppLogger.info('🔗 Navigating to: $folderPath');
    
    // 🔄 BACKWARD COMPATIBILITY: Call callback if provided
    // This allows existing code to continue working during transition
    onFolderSelected?.call(folder);
  }

  // ========== UTILITY METHODS ==========

  /// 🆕 Convert MailFolder enum to URL string
  String _mailFolderToUrlString(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return MailFolderNames.inbox;
      case MailFolder.sent:
        return MailFolderNames.sent;
      case MailFolder.drafts:
        return MailFolderNames.drafts;
      case MailFolder.spam:
        return MailFolderNames.spam;
      case MailFolder.trash:
        return MailFolderNames.trash;
      case MailFolder.starred:
        return MailFolderNames.starred;
      case MailFolder.important:
        return MailFolderNames.important;
      default:
        AppLogger.warning('❌ Unknown folder: $folder, defaulting to inbox');
        return MailFolderNames.inbox;
    }
  }
}