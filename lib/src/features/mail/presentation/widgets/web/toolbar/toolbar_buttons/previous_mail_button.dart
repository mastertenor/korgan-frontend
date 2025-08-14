// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/previous_mail_button.dart

import 'package:flutter/material.dart';

/// Previous mail button for navigating to the previous mail in the list
/// 
/// Displays a left arrow icon with consistent styling.
class PreviousMailButton extends StatelessWidget {
  final bool isLoading;
  final bool hasPreviousMail;
  final VoidCallback? onPressed;

  const PreviousMailButton({
    super.key,
    required this.isLoading,
    required this.hasPreviousMail,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && hasPreviousMail && onPressed != null;

    return Tooltip(
      message: _getTooltipMessage(),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.chevron_left,
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
    
    if (!hasPreviousMail) {
      return 'Önceki mail yok';
    }
    
    return 'Önceki mail';
  }
}