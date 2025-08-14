// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/reply_button.dart

import 'package:flutter/material.dart';

/// Reply button for replying to a mail
/// 
/// Displays a reply icon with consistent styling.
class ReplyButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const ReplyButton({
    super.key,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    return Tooltip(
      message: isEnabled ? 'Yanıtla' : 'Yanıtlama özelliği yakında',
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.reply,
          size: 20,
          color: isEnabled 
              ? Colors.grey.shade700 
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}