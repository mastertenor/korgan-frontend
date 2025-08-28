// lib/src/features/mail/presentation/widgets/web/sections/mail_list_section_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/global_search_provider.dart';
import '../../mail_item/platform/web/mail_item_web.dart';

/// Web mail listesi bölümü - Hover actions destekli + Global Search Integration
/// 
/// Özellikler:
/// - Gmail-style hover actions (sil, okundu/okunmadı işaretle, arşivle)
/// - UPDATED: Global search results integration
/// - UPDATED: Empty search state support
/// - Smooth animations
/// - Provider-based state management
/// - Platform-specific design (sadece web)
class MailListSectionWeb extends ConsumerWidget {
  final String userEmail;
  final String? selectedMailId;
  final Set<String> selectedMails;
  final bool isPreviewPanelVisible;
  final Function(String)? onMailSelected;
  final Function(String, bool) onMailCheckboxChanged;
  
  const MailListSectionWeb({
    super.key,
    required this.userEmail,
    required this.selectedMailId,
    required this.selectedMails,
    required this.isPreviewPanelVisible,
    this.onMailSelected,
    required this.onMailCheckboxChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UPDATED: Use GlobalSearchIntegration helper for smart state selection
    final currentMails = GlobalSearchIntegration.getMailList(ref);
    final isLoading = GlobalSearchIntegration.getLoadingState(ref);
    final error = GlobalSearchIntegration.getErrorState(ref);
    
    // UPDATED: Additional search-specific state
    final isSearchMode = ref.watch(globalSearchModeProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);

    return _buildMailList(
      context: context,
      ref: ref,
      currentMails: currentMails,
      isLoading: isLoading,
      error: error,
      isSearchMode: isSearchMode,
      searchQuery: searchQuery,
    );
  }

  /// Ana mail list container'ı - UPDATED with search context
  Widget _buildMailList({
    required BuildContext context,
    required WidgetRef ref,
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
    required bool isSearchMode,
    required String searchQuery,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isPreviewPanelVisible 
            ? Border(right: BorderSide(color: Colors.grey[300]!))
            : null,
      ),
      child: Column(
        children: [
          // UPDATED: Search mode indicator (optional - can be removed if not needed)
          if (isSearchMode && searchQuery.isNotEmpty)
            _buildSearchModeIndicator(searchQuery, currentMails.length),
          
          // Mail List Content
          Expanded(
            child: _buildMailListContent(
              context: context,
              ref: ref,
              currentMails: currentMails,
              isLoading: isLoading,
              error: error,
              isSearchMode: isSearchMode,
              searchQuery: searchQuery,
            ),
          ),
        ],
      ),
    );
  }

