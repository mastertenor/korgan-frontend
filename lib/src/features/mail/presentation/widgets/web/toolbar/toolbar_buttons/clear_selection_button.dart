// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/clear_selection_button.dart

import 'package:flutter/material.dart';

/// Clear selection button (X icon)
/// 
/// Allows users to quickly clear all selections and return to normal view.
class ClearSelectionButton extends StatelessWidget {
  final int selectedCount;
  final bool isLoading;
  final VoidCallback? onPressed;

  const ClearSelectionButton({
    super.key,
    required this.selectedCount,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = selectedCount > 0 && !isLoading;

    return Tooltip(
      message: _getTooltipMessage(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled 
                  ? Colors.grey.shade100 
                  : Colors.grey.shade50,
              border: Border.all(
                color: isEnabled 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade200,
              ),
            ),
            child: Icon(
              Icons.close,
              size: 16,
              color: isEnabled 
                  ? Colors.grey.shade700 
                  : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  /// Get appropriate tooltip message
  String _getTooltipMessage() {
    if (isLoading) {
      return 'İşlem devam ediyor...';
    }
    
    if (selectedCount == 0) {
      return 'Seçim yok';
    }
    
    return 'Seçimi temizle ($selectedCount seçili)';
  }
}