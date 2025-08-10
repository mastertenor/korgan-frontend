// lib/src/features/mail/presentation/widgets/web/toolbar/mail_toolbar_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/mail_provider.dart';
import 'components/no_selection_toolbar.dart';
import 'components/selection_toolbar.dart';

/// Gmail-style web mail toolbar
/// 
/// This widget displays different toolbar content based on mail selection state:
/// - No selection: SelectAll checkbox + Refresh button
/// - Has selection: Delete button + selection info
/// 
/// The toolbar automatically adapts its content based on the current selection state.
class MailToolbarWeb extends ConsumerWidget {
  final String userEmail;
  final EdgeInsetsGeometry? padding;
  final double height;
  final Color? backgroundColor;

  const MailToolbarWeb({
    super.key,
    required this.userEmail,
    this.padding,
    this.height = 56.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selection and mail state
    final hasSelection = ref.watch(hasSelectionProvider);
    final selectedCount = ref.watch(selectedMailCountProvider);
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final currentFolder = ref.watch(currentFolderProvider);

    AppLogger.info('🔧 MailToolbarWeb: hasSelection=$hasSelection, '
                  'selectedCount=$selectedCount, mailCount=${currentMails.length}');

    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection state-based content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, -0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: hasSelection
                  ? SelectionToolbar(
                      key: const ValueKey('selection_toolbar'),
                      userEmail: userEmail,
                      selectedCount: selectedCount,
                      isLoading: isLoading,
                    )
                  : NoSelectionToolbar(
                      key: const ValueKey('no_selection_toolbar'),
                      userEmail: userEmail,
                      totalMailCount: currentMails.length,
                      currentFolder: currentFolder,
                      isLoading: isLoading,
                    ),
            ),
          ),
          
          // Always visible: Folder info (optional)
          if (currentMails.isNotEmpty) ...[
            const SizedBox(width: 16),
            //_buildFolderInfo(context, currentFolder, currentMails.length),
          ],
        ],
      ),
    );
  }

  /// Build folder information widget
  Widget _buildFolderInfo(BuildContext context, MailFolder folder, int mailCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFolderIcon(folder),
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '$mailCount ${_getFolderDisplayName(folder)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon for folder
  IconData _getFolderIcon(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return Icons.inbox;
      case MailFolder.sent:
        return Icons.send;
      case MailFolder.drafts:
        return Icons.drafts;
      case MailFolder.trash:
        return Icons.delete;
      case MailFolder.spam:
        return Icons.report;
      case MailFolder.starred:
        return Icons.star;
      case MailFolder.important:
        return Icons.label_important;
      default:
        return Icons.folder;
    }
  }

  /// Get display name for folder
  String _getFolderDisplayName(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return 'Gelen';
      case MailFolder.sent:
        return 'Gönderilen';
      case MailFolder.drafts:
        return 'Taslak';
      case MailFolder.trash:
        return 'Çöp Kutusu';
      case MailFolder.spam:
        return 'Spam';
      case MailFolder.starred:
        return 'Yıldızlı';
      case MailFolder.important:
        return 'Önemli';
      default:
        return 'Mail';
    }
  }
}