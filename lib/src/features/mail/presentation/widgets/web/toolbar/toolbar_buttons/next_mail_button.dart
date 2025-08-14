// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/next_mail_button.dart

import 'package:flutter/material.dart';

/// Next mail button for navigating to the next mail in the list
/// 
/// Displays a right arrow icon with consistent styling.
class NextMailButton extends StatelessWidget {
  final bool isLoading;
  final bool hasNextMail;
  final VoidCallback? onPressed;

  const NextMailButton({
    super.key,
    required this.isLoading,
    required this.hasNextMail,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && hasNextMail && onPressed != null;

    return Tooltip(
      message: _getTooltipMessage(),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.chevron_right,
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
      return 'Yükleniyor...';
    }
    
    if (!hasNextMail) {
      return 'Sonraki mail yok';
    }
    
    return 'Sonraki mail';
  }
}