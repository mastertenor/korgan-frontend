// lib/src/features/mail/presentation/pages/mobile/mail_compose_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail_recipient.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/compose/recipients_subject_input_widget.dart';
import '../../widgets/mobile/compose/attachments_manager_widget.dart';
import '../../widgets/mobile/compose/send_button_widget.dart';

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
  late ScrollController _scrollController;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Initialize compose state based on type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeComposeState();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize compose state based on compose type
  void _initializeComposeState() {
    final composeNotifier = ref.read(mailComposeProvider.notifier);
    final sender = MailRecipient(
      email: widget.currentUserEmail,
      name: widget.currentUserName,
    );

    switch (widget.composeType) {
      case ComposeType.newMail:
        composeNotifier.initializeWithSender(sender);
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
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    final isLoading = ref.watch(composeLoadingProvider);
    
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
        // Validation summary
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showValidationInfo,
          tooltip: 'Validation Info',
        ),
        
        // Loading indicator
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
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
            controller: _scrollController,
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
      maxLines: null, // Sınırsız yükseklik
      decoration: const InputDecoration(
        hintText: 'Yanıtınızı buraya yazın...',
        border: InputBorder.none, // Tamamen sade
        isCollapsed: true, // Ekstra paddingleri de kaldırır, opsiyonel
      ),
      style: const TextStyle(), // Renk/boyut ayarı verilmedi, tamamen varsayılan
    ),
  );
}

  /// Build attachments section
  Widget _buildAttachmentsSection() {
    final hasAttachments = ref.watch(hasAttachmentsProvider);
    final attachmentCount = ref.watch(attachmentCountProvider);
    final totalSize = ref.watch(totalAttachmentSizeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Ekler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                if (hasAttachments) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$attachmentCount dosya • $totalSize',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Attachments manager widget
            const AttachmentsManagerWidget(),
          ],
        ),
      ),
    );
  }

  /// Build bottom bar with send button
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Draft button
            OutlinedButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save),
              label: const Text('Taslak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Send button
            const Expanded(child: SendButtonWidget()),
          ],
        ),
      ),
    );
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

  /// Show validation info dialog
  void _showValidationInfo() {
    final summary = ref.read(composeValidationSummaryProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Durumu'),
        content: Text(summary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
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

  /// Save as draft
  void _saveDraft() {
    ref.read(mailComposeProvider.notifier).saveDraft();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Taslak kaydedildi'),
        backgroundColor: Colors.green,
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