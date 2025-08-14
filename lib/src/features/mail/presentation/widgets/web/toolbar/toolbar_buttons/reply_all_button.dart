// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/reply_all_button.dart

import 'package:flutter/material.dart';

/// Reply all button for replying to all recipients of a mail
/// 
/// Displays a reply all icon with consistent styling.
class ReplyAllButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const ReplyAllButton({
    super.key,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    return Tooltip(
      message: isEnabled ? 'Tümünü Yanıtla' : 'Tümünü yanıtlama özelliği yakında',
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.reply_all,
          size: 20,
          color: isEnabled 
              ? Colors.grey.shade700 
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}