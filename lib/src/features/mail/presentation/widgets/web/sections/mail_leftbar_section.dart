// lib/src/features/mail/presentation/widgets/web/sections/mail_leftbar_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/global_search_provider.dart';  // 🆕 GLOBAL SEARCH IMPORT
import '../../../providers/state/mail_state.dart';
import '../../../../../../routing/route_constants.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../../domain/entities/mail_recipient.dart';


/// Web mail sayfası için sol sidebar navigasyon widget'ı
/// 
/// ✅ UPDATED: Search clear integration added
/// - Clears search when folder is changed
/// - Maintains URL-based navigation support
/// - Browser history support
/// - Clean separation of concerns
/// 
/// Özellikler:
/// - Folder listesi (Inbox, Starred, Sent, Drafts, Spam, Trash)
/// - Compose button (Modal açar)
/// - 🆕 Search clear on folder navigation
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
    
    // 🆕 SEARCH STATE WATCHES
    final isSearchMode = ref.watch(globalSearchModeProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);

    AppLogger.debug('🗂️ MailLeftBarSection: currentFolder=$currentFolder, isLoading=$isLoading');
    AppLogger.debug('🔍 MailLeftBarSection: searchMode=$isSearchMode, query="$searchQuery"');

    return Container(
      width: 240,
      decoration: _buildSidebarDecoration(),
      child: Column(
        children: [
          _buildComposeSection(context, ref),
          const SizedBox(height: 8),

          Expanded(
            child: _buildFolderList(
              context,
              ref: ref,  // 🆕 REF PARAMETER ADDED
              currentFolder: currentFolder,
              isLoading: isLoading,
              isSearchMode: isSearchMode,  // 🆕 SEARCH MODE CONTEXT
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
  Widget _buildComposeSection(BuildContext context, WidgetRef ref) {
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

  /// UPDATED: Folder list section with search context
  Widget _buildFolderList(
    BuildContext context, {
    required WidgetRef ref,  // 🆕 REF PARAMETER
    required MailFolder currentFolder,
    required bool isLoading,
    required bool isSearchMode,  // 🆕 SEARCH MODE PARAMETER
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildFolderItem(
          context,
          ref: ref,  // 🆕 REF PARAMETER
          folder: MailFolder.inbox,
          icon: Icons.inbox,
          title: 'Gelen Kutusu',
          isSelected: currentFolder == MailFolder.inbox,
          isSearchMode: isSearchMode,  // 🆕 SEARCH CONTEXT
        ),
        _buildFolderItem(
          context,
          ref: ref,
          folder: MailFolder.starred,
          icon: Icons.star,
          title: 'Yıldızlı',
          isSelected: currentFolder == MailFolder.starred,
          iconColor: Colors.amber,
          isSearchMode: isSearchMode,
        ),
        _buildFolderItem(
          context,
          ref: ref,
          folder: MailFolder.sent,
          icon: Icons.send,
          title: 'Gönderilmiş',
          isSelected: currentFolder == MailFolder.sent,
          isSearchMode: isSearchMode,
        ),
        _buildFolderItem(
          context,
          ref: ref,
          folder: MailFolder.drafts,
          icon: Icons.drafts,
          title: 'Taslaklar',
          isSelected: currentFolder == MailFolder.drafts,
          isSearchMode: isSearchMode,
        ),
        const SizedBox(height: 8),
        _buildSectionDivider('Diğer'),
        _buildFolderItem(
          context,
          ref: ref,
          folder: MailFolder.spam,
          icon: Icons.report,
          title: 'Spam',
          isSelected: currentFolder == MailFolder.spam,
          
          iconColor: Colors.orange,
          isSearchMode: isSearchMode,
        ),
        _buildFolderItem(
          context,
          ref: ref,
          folder: MailFolder.trash,
          icon: Icons.delete,
          title: 'Çöp Kutusu',
          isSelected: currentFolder == MailFolder.trash,
          
          iconColor: Colors.red[400],
          isSearchMode: isSearchMode,
        ),
      ],
    );
  }

  /// UPDATED: Individual folder item with search clear functionality
/// UPDATED: Individual folder item with label stats badge
  Widget _buildFolderItem(
    BuildContext context, {
    required WidgetRef ref,
    required MailFolder folder,
    required IconData icon,
    required String title,
    required bool isSelected,
    
    Color? iconColor,
    required bool isSearchMode,
  }) {
    // 🆕 Watch label stats for this folder
    

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onFolderTap(context, ref, folder, isSearchMode),
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
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: isSelected ? Colors.blue[700] : Colors.grey[800],
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
  void _onComposePressed(BuildContext context, WidgetRef ref) {
    AppLogger.info('🆕 Compose pressed for user: $userEmail');
    
    try {
      final composeNotifier = ref.read(mailComposeProvider.notifier);
      composeNotifier.clearAll();
      
      final userName = _extractUserNameFromEmail(userEmail);
      final sender = MailRecipient(
        email: userEmail,
        name: userName,
      );
      composeNotifier.initializeWithSender(sender);
      
      ref.read(mailComposeModalProvider.notifier).openModal();
      
      AppLogger.info('✅ Compose modal opened successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to open compose modal: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modal açılamadı: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// UPDATED: Folder tapped with search clear functionality
  void _onFolderTap(BuildContext context, WidgetRef ref, MailFolder folder, bool isSearchMode) {
    AppLogger.info('📁 Folder tapped: $folder for user: $userEmail (searchMode: $isSearchMode)');
    
    // 🆕 CLEAR SEARCH IF ACTIVE
    if (isSearchMode) {
      AppLogger.info('🧹 Clearing search before folder navigation');
      final searchController = ref.read(globalSearchControllerProvider);
      searchController.clearSearch();
    }
    
    // Convert MailFolder enum to URL string
    final folderName = _mailFolderToUrlString(folder);
    
    // Generate folder path
    final folderPath = MailRoutes.folderPath(userEmail, folderName);
    
    // Navigate via URL
    context.go(folderPath);
    
    AppLogger.info('🔗 Navigating to: $folderPath');
    
    // 🔄 BACKWARD COMPATIBILITY: Call callback if provided
    onFolderSelected?.call(folder);
  }


  // ========== UTILITY METHODS ==========

  /// Extract user name from email
  String _extractUserNameFromEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      return email.substring(0, atIndex);
    }
    return email;
  }

  /// Convert MailFolder enum to URL string
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