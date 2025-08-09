// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/delete_button.dart

import 'package:flutter/material.dart';

/// Delete button for removing selected mails
/// 
/// Displays a delete icon with red styling when enabled.
class DeleteButton extends StatelessWidget {
  final String userEmail;
  final List<String> selectedMailIds;
  final bool isLoading;
  final VoidCallback? onPressed;

  const DeleteButton({
    super.key,
    required this.userEmail,
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
          Icons.delete_outline,
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
      return 'Maller siliniyor...';
    }
    
    if (selectedMailIds.isEmpty) {
      return 'Silinecek mail seçin';
    }
    
    final count = selectedMailIds.length;
    return '$count mail${count > 1 ? 'i' : ''} çöp kutusuna taşı';
  }
}