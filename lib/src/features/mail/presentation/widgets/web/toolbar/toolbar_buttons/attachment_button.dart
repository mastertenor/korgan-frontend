// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/attachment_button.dart

import 'package:flutter/material.dart';

/// Attachment button for adding file attachments to mail
/// 
/// Displays an attachment icon with different states for active/inactive.
/// Shows attachment count badge when there are attachments.
class AttachmentButton extends StatelessWidget {
  final bool hasAttachments;
  final int attachmentCount;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AttachmentButton({
    super.key,
    required this.hasAttachments,
    this.attachmentCount = 0,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main attachment button
        Tooltip(
          message: _getTooltipMessage(isEnabled),
          child: IconButton(
            onPressed: isEnabled ? onPressed : null,
            icon: Icon(
              hasAttachments ? Icons.attach_file : Icons.attach_file_outlined,
              size: 20,
              color: hasAttachments 
                  ? Colors.blue 
                  : (isEnabled ? Colors.grey.shade700 : Colors.grey.shade400),
            ),
          ),
        ),
        
        // Attachment count badge (show only if there are attachments)
        if (hasAttachments && attachmentCount > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                attachmentCount > 99 ? '99+' : '$attachmentCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Get appropriate tooltip message
  String _getTooltipMessage(bool isEnabled) {
    if (!isEnabled) {
      return 'Dosya ekleme yapılamıyor';
    }
    
    if (hasAttachments) {
      return 'Dosya ekle ($attachmentCount ek mevcut)';
    }
    
    return 'Dosya ekle';
  }
}