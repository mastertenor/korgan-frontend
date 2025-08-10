// lib/src/features/mail/presentation/widgets/web/toolbar/components/mark_as_read_button.dart

import 'package:flutter/material.dart';

/// Mark as read button for marking selected mails as read
/// 
/// Displays a read icon with consistent styling when enabled.
class MarkAsReadButton extends StatelessWidget {
  final List<String> selectedMailIds;
  final bool isLoading;
  final VoidCallback? onPressed;

  const MarkAsReadButton({
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
          Icons.mark_email_read_outlined,
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
      return 'Maller okundu olarak işaretleniyor...';
    }
    
    if (selectedMailIds.isEmpty) {
      return 'Okundu işaretlenecek mail seçin';
    }
    
    final count = selectedMailIds.length;
    return '$count mail${count > 1 ? 'i' : ''} okundu olarak işaretle';
  }
}