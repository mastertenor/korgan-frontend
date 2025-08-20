// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_web.dart

import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/froala_editor_provider.dart';
import '../../../providers/state/mail_compose_modal_state.dart';
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
/// - **NEW: Unified drag&drop ve paste file handling**
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
  // 🎯 NEW: Attachment management
  final List<FileAttachment> _attachments = [];

  @override
  Widget build(BuildContext context) {
    final modalState = ref.watch(mailComposeModalProvider);
    
    // Modal kapalıysa hiçbir şey gösterme
    if (!modalState.isVisible) {
      return const SizedBox.shrink();
    }

    // 🎯 NEW: Wrap everything with UnifiedDropZoneWrapper
    return UnifiedDropZoneWrapper(
      onFilesReceived: _handleUnifiedFileReceive,
      debugMode: true, // 🔧 DEBUG: Enable for testing
      child: Stack(
        children: [
          // Background overlay (sadece normal ve maximized modda)
          if (!modalState.isMinimized) _buildBackgroundOverlay(context),
          
          // Modal content
          _buildModalContent(context, modalState),
        ],
      ),
    );
  }

  // 🎯 NEW: Unified file handling method
  void _handleUnifiedFileReceive(List<web.File> files, String source) {
    AppLogger.info('📁 Received ${files.length} files via $source');
    
    for (final file in files) {
      if (_isImageFile(file)) {
        _handleImageFile(file, source);
      } else {
        _handleAttachmentFile(file, source);
      }
    }
  }

  // 🎯 NEW: Check if file is an image
  bool _isImageFile(web.File file) {
    final imageTypes = [
      'image/png', 'image/jpg', 'image/jpeg', 
      'image/gif', 'image/webp', 'image/svg+xml'
    ];
    return imageTypes.contains(file.type.toLowerCase());
  }

  // 🎯 NEW: Handle image files (send to Froala editor)
  void _handleImageFile(web.File file, String source) {
    AppLogger.info('🖼️ Handling image: ${file.name} (${file.type}) via $source');
    
    // Convert file to base64 and send to Froala editor
    final reader = web.FileReader();
    
    // Modern package:web event handling
    reader.addEventListener('load', (web.Event event) {
      final base64 = reader.result as String;
      
      // Notify Froala editor to insert image
      ref.read(froalaEditorProvider.notifier).insertImage(
        base64: base64,
        name: file.name,
        size: file.size,
      );
      
      // Show success notification
      _showSuccessNotification('Resim eklendi: ${file.name} ($source)');
    }.toJS);
    
    reader.addEventListener('error', (web.Event event) {
      AppLogger.error('❌ Failed to read image file: ${file.name}');
      _showErrorNotification('Resim yüklenemedi: ${file.name}');
    }.toJS);
    
    reader.readAsDataURL(file);
  }

  // 🎯 NEW: Handle attachment files (add to attachment list)
  void _handleAttachmentFile(web.File file, String source) {
    AppLogger.info('📎 Handling attachment: ${file.name} (${file.type}) via $source');
    
    // Convert file to base64 for storage
    final reader = web.FileReader();
    
    // Modern package:web event handling
    reader.addEventListener('load', (web.Event event) {
      final base64 = reader.result as String;
      
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
      
      // Show success notification
      _showSuccessNotification('Ek dosya eklendi: ${file.name} ($source)');
      
      AppLogger.info('✅ Attachment added: ${file.name} (${_formatFileSize(file.size)})');
    }.toJS);
    
    reader.addEventListener('error', (web.Event event) {
      AppLogger.error('❌ Failed to read attachment file: ${file.name}');
      _showErrorNotification('Dosya yüklenemedi: ${file.name}');
    }.toJS);
    
    reader.readAsDataURL(file);
  }

  // 🎯 NEW: Remove attachment
  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments.removeWhere((attachment) => attachment.id == attachmentId);
    });
    AppLogger.info('🗑️ Attachment removed: $attachmentId');
  }

  // 🎯 NEW: Show success notification
  void _showSuccessNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🎯 NEW: Show error notification
  void _showErrorNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Background overlay (modal dışı tıklamada kapatma)
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

  /// Modal content container
  Widget _buildModalContent(
    BuildContext context, 
    MailComposeModalState modalState,
  ) {
    if (modalState.isMinimized) {
      return _buildMinimizedModal(context);
    } else if (modalState.isMaximized) {
      return _buildMaximizedModal(context);
    } else {
      return _buildNormalModal(context);
    }
  }

  /// Normal boyut modal (600x500px, center)
  Widget _buildNormalModal(BuildContext context) {
    return Center(
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
        child: _buildModalBody(context, isMaximized: false),
      ),
    );
  }

  /// Maximized modal (tam ekran)
  Widget _buildMaximizedModal(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = screenSize.width * 0.9;
    final modalHeight = screenSize.height * 0.9;

    return Center(
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
        child: _buildModalBody(context, isMaximized: true),
      ),
    );
  }

  /// Minimized modal (bottom bar)
  Widget _buildMinimizedModal(BuildContext context) {
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
        child: _buildMinimizedContent(context),
      ),
    );
  }

  /// Modal body içeriği
  Widget _buildModalBody(BuildContext context, {required bool isMaximized}) {
    return Column(
      children: [
        // Header (title + control buttons)
        ComposeHeaderWidget(
          title: 'Yeni İleti',
          isMaximized: isMaximized,
        ),
        
        // Content area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Recipients section
                ComposeRecipientsWidget(
                  fromEmail: widget.userEmail,
                  fromName: widget.userName,
                ),
                
                const SizedBox(height: 16),
                
                // Subject field
                _buildSubjectField(),
                
                const SizedBox(height: 16),
                
                // Content editor - Froala rich text editor
                Expanded(
                  child: _buildRichTextEditor(context),
                ),
                
                // 🎯 NEW: Attachment area (show only if there are attachments)
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAttachmentArea(),
                ],
              ],
            ),
          ),
        ),
        
        // Footer (send button + toolbar)
        _buildModalFooter(context),
      ],
    );
  }

  // 🎯 NEW: Build attachment area
  Widget _buildAttachmentArea() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
          
          // Attachment chips
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

  // 🎯 NEW: Build attachment chip
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

  /// Build Froala rich text editor (replaces the old content editor)
  Widget _buildRichTextEditor(BuildContext context) {
    final composeState = ref.watch(mailComposeProvider);
    
    return ComposeRichEditorWidget(
      initialContent: composeState.htmlContent,
      height: double.infinity,
      onContentChanged: (html, text) {
        // Update compose provider with new content
        ref.read(mailComposeProvider.notifier).updateHtmlContent(
          html.isEmpty ? null : html,
        );
        ref.read(mailComposeProvider.notifier).updateTextContent(text);
        
        // Update Froala editor state
        ref.read(froalaEditorProvider.notifier).updateContent(
          htmlContent: html,
          textContent: text,
          isEmpty: html.trim().isEmpty || html == '<p><br></p>',
          wordCount: text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length,
        );
      },
      onSendShortcut: () => _handleSend(context),
      onImagePasted: (base64, name, size) {
        // Handle pasted images
        ref.read(froalaEditorProvider.notifier).onImagePasted(
          base64: base64,
          name: name,
          size: size,
        );
        
        // Show notification
        _showSuccessNotification('Görsel yapıştırıldı: $name (${_formatFileSize(size)})');
      },
    );
  }

  /// Minimized content (bottom bar)
  Widget _buildMinimizedContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title
          const Text(
            'Yeni İleti',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          
          // 🎯 NEW: Show attachment count if any
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

  /// Modal footer (send button + toolbar)
  Widget _buildModalFooter(BuildContext context) {
    final composeState = ref.watch(mailComposeProvider);
    final editorState = ref.watch(froalaEditorProvider);
    
    return Container(
      height: 60,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Send button
          ElevatedButton(
            onPressed: (editorState.canSend && !composeState.isSending) 
                ? () => _handleSend(context)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          
          const SizedBox(width: 16),
          
          // Content stats
          Expanded(
            child: Text(
              _getContentStats(editorState),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          
          // Error indicator
          if (editorState.error != null)
            Tooltip(
              message: editorState.error!,
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// Handle send action
  void _handleSend(BuildContext context) async {
    final editorNotifier = ref.read(froalaEditorProvider.notifier);
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    
    // Validate content
    if (!editorNotifier.validateForSend()) {
      return;
    }
    
    try {
      // TODO: Implement actual send functionality with backend
      // Include attachments in the send process
      AppLogger.info('📤 Sending mail with ${_attachments.length} attachments');
      
      await Future.delayed(const Duration(seconds: 1));
      
      _showSuccessNotification('Mail gönderildi!');
      
      // Close modal and reset state
      ref.read(mailComposeModalProvider.notifier).closeModal();
      composeNotifier.clearAll();
      editorNotifier.reset();
      
      // Clear attachments
      setState(() {
        _attachments.clear();
      });
      
    } catch (e) {
      _showErrorNotification('Gönderme hatası: $e');
    }
  }

  /// Get content statistics text
  String _getContentStats(FroalaEditorState editorState) {
    if (editorState.isEmpty && _attachments.isEmpty) {
      return 'Boş mesaj';
    }
    
    final stats = <String>[];
    
    if (editorState.wordCount > 0) {
      stats.add('${editorState.wordCount} kelime');
    }
    
    if (editorState.pastedImages.isNotEmpty) {
      stats.add('${editorState.pastedImages.length} görsel');
    }
    
    if (_attachments.isNotEmpty) {
      stats.add('${_attachments.length} ek');
    }
    
    return stats.isEmpty ? 'Sadece format' : stats.join(', ');
  }

  /// Get total attachment size
  String _getTotalAttachmentSize() {
    final totalSize = _attachments.fold<int>(0, (sum, attachment) => sum + attachment.size);
    return _formatFileSize(totalSize);
  }

  /// Get file icon based on MIME type
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

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// 🎯 NEW: FileAttachment data class
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