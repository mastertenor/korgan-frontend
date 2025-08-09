// lib/src/features/mail/presentation/widgets/web/toolbar/components/mail_selection_info_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/mail_provider.dart';

/// Gmail-style selection info bar
/// 
/// Shows selection information when mails are selected:
/// "Gelen klasöründeki 5 ileti seçildi"
/// "Gönderilmiş klasöründeki 10 ileti seçildi"
/// 
/// Appears below toolbar, disappears when no selection.
class MailSelectionInfoBar extends ConsumerWidget {
  const MailSelectionInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selection and folder state
    final selectedCount = ref.watch(selectedMailCountProvider);
    final hasSelection = ref.watch(hasSelectionProvider);
    final currentFolder = ref.watch(currentFolderProvider);
    final totalMailCount = ref.watch(currentMailsProvider).length;
    final isAllSelected = ref.watch(isAllSelectedProvider);

    // Don't show if no selection
    if (!hasSelection || selectedCount == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: hasSelection ? 48.0 : 0.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.blue.shade200, width: 1),
          ),
        ),
        child: Center( // Ortalanmış
          child: Text(
            _getSelectionText(currentFolder, selectedCount, totalMailCount, isAllSelected),
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Generate selection text based on folder and selection state
  String _getSelectionText(MailFolder folder, int selectedCount, int totalCount, bool isAllSelected) {
    final folderName = _getFolderDisplayName(folder);
    
    if (isAllSelected && selectedCount == totalCount) {
      // All mails selected on current page
      return '$folderName klasöründeki bu sayfada bulunan $selectedCount ileti seçildi';
    } else {
      // Partial selection
      return '$folderName klasöründeki $selectedCount ileti seçildi';
    }
  }

  /// Get display name for folder
  String _getFolderDisplayName(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return 'Gelen';
      case MailFolder.sent:
        return 'Gönderilmiş';
      case MailFolder.drafts:
        return 'Taslaklar';
      case MailFolder.trash:
        return 'Çöp Kutusu';
      case MailFolder.spam:
        return 'Spam';
      case MailFolder.starred:
        return 'Yıldızlı';
      case MailFolder.important:
        return 'Önemli';
      default:
        return 'Klasör';
    }
  }
}