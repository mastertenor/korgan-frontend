// lib/src/features/mail/presentation/pages/mobile/mail_compose_mobile.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/mail_recipient.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/compose/recipients_subject_input_widget.dart';
import '../../widgets/mobile/compose/attachments_manager_widget.dart';
import '../../../../../core/services/file_processing_service.dart';

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
  late TextEditingController _contentController;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
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
        //bottomNavigationBar: _buildBottomBar(),
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
              onPressed: () => _showAttachmentOptions(context, ref),
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

        /*      
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, ref, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'draft',
              child: Row(
                children: [
                  Icon(Icons.save, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Taslak olarak kaydet'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'discard',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('İptal et'),
                ],
              ),
            ),
          ],
        ),
        */
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

  /// Show attachment options modal
  void _showAttachmentOptions(BuildContext context, WidgetRef ref) {
    // Direct implementation with real file picking
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Options
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.blue),
              title: const Text('Galeri'),
              subtitle: const Text('Fotoğraf ve videolar'),
              onTap: () {
                Navigator.pop(modalContext);
                _pickFromGallery(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Kamera'),
              subtitle: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(modalContext);
                _pickFromCamera(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.orange),
              title: const Text('Dosyalar'),
              subtitle: const Text('Belgeler ve diğer dosyalar'),
              onTap: () {
                Navigator.pop(modalContext);
                _pickFromFiles(context, ref);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Pick from gallery - Real implementation
  Future<void> _pickFromGallery(BuildContext context, WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final List<XFile> files = await picker.pickMultipleMedia(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      
      if (files.isNotEmpty) {
        await _processSelectedFiles(context, ref, files);
      }
    } catch (e) {
      _showErrorMessage(context, 'Galeri erişimi başarısız: ${e.toString()}');
    }
  }

  /// Pick from camera - Real implementation
  Future<void> _pickFromCamera(BuildContext context, WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      
      if (file != null) {
        await _processSelectedFiles(context, ref, [file]);
      }
    } catch (e) {
      _showErrorMessage(context, 'Kamera erişimi başarısız: ${e.toString()}');
    }
  }

  /// Pick from files - Real implementation
  Future<void> _pickFromFiles(BuildContext context, WidgetRef ref) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowCompression: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        await _processFilePickerResult(context, ref, result);
      }
    } catch (e) {
      _showErrorMessage(context, 'Dosya seçimi başarısız: ${e.toString()}');
    }
  }

  /// Process selected XFiles (from ImagePicker)
  Future<void> _processSelectedFiles(BuildContext context, WidgetRef ref, List<XFile> xFiles) async {
    for (final xFile in xFiles) {
      try {
        if (context.mounted) {
          _showProcessingMessage(context, 'Dosya işleniyor: ${xFile.name}');
        }
        
        final File file = File(xFile.path);
        final attachment = await FileProcessingService.createAttachmentFromFile(file);
        
        ref.read(mailComposeProvider.notifier).addAttachment(attachment);
        
        if (context.mounted) {
          _showSuccessMessage(context, '${xFile.name} eklendi');
        }
        
      } catch (e) {
        if (context.mounted) {
          if (e is FileProcessingException) {
            _showErrorMessage(context, e.message);
          } else {
            _showErrorMessage(context, 'Dosya işleme hatası: ${e.toString()}');
          }
        }
      }
    }
  }

  /// Process FilePicker result
  Future<void> _processFilePickerResult(BuildContext context, WidgetRef ref, FilePickerResult result) async {
    for (final platformFile in result.files) {
      try {
        if (context.mounted) {
          _showProcessingMessage(context, 'Dosya işleniyor: ${platformFile.name}');
        }
        
        if (platformFile.path != null) {
          final File file = File(platformFile.path!);
          final attachment = await FileProcessingService.createAttachmentFromFile(file);
          
          ref.read(mailComposeProvider.notifier).addAttachment(attachment);
          
          if (context.mounted) {
            _showSuccessMessage(context, '${platformFile.name} eklendi');
          }
        }
        
      } catch (e) {
        if (context.mounted) {
          if (e is FileProcessingException) {
            _showErrorMessage(context, e.message);
          } else {
            _showErrorMessage(context, 'Dosya işleme hatası: ${e.toString()}');
          }
        }
      }
    }
  }

  /// Show processing message
  void _showProcessingMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
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

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'draft':
        _saveDraft();
        break;
      case 'discard':
        _showDiscardDialog();
        break;
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