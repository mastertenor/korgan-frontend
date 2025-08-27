// lib/src/features/mail/presentation/widgets/web/compose/components/compose_footer_widget.dart

import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../../../../providers/mail_compose_provider.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/froala_editor_provider.dart';
import '../../toolbar/toolbar_buttons/attachment_button.dart';

/// Compose modal footer widget with file input handling
/// 
/// Features:
/// - Send button with loading state
/// - Attachment button with file picker
/// - File input handler integration
/// - Attachment count from compose state
class ComposeFooterWidget extends ConsumerStatefulWidget {
  /// Callback when files are selected
  final Function(List<web.File>, String) onFilesReceived;
  
  /// Callback when send button is pressed
  final VoidCallback onSend;

  const ComposeFooterWidget({
    super.key,
    required this.onFilesReceived,
    required this.onSend,
  });

  @override
  ConsumerState<ComposeFooterWidget> createState() => _ComposeFooterWidgetState();
}

class _ComposeFooterWidgetState extends ConsumerState<ComposeFooterWidget> {
  // File input element
  web.HTMLInputElement? _fileInput;

  @override
  void initState() {
    super.initState();
    _initializeFileInput();
  }

  @override
  void dispose() {
    // File input cleanup
    _fileInput?.remove();
    _fileInput = null;
    super.dispose();
  }

  /// Initialize file input element
  void _initializeFileInput() {
    _fileInput = web.HTMLInputElement()
      ..type = 'file'
      ..multiple = true
      ..accept = '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.jpg,.jpeg,.png,.gif,.zip,.rar,.txt';
    
    // File selection event listener
    _fileInput!.addEventListener('change', (web.Event event) {
      final files = _fileInput!.files;
      if (files != null && files.length > 0) {
        final fileList = List.generate(files.length, (index) => files.item(index)!)
            .cast<web.File>()
            .toList();
        
        debugPrint('Selected ${fileList.length} files via file input');
        widget.onFilesReceived(fileList, 'file_picker');
      }
      
      // Clear input (to allow selecting same file again)
      _fileInput!.value = '';
    }.toJS);
  }

  /// Handle attachment button click
  void _handleAttachmentButtonClick() {
    debugPrint('Attachment button clicked');
    
    if (_fileInput != null) {
      _fileInput!.click();
    } else {
      debugPrint('File input not initialized, creating new one');
      _createAndClickFileInput();
    }
  }

  /// Fallback - create new file input and click
  void _createAndClickFileInput() {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..multiple = true
      ..accept = '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.jpg,.jpeg,.png,.gif,.zip,.rar,.txt';
    
    input.addEventListener('change', (web.Event event) {
      final files = input.files;
      if (files != null && files.length > 0) {
        final fileList = List.generate(files.length, (index) => files.item(index)!)
            .cast<web.File>()
            .toList();
        
        debugPrint('Selected ${fileList.length} files via fallback input');
        widget.onFilesReceived(fileList, 'fallback_picker');
      }
    }.toJS);
    
    input.click();
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(mailComposeProvider);
    final editorState = ref.watch(froalaEditorProvider);
    
    // Comprehensive validation - recipient, subject, editor control
    final canSend = composeState.canSend && editorState.canSend && !composeState.isSending;
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Send button with comprehensive validation
          ElevatedButton(
            onPressed: canSend ? widget.onSend : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSend ? Colors.blue : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(80, 44),
            ),
            child: composeState.isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Gönder'),
          ),
          
          const SizedBox(width: 12),
          
          // Attachment button - simplified to use compose state
          AttachmentButton(
            hasAttachments: composeState.attachments.isNotEmpty,
            attachmentCount: composeState.attachments.length,
            isLoading: false,
            onPressed: _handleAttachmentButtonClick,
          ),
          
          // Validation status indicator
          if (!canSend && !composeState.isSending) ...[
            const SizedBox(width: 12),
            Tooltip(
              message: _getValidationMessage(composeState, editorState),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.orange.shade600,
              ),
            ),
          ],
          
          const Spacer(),
        ],
      ),
    );
  }
  
  /// Get validation message for tooltip
  String _getValidationMessage(MailComposeState composeState, dynamic editorState) {
    final issues = <String>[];
    
    // Check recipients
    if (composeState.to.isEmpty) {
      issues.add('Alıcı gerekli');
    }
    
    // Check subject
    if (composeState.subject.isEmpty) {
      issues.add('Konu gerekli');
    }
    
    // Check content
    if (composeState.textContent.isEmpty && 
        (composeState.htmlContent == null || composeState.htmlContent!.isEmpty)) {
      issues.add('Mesaj içeriği gerekli');
    }
    
    return issues.isEmpty ? 'Gönderilmeye hazır' : issues.join(', ');
  }
}