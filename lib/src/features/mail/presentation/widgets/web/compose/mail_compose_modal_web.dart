// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/froala_editor_provider.dart';
import '../../../providers/state/mail_compose_modal_state.dart';
import 'components/compose_header_widget.dart';
import 'components/compose_recipients_widget.dart';
import 'components/compose_rich_editor_widget.dart';


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
class MailComposeModalWeb extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final modalState = ref.watch(mailComposeModalProvider);
    
    // Modal kapalıysa hiçbir şey gösterme
    if (!modalState.isVisible) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Background overlay (sadece normal ve maximized modda)
        if (!modalState.isMinimized) _buildBackgroundOverlay(context, ref),
        
        // Modal content
        _buildModalContent(context, ref, modalState),
      ],
    );
  }

  /// Background overlay (modal dışı tıklamada kapatma)
  Widget _buildBackgroundOverlay(BuildContext context, WidgetRef ref) {
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
    WidgetRef ref, 
    MailComposeModalState modalState,
  ) {
    if (modalState.isMinimized) {
      return _buildMinimizedModal(context, ref);
    } else if (modalState.isMaximized) {
      return _buildMaximizedModal(context, ref);
    } else {
      return _buildNormalModal(context, ref);
    }
  }

  /// Normal boyut modal (600x500px, center)
  Widget _buildNormalModal(BuildContext context, WidgetRef ref) {
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
        child: _buildModalBody(context, ref, isMaximized: false),
      ),
    );
  }

  /// Maximized modal (tam ekran)
  Widget _buildMaximizedModal(BuildContext context, WidgetRef ref) {
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
        child: _buildModalBody(context, ref, isMaximized: true),
      ),
    );
  }

  /// Minimized modal (bottom bar)
  Widget _buildMinimizedModal(BuildContext context, WidgetRef ref) {
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
        child: _buildMinimizedContent(context, ref),
      ),
    );
  }

  /// Modal body içeriği
  Widget _buildModalBody(BuildContext context, WidgetRef ref, {required bool isMaximized}) {
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
                  fromEmail: userEmail,
                  fromName: userName,
                ),
                
                const SizedBox(height: 16),
                
                // Subject field
                _buildSubjectField(),
                
                const SizedBox(height: 16),
                
                // Content editor - Froala rich text editor
                Expanded(
                  child: _buildRichTextEditor(context, ref),
                ),
              ],
            ),
          ),
        ),
        
        // Footer (send button + toolbar)
        _buildModalFooter(context, ref),
      ],
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
  Widget _buildRichTextEditor(BuildContext context, WidgetRef ref) {
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
      onSendShortcut: () => _handleSend(context, ref),
      onImagePasted: (base64, name, size) {
        // Handle pasted images
        ref.read(froalaEditorProvider.notifier).onImagePasted(
          base64: base64,
          name: name,
          size: size,
        );
        
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel yapıştırıldı: $name (${_formatFileSize(size)})'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  /// Minimized content (bottom bar)
  Widget _buildMinimizedContent(BuildContext context, WidgetRef ref) {
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
  Widget _buildModalFooter(BuildContext context, WidgetRef ref) {
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
                ? () => _handleSend(context, ref)
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
          
          // Content stats (replacing the old "Format toolbar (TO DO)" text)
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
  void _handleSend(BuildContext context, WidgetRef ref) async {
    final editorNotifier = ref.read(froalaEditorProvider.notifier);
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    
    // Validate content
    if (!editorNotifier.validateForSend()) {
      return;
    }
    
    try {
      // TODO: Implement actual send functionality with backend
      // For now, just show loading and success
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mail gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Close modal and reset state
      ref.read(mailComposeModalProvider.notifier).closeModal();
      composeNotifier.clearAll();
      editorNotifier.reset();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gönderme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get content statistics text
  String _getContentStats(FroalaEditorState editorState) {
    if (editorState.isEmpty) {
      return 'Boş mesaj';
    }
    
    final stats = <String>[];
    
    if (editorState.wordCount > 0) {
      stats.add('${editorState.wordCount} kelime');
    }
    
    if (editorState.pastedImages.isNotEmpty) {
      stats.add('${editorState.pastedImages.length} görsel');
    }
    
    return stats.isEmpty ? 'Sadece format' : stats.join(', ');
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}