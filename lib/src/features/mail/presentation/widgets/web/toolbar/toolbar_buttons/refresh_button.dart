// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/refresh_button.dart

import 'package:flutter/material.dart';

/// Refresh button for updating current mail folder (V2)
///
/// Displays a refresh icon with loading animation when refreshing.
/// V2: Works with folder name directly from TreeNode
class RefreshButton extends StatelessWidget {
  final String userEmail;
  final String? currentFolderName; // V2: Direct folder name from TreeNode
  final bool isLoading;
  final VoidCallback? onPressed;

  const RefreshButton({
    super.key,
    required this.userEmail,
    required this.currentFolderName, // V2: Accept folder name directly
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getTooltipMessage(),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: AnimatedRotation(
          turns: isLoading ? 1 : 0,
          duration: const Duration(milliseconds: 1000),
          child: Icon(
            Icons.refresh,
            size: 20,
            color: isLoading ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// Get appropriate tooltip message
  String _getTooltipMessage() {
    if (isLoading) {
      return 'Yenileniyor...';
    }

    final folderName = currentFolderName ?? 'Gelen Kutusu';
    return '$folderName yenile';
  }
}
