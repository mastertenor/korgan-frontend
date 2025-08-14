// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/forward_button.dart

import 'package:flutter/material.dart';

/// Forward button for forwarding a mail
/// 
/// Displays a forward icon with consistent styling.
class ForwardButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const ForwardButton({
    super.key,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    return Tooltip(
      message: isEnabled ? 'Yönlendir' : 'Yönlendirme özelliği yakında',
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.forward,
          size: 20,
          color: isEnabled 
              ? Colors.grey.shade700 
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}