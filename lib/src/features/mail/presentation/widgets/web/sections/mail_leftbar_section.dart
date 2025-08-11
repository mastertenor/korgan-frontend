// lib/src/features/mail/presentation/widgets/web/sections/mail_leftbar_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/state/mail_state.dart';

/// Web mail sayfası için sol sidebar navigasyon widget'ı
/// 
/// Özellikler:
/// - Folder listesi (Inbox, Starred, Sent, Drafts, Spam, Trash)
/// - Compose button
/// - Unread count indicators
/// - Active folder highlighting
/// - Gmail-benzeri tasarım
class MailLeftBarSection extends ConsumerWidget {
  final String userEmail;
  final Function(MailFolder)? onFolderSelected;

  const MailLeftBarSection({
    super.key,
    required this.userEmail,
    this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider watches (şimdilik temel olanlar)
    final currentFolder = ref.watch(currentFolderProvider);
    final isLoading = ref.watch(currentLoadingProvider);

    return Container(
      width: 240,
      decoration: _buildSidebarDecoration(),
      child: Column(
        children: [
          _buildComposeSection(),
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

  /// Compose button section
  Widget _buildComposeSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onComposePressed,
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
          folder: MailFolder.inbox,
          icon: Icons.inbox,
          title: 'Gelen Kutusu',
          isSelected: currentFolder == MailFolder.inbox,
          unreadCount: 0, // TODO: Implement
        ),
        _buildFolderItem(
          folder: MailFolder.starred,
          icon: Icons.star,
          title: 'Yıldızlı',
          isSelected: currentFolder == MailFolder.starred,
          unreadCount: 0, // TODO: Implement
          iconColor: Colors.amber,
        ),
        _buildFolderItem(
          folder: MailFolder.sent,
          icon: Icons.send,
          title: 'Gönderilmiş',
          isSelected: currentFolder == MailFolder.sent,
          unreadCount: 0, // TODO: Implement
        ),
        _buildFolderItem(
          folder: MailFolder.drafts,
          icon: Icons.drafts,
          title: 'Taslaklar',
          isSelected: currentFolder == MailFolder.drafts,
          unreadCount: 0, // TODO: Implement
        ),
        const SizedBox(height: 8),
        _buildSectionDivider('Diğer'),
        _buildFolderItem(
          folder: MailFolder.spam,
          icon: Icons.report,
          title: 'Spam',
          isSelected: currentFolder == MailFolder.spam,
          unreadCount: 0, // TODO: Implement
          iconColor: Colors.orange,
        ),
        _buildFolderItem(
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

  /// Individual folder item
  Widget _buildFolderItem({
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
          onTap: () => _onFolderTap(folder),
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

  /// Compose button pressed
  void _onComposePressed() {
    // TODO: Navigate to compose page
    debugPrint('🆕 Compose pressed for user: $userEmail');
  }

  /// Folder tapped
  void _onFolderTap(MailFolder folder) {
    debugPrint('📁 Folder tapped: $folder');
    
    // Call callback if provided
    onFolderSelected?.call(folder);
  }
}