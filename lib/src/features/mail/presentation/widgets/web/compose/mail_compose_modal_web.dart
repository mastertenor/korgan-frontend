// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_web.dart

import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../../../../domain/entities/attachment_upload.dart';
import '../../../../domain/enums/reply_type.dart'; // NEW IMPORT
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/froala_editor_provider.dart';
import '../../../providers/mail_reply_provider.dart';
import '../../../providers/state/mail_compose_modal_state.dart';
import 'components/compose_footer_widget.dart';
import 'components/compose_header_widget.dart';
import 'components/compose_recipients_widget.dart';
import 'components/compose_rich_editor_widget.dart';
import 'unified_drop_zone_wrapper.dart';
import '../../../../../../utils/app_logger.dart';

/// Gmail benzeri compose modal widget
/// 
/// Üç farklı görünüm modu:
/// - Normal: 600x500px center positioned modal
/// - Minimized: Bottom bar (full width x 50px)
/// - Maximized: Full screen modal
/// 
/// Features:
/// - Fixed positioning (no dragging)
/// - Smooth animations
/// - Shadow effects
/// - Responsive behavior
/// - Froala Rich Text Editor integration
/// - Unified drag&drop ve paste file handling
/// - Reply mode support (NEW)
class MailComposeModalWeb extends ConsumerStatefulWidget {
  /// Current user email
  final String userEmail;
  
  /// Current user name
  final String userName;

  const MailComposeModalWeb({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  ConsumerState<MailComposeModalWeb> createState() => _MailComposeModalWebState();
}

class _MailComposeModalWebState extends ConsumerState<MailComposeModalWeb> {
  final GlobalKey<ComposeRichEditorWidgetState> _editorKey = GlobalKey();

  // Attachment management
  final List<FileAttachment> _attachments = [];
  final Set<web.FileReader> _activeReaders = {};

  @override
  void dispose() {
    // Tüm aktif reader'ları iptal et
    for (final reader in _activeReaders) {
      try {
        reader.abort();
      } catch (e) {
        // Silent ignore
      }
    }
    _activeReaders.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modalState = ref.watch(mailComposeModalProvider);
    final MailReplyState replyState = ref.watch(mailReplyProvider); // FIXED: Type annotation
    
    // Modal kapalıysa hiçbir şey gösterme
    if (!modalState.isVisible) {
      return const SizedBox.shrink();
    }

    // NEW: Reply mode detection
    final isReplyMode = replyState.originalMail != null;
    
    // NEW: Simple approach - transfer reply data to compose if in reply mode
    if (isReplyMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transferReplyDataToCompose(replyState);
      });
    }

    AppLogger.info('Modal build - Reply mode: $isReplyMode');

    return Stack(
      children: [
        // Background overlay (sadece normal ve maximized modda)
        if (!modalState.isMinimized) _buildBackgroundOverlay(context),
        
        // Modal content with reply mode support
        _buildModalContentWithDropZone(context, modalState, isReplyMode),
      ],
    );
  }

  /// NEW: Transfer reply data to compose state (simple approach)
  void _transferReplyDataToCompose(MailReplyState replyState) {
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    final composeState = ref.read(mailComposeProvider);
    
    // Avoid duplicate transfers
    if (composeState.from != null && composeState.subject.isNotEmpty) {
      return; // Already transferred
    }
    
    // Initialize compose with reply data
    composeNotifier.clearAll();
    
    if (replyState.from != null) {
      composeNotifier.initializeWithSender(replyState.from!);
    }
    
    // Add recipients
    for (final recipient in replyState.to) {
      composeNotifier.addToRecipient(recipient);
    }
    
    for (final recipient in replyState.cc) {
      composeNotifier.addCcRecipient(recipient);
    }
    
    for (final recipient in replyState.bcc) {
      composeNotifier.addBccRecipient(recipient);
    }
    
    // Set subject
    composeNotifier.updateSubject(replyState.subject);
    
    // Set content (if any)
    if (replyState.textContent.isNotEmpty) {
      composeNotifier.updateTextContent(replyState.textContent);
    }
    
    AppLogger.info('Reply data transferred to compose state');
  }

