// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/refresh_button.dart

import 'package:flutter/material.dart';
import '../../../../providers/mail_provider.dart';

/// Refresh button for updating current mail folder
/// 
/// Displays a refresh icon with loading animation when refreshing.
class RefreshButton extends StatelessWidget {
  final String userEmail;
  final MailFolder currentFolder;
  final bool isLoading;
  final VoidCallback? onPressed;

  const RefreshButton({
    super.key,
    required this.userEmail,
    required this.currentFolder,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getTooltipMessage(),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: AnimatedRotation(
          turns: isLoading ? 1 : 0,
          duration: const Duration(milliseconds: 1000),
          child: Icon(
            Icons.refresh,
            size: 20,
            color: isLoading 
                ? Colors.grey.shade400 
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// Get appropriate tooltip message
  String _getTooltipMessage() {
    if (isLoading) {
      return 'Yenileniyor...';
    }
    
    return '${_getFolderDisplayName(currentFolder)} klasörünü yenile';
  }

  /// Get display name for folder
  String _getFolderDisplayName(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return 'Gelen Kutusu';
      case MailFolder.sent:
        return 'Gönderilen';
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