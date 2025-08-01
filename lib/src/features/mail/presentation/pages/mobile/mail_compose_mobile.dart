// lib/src/features/mail/presentation/pages/mobile/mail_compose_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail_recipient.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/compose/recipients_subject_input_widget.dart';
import '../../widgets/mobile/compose/attachments_manager_widget.dart';

/// Mail compose page for mobile devices
///
/// Features:
/// - Recipients management (TO, CC, BCC)
/// - Subject and content editing
/// - Attachment management
/// - Real-time validation
/// - Send functionality with loading states
class MailComposeMobile extends ConsumerStatefulWidget {
  /// Current user email (sender)
  final String currentUserEmail;

  /// Current user display name
  final String currentUserName;

  /// Initialize for reply (optional)
  final MailRecipient? replyTo;

  /// Original subject for reply/forward (optional)
  final String? originalSubject;

  /// Original content for forward (optional)
  final String? originalContent;

  /// Compose type (new, reply, forward)
  final ComposeType composeType;

  const MailComposeMobile({
    super.key,
    required this.currentUserEmail,
    required this.currentUserName,
    this.replyTo,
    this.originalSubject,
    this.originalContent,
    this.composeType = ComposeType.newMail,
  });

  @override
  ConsumerState<MailComposeMobile> createState() => _MailComposeMobileState();
}

class _MailComposeMobileState extends ConsumerState<MailComposeMobile> {
  late TextEditingController _contentController;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    
    // Initialize compose state based on type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeComposeState();
      
      // Set initial content to controller
      final initialContent = ref.read(mailComposeProvider).textContent;
      _contentController.text = initialContent;
      
      // Add listener to update state when text changes
      _contentController.addListener(() {
        ref.read(mailComposeProvider.notifier).updateTextContent(_contentController.text);
      });
    });
  }

  @override
  void dispose() {
    
    _contentController.dispose();
    super.dispose();
  }

  /// Initialize compose state based on compose type
  void _initializeComposeState() {
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    // State'i temizle
    composeNotifier.clearAll();
    final sender = MailRecipient(
      email: widget.currentUserEmail,
      name: widget.currentUserName,
    );

  // 🔍 DEBUG: Değerleri kontrol edin
  print('🐛 MailComposeMobile - currentUserEmail: ${widget.currentUserEmail}');
  print('🐛 MailComposeMobile - sender: ${sender.email}');

    switch (widget.composeType) {
      case ComposeType.newMail:
        composeNotifier.initializeWithSender(sender);
              final state = ref.read(mailComposeProvider);
      print('🐛 After initializeWithSender - from: ${state.from?.email}');
        break;
      case ComposeType.reply:
        if (widget.replyTo != null && widget.originalSubject != null) {
          composeNotifier.initializeForReply(
            from: sender,
            replyTo: widget.replyTo!,
            originalSubject: widget.originalSubject!,
          );
        }
        break;
      case ComposeType.forward:
        if (widget.originalSubject != null && widget.originalContent != null) {
          composeNotifier.initializeForForward(
            from: sender,
            originalSubject: widget.originalSubject!,
            originalContent: widget.originalContent!,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedChanges) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// Build app bar with attachment button
  PreferredSizeWidget _buildAppBar() {
    final isLoading = ref.watch(composeLoadingProvider);
    final composeState = ref.watch(mailComposeProvider);
    final hasAttachments = composeState.attachments.isNotEmpty;
    
    return AppBar(
      title: Text(_getAppBarTitle()),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _handleClose,
      ),
      actions: [
        // Attachment button with badge
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: Icon(
                hasAttachments ? Icons.attach_file : Icons.attach_file_outlined,
                color: hasAttachments ? Colors.amber : Colors.white,
              ),
              // ✅ YENİ: Widget'tan attachment options çağır
              onPressed: () => const AttachmentsManagerWidget().showAttachmentOptions(context, ref),
              tooltip: 'Dosya Ekle',
            ),
            
            // Attachment count badge
            if (hasAttachments)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${composeState.attachments.length}',
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
        ),
        
        // Send button
        IconButton(
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
          onPressed: composeState.canSend && !isLoading
              ? () => _handleSend(context, ref)
              : null,
          tooltip: 'Gönder',
        ),
      ],
    );
  }

  /// Build main body
  Widget _buildBody() {
    return Column(
      children: [
        // Error banner
        _buildErrorBanner(),
        
        // Scrollable form content
        Expanded(
          child: SingleChildScrollView(            
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipients section
                _buildRecipientsAndSubjectSection(),
                               
                const SizedBox(height: 16),
                
                // Content section
                _buildContentSection(),
                
                const SizedBox(height: 16),
                
                // Attachments section
                _buildAttachmentsSection(),
                
                // Bottom padding for floating action button
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build error banner
  Widget _buildErrorBanner() {
    final error = ref.watch(composeErrorProvider);
    
    if (error == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Clear error
              ref.read(mailComposeProvider.notifier).updateSubject(
                ref.read(mailComposeProvider).subject,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build recipients section
  Widget _buildRecipientsAndSubjectSection() {
    return const RecipientsInputWidget();
  }

  /// Build content section
  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        maxLines: null, // Sınırsız yükseklik
        decoration: const InputDecoration(
          hintText: 'Mesajınızı buraya yazınız...',
          border: InputBorder.none, // Tamamen sade
          isCollapsed: true, // Ekstra paddingleri de kaldırır, opsiyonel
        ),
        style: const TextStyle(), // Renk/boyut ayarı verilmedi, tamamen varsayılan
      ),
    );
  }

  /// Build attachments section
  Widget _buildAttachmentsSection() {
    return const AttachmentsManagerWidget();
  }

  // ========== EVENT HANDLERS ==========

  /// Get app bar title based on compose type
  String _getAppBarTitle() {
    switch (widget.composeType) {
      case ComposeType.newMail:
        return 'Yeni Mail';
      case ComposeType.reply:
        return 'Yanıtla';
      case ComposeType.forward:
        return 'İlet';
    }
  }

  /// Handle close button
  void _handleClose() {
    if (_hasUnsavedChanges) {
      _showDiscardDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Handle send action
  Future<void> _handleSend(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(mailComposeProvider.notifier).sendMail();
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📧 Mesaj gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Show discard changes dialog
  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değişiklikleri At'),
        content: const Text(
          'Kaydedilmemiş değişiklikler var. Bu sayfadan çıkmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close compose page
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('At'),
          ),
        ],
      ),
    );
  }
}

/// Compose type enumeration
enum ComposeType {
  newMail,
  reply,
  forward,
}