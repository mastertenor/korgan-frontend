// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_web.dart

import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../../../../domain/entities/attachment_upload.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../../domain/enums/reply_type.dart';
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
  final MailReplyState replyState = ref.watch(mailReplyProvider);
  
  // DEBUG: Reply state kontrolü
  print('=== MODAL BUILD DEBUG ===');
  print('Modal visible: ${modalState.isVisible}');
  print('Reply mode: ${replyState.originalMail != null}');
  print('Original mail: ${replyState.originalMail}');
  print('Reply type: ${replyState.replyType}');
  print('==========================');
  
  // Modal kapalıysa hiçbir şey gösterme
  if (!modalState.isVisible) {
    return const SizedBox.shrink();
  }

  // NEW: Reply mode detection
  final isReplyMode = replyState.originalMail != null;
  
  // NEW: Editor ready listener - send quote when editor becomes ready
  ref.listen<FroalaEditorState>(froalaEditorProvider, (previous, next) {
    if (previous?.isReady != true && next.isReady && isReplyMode) {
      AppLogger.info('Editor became ready, sending quote content');
      _sendQuoteContentToEditor(replyState.originalMail!, replyState.replyType);
    }
  });
  
  // UPDATED: Simple approach - transfer reply data to compose if in reply mode (NO QUOTE)
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
    print('=== TRANSFER DEBUG ===');
    print('Transfer method called');
    print('Original mail: ${replyState.originalMail?.subject}');
    
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    final composeState = ref.read(mailComposeProvider);
    
    print('Compose from: ${composeState.from}');
    print('Compose subject: ${composeState.subject}');
    print('Should skip: ${composeState.from != null && composeState.subject.isNotEmpty}');

    // Avoid duplicate transfers
    if (composeState.from != null && composeState.subject.isNotEmpty) {
      print('Transfer skipped - already transferred');
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
    
    // REMOVED: Quote content sending moved to editor ready listener
    
    AppLogger.info('Reply data transferred to compose state');
  }
  /// NEW: Send quote content to Froala editor
  void _sendQuoteContentToEditor(MailDetail originalMail, ReplyType replyType) {
    final editor = _editorKey.currentState;
    if (editor == null) {
      AppLogger.warning('Editor not ready for quote content');
      return;
    }
    
    // Import the utility here to avoid circular dependencies
    final quoteHtml = _buildQuoteHtml(originalMail, replyType);
    
    // Send quote content to editor
    editor.setContentWithQuote(quoteHtml);
    
    AppLogger.info('Quote content sent to editor: ${quoteHtml.length} characters');
  }

  /// Build quote HTML based on reply type
/// Build quote HTML based on reply type
  String _buildQuoteHtml(MailDetail originalMail, ReplyType replyType) {
    // Provider'dan rendered HTML alma
    final mailDetailState = ref.read(mailDetailProvider);
    
    String content;
    if (mailDetailState.mailDetail?.id == originalMail.id && 
        mailDetailState.renderedHtml != null && 
        mailDetailState.renderedHtml!.isNotEmpty) {
      // Rendered HTML kullan
      content = mailDetailState.renderedHtml!;
      print('✅ Using rendered HTML for quote');
    } else {
      // Fallback: ham HTML kullan
      content = originalMail.safeHtmlContent;
      print('⚠️ Using fallback HTML for quote');
    }
    
    final from = originalMail.formattedSender;
    final date = _formatQuoteDate(originalMail.receivedDate ?? DateTime.parse(originalMail.time));
    final subject = originalMail.subject;
    
    String header;
    if (replyType == ReplyType.replyAll) {
      final to = originalMail.recipients.join(', ');
      final cc = originalMail.ccRecipients.join(', ');
      
      header = '''
  On $date, $from wrote:<br>
  <strong>Subject:</strong> $subject<br>
  <strong>To:</strong> $to''';
      
      if (cc.isNotEmpty) {
        header += '<br><strong>CC:</strong> $cc';
      }
    } else {
      header = '''
  On $date, $from wrote:<br>
  <strong>Subject:</strong> $subject
  ''';
    }
    
    return '''
  <p><br></p>
  <p><br></p>
  <div style="margin-top: 20px;">
    <div class="gmail_quote">
      <div style="margin-bottom: 10px; color: #666; font-size: 13px;">
        $header
      </div>
      <blockquote style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex;color:#666;">
        $content
      </blockquote>
    </div>
  </div>''';
  }

  /// Format date for quote header
  String _formatQuoteDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year at $hour:$minute';
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
    final modalWidth = screenSize.width * 0.75;
    final modalHeight = screenSize.height * 0.75;

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
                                
                // Recipients section (same widget, but pre-filled in reply mode)
                ComposeRecipientsWidget(
                  fromEmail: widget.userEmail,
                  fromName: widget.userName,
                ),
                
                //const SizedBox(height: 16),
                
                // Subject field (same widget, but pre-filled in reply mode)
                //_buildSubjectField(),
                
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
        return 'Tümünü Yanıtla: $originalSubject';
      case ReplyType.forward:
        return 'İlet: $originalSubject';
    }
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