  // Modal content with reply mode parameter
  Widget _buildModalContentWithDropZone(
    BuildContext context, 
    MailComposeModalState modalState,
    bool isReplyMode, // NEW PARAMETER
  ) {
    if (modalState.isMinimized) {
      return _buildMinimizedModal(context, isReplyMode);
    } else if (modalState.isMaximized) {
      return _buildMaximizedModalWithDropZone(context, isReplyMode);
    } else {
      return _buildNormalModalWithDropZone(context, isReplyMode);
    }
  }

  // Normal modal with reply mode support
  Widget _buildNormalModalWithDropZone(BuildContext context, bool isReplyMode) {
    return Center(
      child: UnifiedDropZoneWrapper(
        onFilesReceived: _handleUnifiedFileReceive,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 600,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildModalBody(context, isMaximized: false, isReplyMode: isReplyMode),
        ),
      ),
    );
  }

  // Maximized modal with reply mode support
  Widget _buildMaximizedModalWithDropZone(BuildContext context, bool isReplyMode) {
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = screenSize.width * 0.9;
    final modalHeight = screenSize.height * 0.9;

    return Center(
      child: UnifiedDropZoneWrapper(
        onFilesReceived: _handleUnifiedFileReceive,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: modalWidth,
          height: modalHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildModalBody(context, isMaximized: true, isReplyMode: isReplyMode),
        ),
      ),
    );
  }

  /// Modal body content with reply mode support
  Widget _buildModalBody(BuildContext context, {required bool isMaximized, required bool isReplyMode}) {
    return Column(
      children: [
        // Header with dynamic title based on mode
        ComposeHeaderWidget(
          title: _getModalTitle(isReplyMode),
          isMaximized: isMaximized,
          onClearAndClose: _clearAndClose,
        ),
        
        // Content area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Reply type toggle (only if reply mode and can switch)
                if (isReplyMode) _buildReplyTypeToggleIfNeeded(),
                
                // Recipients section (same widget, but pre-filled in reply mode)
                ComposeRecipientsWidget(
                  fromEmail: widget.userEmail,
                  fromName: widget.userName,
                ),
                
                const SizedBox(height: 16),
                
                // Subject field (same widget, but pre-filled in reply mode)
                _buildSubjectField(),
                
                const SizedBox(height: 16),
                
                // Content editor - Froala rich text editor
                Expanded(
                  child: _buildRichTextEditor(context),
                ),
                
                // Attachment area (show only if there are attachments)
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAttachmentArea(),
                ],
              ],
            ),
          ),
        ),
        
        // Footer widget
        ComposeFooterWidget(
          attachments: _attachments,
          onFilesReceived: _handleUnifiedFileReceive,
          onSend: () => _handleSend(context),
        ),
      ],
    );
  }

  /// NEW: Get dynamic modal title based on mode
  String _getModalTitle(bool isReplyMode) {
    if (!isReplyMode) {
      return 'Yeni İleti';
    }
    
    final MailReplyState replyState = ref.read(mailReplyProvider);
    final originalSubject = replyState.originalMail?.subject ?? '';
    
    switch (replyState.replyType) {
      case ReplyType.reply:
        return 'Yanıtla: $originalSubject';
      case ReplyType.replyAll:
        return 'Tümüne Yanıtla: $originalSubject';
      case ReplyType.forward:
        return 'İlet: $originalSubject';
    }
  }

  /// NEW: Reply type toggle - only show if needed
  Widget _buildReplyTypeToggleIfNeeded() {
    final MailReplyState replyState = ref.watch(mailReplyProvider);
    
    if (!replyState.canSwitchToReplyAll) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            'Yanıt Türü:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          ToggleButtons(
            isSelected: [
              replyState.replyType == ReplyType.reply,
              replyState.replyType == ReplyType.replyAll,
            ],
            onPressed: (index) {
              final newType = index == 0 ? ReplyType.reply : ReplyType.replyAll;
              ref.read(mailReplyProvider.notifier).switchReplyType(newType);
              
              // Re-transfer new reply data to compose
              final newReplyState = ref.read(mailReplyProvider);
              _transferReplyDataToCompose(newReplyState);
            },
            borderRadius: BorderRadius.circular(4),
            constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
            textStyle: const TextStyle(fontSize: 12),
            children: const [
              Text('Yanıtla'),
              Text('Tümüne Yanıtla'),
            ],
          ),
        ],
      ),
    );
  }

  /// Minimized modal with reply mode support
  Widget _buildMinimizedModal(BuildContext context, bool isReplyMode) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _buildMinimizedContent(context, isReplyMode),
      ),
    );
  }

  /// Minimized content with reply mode support
  Widget _buildMinimizedContent(BuildContext context, bool isReplyMode) {
    String title = _getModalTitle(isReplyMode);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          
          // Show attachment count if any
          if (_attachments.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_attachments.length} ek',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          const Spacer(),
          
          // Restore button
          IconButton(
            onPressed: () => ref.read(mailComposeModalProvider.notifier).restoreModal(),
            icon: const Icon(Icons.open_in_full, size: 18),
            tooltip: 'Geri yükle',
          ),
          
          // Close button
          IconButton(
            onPressed: () => ref.read(mailComposeModalProvider.notifier).closeModal(),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Kapat',
          ),
        ],
      ),
    );
  }

  // EXISTING METHODS (unchanged but organized)

  /// Build subject field
  Widget _buildSubjectField() {
    return Consumer(
      builder: (context, ref, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Konu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Konu',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ref.read(mailComposeProvider.notifier).updateSubject(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichTextEditor(BuildContext context) {
    return ComposeRichEditorWidget(
      key: _editorKey,
      height: double.infinity,
      onIframeFilesDropped: _handleIframeFilesDropped,
      // FIXED: Removed isReplyMode parameter that doesn't exist
    );
  }

  /// Handle send action with simplified approach
  void _handleSend(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    final composeState = ref.read(mailComposeProvider);
    
    try {
      AppLogger.info('Starting mail send process...');
      
      // Basic validation
      if (!composeState.canSend) {
        AppLogger.info('Send validation failed');
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Mail gönderilemedi: Eksik bilgiler var'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Add local attachments to compose state before sending
      _addAttachmentsToComposeState();
      
      // Send mail using compose provider (simplified approach)
      final result = await composeNotifier.sendMail();
      
      if (!mounted) return;
      
      if (result) {
        AppLogger.info('Mail sent successfully!');
        _handleSuccess(scaffoldMessenger);
      } else {
        AppLogger.info('Mail send failed');
        _handleFailure(scaffoldMessenger);
      }
      
    } catch (e) {
      AppLogger.error('Send error: $e');
      if (!mounted) return;
      _handleException(scaffoldMessenger, e);
    }
  }

  // Unified file handling method
  void _handleUnifiedFileReceive(List<web.File> files, String source) {
    AppLogger.info('Received ${files.length} files via $source');
    
    final forceAttachment = source == 'paste' || source == 'iframe_paste' || source == 'drop';

    for (final file in files) {
      final isImage = _isImageFile(file);

      if (!forceAttachment && isImage) {
        _handleImageFile(file, source);
      } else {
        _handleAttachmentFile(file, source);
      }
    }
  }

  bool _isImageFile(web.File file) {
    final imageTypes = [
      'image/png', 'image/jpg', 'image/jpeg', 
      'image/gif', 'image/webp', 'image/svg+xml'
    ];
    return imageTypes.contains(file.type.toLowerCase());
  }

  void _handleImageFile(web.File file, String source) {
    AppLogger.info('Starting image processing: ${file.name}');
    
    if (!mounted) return;
    
    final reader = web.FileReader();
    _activeReaders.add(reader);
    
    reader.addEventListener('load', (web.Event event) {
      _activeReaders.remove(reader);
      if (!mounted) return;
      
      try {
        final result = reader.result;
        if (result == null) return;
        
        final base64 = (result as JSString).toDart;
        
        final editor = _editorKey.currentState;
        editor?.sendExternalImageMessage(
          base64: base64,
          name: file.name,
          size: file.size,
          source: source,
        );
        
        AppLogger.info('Image message sent via widget state');
        
      } catch (e) {
        AppLogger.error('Error: $e');
      }
    }.toJS);
    
    reader.readAsDataURL(file);
  }

  void _handleAttachmentFile(web.File file, String source) {
    if (!mounted) return;
    
    final reader = web.FileReader();
    _activeReaders.add(reader);
    
    reader.addEventListener('load', (web.Event event) {
      _activeReaders.remove(reader);
      
      if (!mounted) return;
      
      try {
        final result = reader.result;
        if (result == null) {
          AppLogger.error('FileReader result is null for: ${file.name}');
          return;
        }
        
        final base64 = (result as JSString).toDart;
        
        final attachment = FileAttachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.name,
          size: file.size,
          type: file.type,
          base64Data: base64,
          source: source,
          addedAt: DateTime.now(),
        );
        
        setState(() {
          _attachments.add(attachment);
        });
        
        AppLogger.info('Attachment added: ${file.name} (${_formatFileSize(file.size)})');
        
      } catch (e) {
        AppLogger.error('Error handling attachment: $e');
      }
    }.toJS);
    
    reader.addEventListener('error', (web.Event event) {
      _activeReaders.remove(reader);
      if (!mounted) return;
      AppLogger.error('Failed to read attachment file: ${file.name}');
    }.toJS);
    
    reader.readAsDataURL(file);
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments.removeWhere((attachment) => attachment.id == attachmentId);
    });
    AppLogger.info('Attachment removed: $attachmentId');
  }

  Widget _buildBackgroundOverlay(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => ref.read(mailComposeModalProvider.notifier).closeModal(),
        child: Container(
          color: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildAttachmentArea() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Ekler (${_attachments.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  _getTotalAttachmentSize(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.map((attachment) => 
                _buildAttachmentChip(attachment)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(FileAttachment attachment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.type),
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatFileSize(attachment.size),
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeAttachment(attachment.id),
            child: Icon(
              Icons.close,
              size: 14,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleIframeFilesDropped(List<Map<String, dynamic>> files) {
    AppLogger.info('Received ${files.length} files from iframe');
    
    for (final fileData in files) {
      final name = fileData['name'] as String;
      final type = fileData['type'] as String;
      final size = fileData['size'] as int;
      final base64 = fileData['base64'] as String;
      
      AppLogger.info('Processing iframe file: $name ($type, $size bytes)');
      
      final attachment = FileAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        size: size,
        type: type,
        base64Data: base64,
        source: 'iframe_paste',
        addedAt: DateTime.now(),
      );
      
      setState(() {
        _attachments.add(attachment);
      });
      
      AppLogger.info('Iframe attachment added: $name (${_formatFileSize(size)})');
    }
  }

  void _addAttachmentsToComposeState() {
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    
    for (final attachment in _attachments) {
      String cleanBase64 = attachment.base64Data;
      if (cleanBase64.startsWith('data:')) {
        final commaIndex = cleanBase64.indexOf(',');
        if (commaIndex != -1) {
          cleanBase64 = cleanBase64.substring(commaIndex + 1);
        }
      }
      
      final attachmentUpload = AttachmentUpload(
        content: cleanBase64,
        type: attachment.type,
        filename: attachment.name,
        disposition: 'attachment',
      );
      
      composeNotifier.addAttachment(attachmentUpload);
    }
  }

  void _handleSuccess(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Mail başarıyla gönderildi!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    _clearAndClose();
  }

  void _handleFailure(ScaffoldMessengerState scaffoldMessenger) {
    final composeState = ref.read(mailComposeProvider);
    final error = composeState.error ?? 'Bilinmeyen hata oluştu';
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Mail gönderilemedi: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleException(ScaffoldMessengerState scaffoldMessenger, dynamic error) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Hata oluştu: ${error.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _clearAndClose() {
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    final replyNotifier = ref.read(mailReplyProvider.notifier); // NEW: Clear reply state too
    final editorNotifier = ref.read(froalaEditorProvider.notifier);
    
    // Clear states
    composeNotifier.clearAll();
    replyNotifier.clearAll(); // NEW: Clear reply state
    editorNotifier.reset();
    
    // Clear local attachments
    setState(() {
      _attachments.clear();
    });
    
    // Close modal
    ref.read(mailComposeModalProvider.notifier).closeModal();
  }
 
  String _getTotalAttachmentSize() {
    final totalSize = _attachments.fold<int>(0, (sum, attachment) => sum + attachment.size);
    return _formatFileSize(totalSize);
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.contains('text')) return Icons.text_snippet;
    if (mimeType.contains('audio')) return Icons.audio_file;
    if (mimeType.contains('video')) return Icons.video_file;
    return Icons.attach_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// FileAttachment data class
class FileAttachment {
  final String id;
  final String name;
  final int size;
  final String type;
  final String base64Data;
  final String source; // 'drop' or 'paste'
  final DateTime addedAt;

  const FileAttachment({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.base64Data,
    required this.source,
    required this.addedAt,
  });
}