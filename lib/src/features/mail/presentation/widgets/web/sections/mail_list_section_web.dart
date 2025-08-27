// lib/src/features/mail/presentation/widgets/web/sections/mail_list_section_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail.dart';
import '../../../providers/mail_providers.dart';
import '../../mail_item/platform/web/mail_item_web.dart';

/// Web mail listesi bölümü - Hover actions destekli
/// 
/// Özellikler:
/// - Gmail-style hover actions (sil, okundu/okunmadı işaretle, arşivle)
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
    // Provider watches
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final error = ref.watch(currentErrorProvider);

    return _buildMailList(
      currentMails: currentMails,
      isLoading: isLoading,
      error: error,
    );
  }

  /// Ana mail list container'ı
  Widget _buildMailList({
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
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
          // Mail List Content
          Expanded(
            child: _buildMailListContent(
              currentMails: currentMails,
              isLoading: isLoading,
              error: error,
            ),
          ),
        ],
      ),
    );
  }

  /// Mail list içeriği - loading, error, empty states ile
  Widget _buildMailListContent({
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
  }) {
    // Loading state
    if (isLoading && currentMails.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state  
    if (error != null && currentMails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Mailler yüklenemedi',
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

    // Empty state
    if (currentMails.isEmpty) {
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

    // Mail list - Consumer ile ref'e erişim
    return Consumer(
      builder: (context, ref, child) {
        return ListView.builder(
          itemCount: currentMails.length,
          itemBuilder: (context, index) {
            final mail = currentMails[index];
            return _buildMailListItem(context, ref, mail, index);
          },
        );
      },
    );
  }

  /// Tek mail item'ı - MailItemWeb kullanımı
/// Tek mail item'ı - MailItemWeb kullanımı
      Widget _buildMailListItem(BuildContext context, WidgetRef ref, Mail mail, int index) {
        final isSelected = selectedMails.contains(mail.id);
        // Provider'dan seçili mail ID'sini al
        final currentSelectedMailId = ref.watch(selectedMailIdProvider);
        final isCurrentlySelected = currentSelectedMailId == mail.id;
        
        // MailItemWeb ile hover actions!
        return Material(
          color: isCurrentlySelected 
              ? Colors.blue.withOpacity(0.1)
              : Colors.transparent,
          child: MailItemWeb(
            mail: mail,
            isSelected: isSelected,
            onTap: () => _handleMailTap(ref, mail.id),  // Yeni method
            onToggleSelection: () => onMailCheckboxChanged(mail.id, !isSelected),
            onToggleRead: () => _handleToggleRead(ref, mail), 
            onArchive: () => _handleOnArchive(context, ref, mail),      
            onToggleStar: () => _handleToggleStar(ref, mail),
          ),
        );
      }

/// Handle mail tap - use selection controller
// lib/src/features/mail/presentation/widgets/web/sections/mail_list_section_web.dart
// Bu kısmı güncelleyin:

/// Handle mail tap - mark as read + navigation (both split and non-split modes)
/// Handle mail tap - Basit auto mark as read
void _handleMailTap(WidgetRef ref, String mailId) {
  final currentMails = ref.read(currentMailsProvider);
  final mailIndex = currentMails.indexWhere((mail) => mail.id == mailId);
  
  // Mail bulundu ve okunmamışsa okundu yap
  if (mailIndex != -1 && !currentMails[mailIndex].isRead) {
    ref.read(mailProvider.notifier).markAsRead(mailId, userEmail);
  }

  if (!isPreviewPanelVisible && onMailSelected != null) {
    // noSplit mode: selection temizle ve detay sayfasına git
    ref.read(selectedMailIdProvider.notifier).state = null;
    ref.read(mailDetailProvider.notifier).clearData();
    onMailSelected!(mailId);
    return;
  }
  
  // split mode: okundu yap ve mail detail yükle
  ref.read(mailSelectionControllerProvider).select(mailId, userEmail: userEmail);
}
  // ========== ACTION HANDLERS ==========

  /// Toggle read/unread status
  void _handleToggleRead(WidgetRef ref, Mail mail) {
    if (mail.isRead) {
      ref.read(mailProvider.notifier).markAsUnread(mail.id, userEmail);
    } else {
      ref.read(mailProvider.notifier).markAsRead(mail.id, userEmail);
    }
  }

  /// Delete mail (move to trash) - selection_toolbar.dart pattern kullanımı
  Future<void> _handleOnArchive(BuildContext context, WidgetRef ref, Mail mail) async {
    // Get mail info for feedback
    final mailName = mail.senderName;

    try {
      // 1. Optimistic remove (same as selection_toolbar pattern)
      ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mail.id);
      
      // 2. Show success feedback immediately
      if (context.mounted) {
        _showSuccessSnackBar(context, '$mailName çöp kutusuna taşındı');
      }

      // 3. Background API call (same as selection_toolbar pattern)
      await ref.read(mailProvider.notifier).moveToTrashApiOnly(mail.id, userEmail);
      
    } catch (error) {
      // 4. Error handling
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

  // ========== SNACKBAR HELPERS ==========

  /// Show success snackbar
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

  /// Show error snackbar  
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