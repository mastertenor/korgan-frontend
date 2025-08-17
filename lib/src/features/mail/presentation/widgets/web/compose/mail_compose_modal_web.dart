// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_compose_modal_provider.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/state/mail_compose_modal_state.dart';
import 'components/compose_header_widget.dart';
import 'components/compose_recipients_widget.dart';

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
                
                // Content editor
                Expanded(
                  child: _buildContentEditor(),
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

  /// Build content editor placeholder
  Widget _buildContentEditor() {
    return Consumer(
      builder: (context, ref, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rich Text Editor (Coming Soon)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: TextField(
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı buraya yazın...',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      ref.read(mailComposeProvider.notifier).updateTextContent(value);
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

  /// Minimized content (bottom bar)
  Widget _buildMinimizedContent(BuildContext context, WidgetRef ref) {
    return ComposeMinimizedHeaderWidget(
      title: 'Yeni İleti',
    );
  }

  /// Modal footer (send button + toolbar)
  Widget _buildModalFooter(BuildContext context, WidgetRef ref) {
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
            onPressed: () {
              // TODO: Send functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Send functionality coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Gönder'),
          ),
          
          const SizedBox(width: 16),
          
          // TODO: Format toolbar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                'Format toolbar (TO DO)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}