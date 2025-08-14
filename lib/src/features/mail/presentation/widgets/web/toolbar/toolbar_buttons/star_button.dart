// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/star_button.dart

import 'package:flutter/material.dart';

/// Star button for starring/unstarring a mail
/// 
/// Displays a star icon with different states for starred/unstarred.
class StarButton extends StatelessWidget {
  final bool isStarred;
  final bool isLoading;
  final VoidCallback? onPressed;

  const StarButton({
    super.key,
    required this.isStarred,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    return Tooltip(
      message: _getTooltipMessage(isEnabled),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          isStarred ? Icons.star : Icons.star_border,
          size: 20,
          color: isStarred 
              ? Colors.amber 
              : (isEnabled ? Colors.grey.shade700 : Colors.grey.shade400),
        ),
      ),
    );
  }

  /// Get appropriate tooltip message
  String _getTooltipMessage(bool isEnabled) {
    if (!isEnabled) {
      return 'Yıldızlama işlemi yapılamıyor';
    }
    
    return isStarred ? 'Yıldızı kaldır' : 'Yıldızla';
  }
}