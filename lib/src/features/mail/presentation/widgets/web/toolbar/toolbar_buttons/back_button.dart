// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/back_button.dart

import 'package:flutter/material.dart';

/// Back button for navigation
/// 
/// Displays a back arrow icon with consistent styling.
class BackButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? tooltip;

  const BackButton({
    super.key,
    required this.isLoading,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    return Tooltip(
      message: tooltip ?? 'Geri',
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.arrow_back,
          size: 20,
          color: isEnabled 
              ? Colors.grey.shade700 
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}