  /// UPDATED: Search mode indicator (subtle header showing search info)
  Widget _buildSearchModeIndicator(String query, int resultCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100]!, width: 1),
        ),
      ),
      child: Text(
        '"$query" için $resultCount sonuç',
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// UPDATED: Mail list içeriği - loading, error, empty, search states ile
  Widget _buildMailListContent({
    required BuildContext context,
    required WidgetRef ref,
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
    required bool isSearchMode,
    required String searchQuery,
  }) {
    // Loading state
    if (isLoading && currentMails.isEmpty) {
      return _buildLoadingState(isSearchMode);
    }

    // Error state  
    if (error != null && currentMails.isEmpty) {
      return _buildErrorState(error, isSearchMode);
    }

    // UPDATED: Empty state - differentiate between folder empty and search empty
    if (currentMails.isEmpty) {
      if (isSearchMode && searchQuery.isNotEmpty) {
        return _buildEmptySearchState(context, ref, searchQuery);
      } else {
        return _buildEmptyFolderState();
      }
    }

    // Mail list
    return _buildMailListView(currentMails, ref);
  }

  /// UPDATED: Loading state with search context
  Widget _buildLoadingState(bool isSearchMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            isSearchMode ? 'Aranıyor...' : 'E-postalar yükleniyor...',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// UPDATED: Error state with search context
  Widget _buildErrorState(String error, bool isSearchMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isSearchMode ? 'Arama başarısız' : 'Mailler yüklenemedi',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Folder empty state (original)
  Widget _buildEmptyFolderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Gelen kutunuz boş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// NEW: Empty search state with clear search button
  Widget _buildEmptySearchState(BuildContext context, WidgetRef ref, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aramanızla eşleşen sonuç yok',
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$query" için sonuç bulunamadı',
            style: TextStyle(
              fontSize: 14, 
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _clearSearchFromEmptyState(ref),
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Aramayı Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showSearchTips(context),
            child: Text(
              'Arama ipuçları',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// NEW: Clear search from empty state
  void _clearSearchFromEmptyState(WidgetRef ref) {
    final searchController = ref.read(globalSearchControllerProvider);
    searchController.clearSearch();
  }

  /// NEW: Show search tips dialog
  void _showSearchTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arama İpuçları'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Farklı anahtar kelimeler deneyin'),
            Text('• Daha kısa veya genel terimler kullanın'),
            Text('• Yazım hatalarını kontrol edin'),
            Text('• Gönderen adı ile arama yapın'),
            Text('• E-posta konusu ile arama yapın'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Mail list view (existing logic)
  Widget _buildMailListView(List<Mail> currentMails, WidgetRef ref) {
    return ListView.builder(
      itemCount: currentMails.length,
      itemBuilder: (context, index) {
        final mail = currentMails[index];
        return _buildMailListItem(context, ref, mail, index);
      },
    );
  }

  /// Tek mail item'ı - MailItemWeb kullanımı (unchanged)
  Widget _buildMailListItem(BuildContext context, WidgetRef ref, Mail mail, int index) {
    final isSelected = selectedMails.contains(mail.id);
    final currentSelectedMailId = ref.watch(selectedMailIdProvider);
    final isCurrentlySelected = currentSelectedMailId == mail.id;
    
    return Material(
      color: isCurrentlySelected 
          ? Colors.blue.withOpacity(0.1)
          : Colors.transparent,
      child: MailItemWeb(
        mail: mail,
        isSelected: isSelected,
        onTap: () => _handleMailTap(ref, mail.id),
        onToggleSelection: () => onMailCheckboxChanged(mail.id, !isSelected),
        onToggleRead: () => _handleToggleRead(ref, mail), 
        onArchive: () => _handleOnArchive(context, ref, mail),      
        onToggleStar: () => _handleToggleStar(ref, mail),
      ),
    );
  }

  // ========== ACTION HANDLERS (UNCHANGED) ==========

  /// Handle mail tap - mark as read + navigation (both split and non-split modes)
  void _handleMailTap(WidgetRef ref, String mailId) {
    final currentMails = ref.read(currentMailsProvider);
    final mailIndex = currentMails.indexWhere((mail) => mail.id == mailId);
    
    if (mailIndex != -1 && !currentMails[mailIndex].isRead) {
      ref.read(mailProvider.notifier).markAsRead(mailId, userEmail);
    }

    if (!isPreviewPanelVisible && onMailSelected != null) {
      ref.read(selectedMailIdProvider.notifier).state = null;
      ref.read(mailDetailProvider.notifier).clearData();
      onMailSelected!(mailId);
      return;
    }
    
    ref.read(mailSelectionControllerProvider).select(mailId, userEmail: userEmail);
  }

  /// Toggle read/unread status
  void _handleToggleRead(WidgetRef ref, Mail mail) {
    if (mail.isRead) {
      ref.read(mailProvider.notifier).markAsUnread(mail.id, userEmail);
    } else {
      ref.read(mailProvider.notifier).markAsRead(mail.id, userEmail);
    }
  }

  /// Delete mail (move to trash)
  Future<void> _handleOnArchive(BuildContext context, WidgetRef ref, Mail mail) async {
    final mailName = mail.senderName;

    try {
      ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mail.id);
      
      if (context.mounted) {
        _showSuccessSnackBar(context, '$mailName çöp kutusuna taşındı');
      }

      await ref.read(mailProvider.notifier).moveToTrashApiOnly(mail.id, userEmail);
      
    } catch (error) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Çöp kutusuna taşıma başarısız');
      }
    }
  }

  /// Toggle star status
  void _handleToggleStar(WidgetRef ref, Mail mail) {
    if (mail.isStarred) {
      ref.read(mailProvider.notifier).unstarMail(mail.id, userEmail);
    } else {
      ref.read(mailProvider.notifier).starMail(mail.id, userEmail);
    }
  }

  // ========== SNACKBAR HELPERS (UNCHANGED) ==========

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}