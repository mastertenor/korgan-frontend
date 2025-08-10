// lib/src/features/mail/presentation/widgets/web/toolbar/components/mark_as_unread_button.dart

import 'package:flutter/material.dart';

/// Mark as unread button for marking selected mails as unread
/// 
/// Displays an unread icon with consistent styling when enabled.
class MarkAsUnreadButton extends StatelessWidget {
  final List<String> selectedMailIds;
  final bool isLoading;
  final VoidCallback? onPressed;

  const MarkAsUnreadButton({
    super.key,
    required this.selectedMailIds,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = selectedMailIds.isNotEmpty && !isLoading;

    return Tooltip(
      message: _getTooltipMessage(),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.mark_email_unread_outlined,
          size: 20,
          color: isEnabled 
              ? Colors.grey.shade700 
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  /// Get appropriate tooltip message
  String _getTooltipMessage() {
    if (isLoading) {
      return 'Maller okunmadı olarak işaretleniyor...';
    }
    
    if (selectedMailIds.isEmpty) {
      return 'Okunmadı işaretlenecek mail seçin';
    }
    
    final count = selectedMailIds.length;
    return '$count mail${count > 1 ? 'i' : ''} okunmadı olarak işaretle';
  }
}