// lib/src/features/mail/presentation/widgets/mobile/compose/attachments_manager_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/attachment_upload.dart';
import '../../../providers/mail_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/services/file_processing_service.dart';
import '../../../../../../core/services/file_type_detector.dart';

/// Horizontal attachments manager widget for compose form
///
/// Similar design to AttachmentsWidgetMobile but for compose functionality
/// Features:
/// - Horizontal scrollable cards
/// - File type icons with colors  
/// - Remove functionality
/// - Real-time size calculation
/// - Professional Gmail-style design
class AttachmentsManagerWidget extends ConsumerWidget {
  const AttachmentsManagerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composeState = ref.watch(mailComposeProvider);
    
    // Don't show anything if no attachments
    if (composeState.attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal attachment cards
        _buildHorizontalAttachmentsList(context, ref, composeState.attachments),
        
        const SizedBox(height: 12),
        
        // Size summary (compact version)
        _buildCompactSizeInfo(context, composeState.attachments),
      ],
    );
  }

  /// Build horizontal attachments list (Gmail-style)
  Widget _buildHorizontalAttachmentsList(
    BuildContext context, 
    WidgetRef ref, 
    List<AttachmentUpload> attachments,
  ) {
    return SizedBox(
      height: 100, // Fixed height for horizontal scroll
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: attachments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildAttachmentCard(context, ref, attachments[index], index);
        },
      ),
    );
  }

  /// Build individual attachment card (similar to AttachmentsWidgetMobile)
  Widget _buildAttachmentCard(
    BuildContext context,
    WidgetRef ref,
    AttachmentUpload attachment,
    int index,
  ) {
    final theme = Theme.of(context);
    final fileType = FileTypeDetector.autoDetect(
      mimeType: attachment.type,
      filename: attachment.filename,
    );
    final fileTypeColor = FileTypeDetector.getColor(fileType);
    
    return Container(
      width: 160, // Fixed card width matching AttachmentsWidgetMobile
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _previewAttachment(context, attachment),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and remove button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // File type icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: fileTypeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        FileTypeDetector.getIcon(fileType),
                        color: fileTypeColor,
                        size: 18,
                      ),
                    ),
                    
                    // Remove button
                    InkWell(
                      onTap: () => _removeAttachment(ref, index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // File name (truncated)
                Expanded(
                  child: Text(
                    attachment.filename,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // File type and size
                Row(
                  children: [
                    // File type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: fileTypeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        FileTypeDetector.getTypeName(fileType).toUpperCase(),
                        style: TextStyle(
                          color: fileTypeColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // File size
                    Text(
                      attachment.sizeFormatted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact size info (replaces the large warning section)
  Widget _buildCompactSizeInfo(BuildContext context, List<AttachmentUpload> attachments) {
    final totalSizeBytes = attachments.fold<int>(
      0, 
      (sum, attachment) => sum + attachment.estimatedSizeBytes,
    );
    
    final totalSizeMB = totalSizeBytes / (1024 * 1024);
    final maxSizeMB = 25;
    final isOverLimit = totalSizeMB > maxSizeMB;
    final isNearLimit = totalSizeMB > maxSizeMB * 0.8;
    
    if (!isNearLimit && !isOverLimit) {
      return const SizedBox.shrink(); // Don't show if everything is fine
    }
    
       
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOverLimit ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverLimit ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverLimit ? Icons.error : Icons.warning,
            color: isOverLimit ? Colors.red.shade700 : Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOverLimit
                  ? 'Limit aşıldı: ${totalSizeMB.toStringAsFixed(1)}MB / ${maxSizeMB}MB'
                  : '${totalSizeMB.toStringAsFixed(1)}MB / ${maxSizeMB}MB',
              style: TextStyle(
                color: isOverLimit ? Colors.red.shade700 : Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${attachments.length} dosya',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ========== FILE SELECTION METHODS ==========

  /// Show attachment options modal
  void showAttachmentOptions(BuildContext context, WidgetRef ref) {
    // Ensure context is mounted before showing modal
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                Navigator.pop(context);
                _pickFromGallery(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Kamera'),
              subtitle: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.orange),
              title: const Text('Dosyalar'),
              subtitle: const Text('Belgeler ve diğer dosyalar'),
              onTap: () {
                Navigator.pop(context);
                _pickFromFiles(ref);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Pick from gallery - REAL IMPLEMENTATION
  Future<void> _pickFromGallery(WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final List<XFile> files = await picker.pickMultipleMedia(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      
      if (files.isNotEmpty) {
        await _processSelectedFiles(files, ref);
      }
    } catch (e) {
      _showErrorMessage(ref, 'Galeri erişimi başarısız: ${e.toString()}');
    }
  }

  /// Pick from camera - REAL IMPLEMENTATION
  Future<void> _pickFromCamera(WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      
      if (file != null) {
        await _processSelectedFiles([file], ref);
      }
    } catch (e) {
      _showErrorMessage(ref, 'Kamera erişimi başarısız: ${e.toString()}');
    }
  }

  /// Pick from files - REAL IMPLEMENTATION
  Future<void> _pickFromFiles(WidgetRef ref) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowCompression: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        await _processFilePickerResult(result, ref);
      }
    } catch (e) {
      _showErrorMessage(ref, 'Dosya seçimi başarısız: ${e.toString()}');
    }
  }

  /// Process selected XFiles (from ImagePicker)
  Future<void> _processSelectedFiles(List<XFile> xFiles, WidgetRef ref) async {
    for (final xFile in xFiles) {
      try {
        // Safe context check before showing processing message
        if (ref.context.mounted) {
          _showProcessingMessage(ref, 'Dosya işleniyor: ${xFile.name}');
        }
        
        final File file = File(xFile.path);
        final attachment = await FileProcessingService.createAttachmentFromFile(file);
        
        ref.read(mailComposeProvider.notifier).addAttachment(attachment);
        
        // Safe context check before showing success message
        if (ref.context.mounted) {
          _showSuccessMessage(ref, '${xFile.name} eklendi');
        }
        
      } catch (e) {
        // Safe context check before showing error message
        if (ref.context.mounted) {
          if (e is FileProcessingException) {
            _showErrorMessage(ref, e.message);
          } else {
            _showErrorMessage(ref, 'Dosya işleme hatası: ${e.toString()}');
          }
        }
      }
    }
  }

  /// Process FilePicker result
  Future<void> _processFilePickerResult(FilePickerResult result, WidgetRef ref) async {
    for (final platformFile in result.files) {
      try {
        // Safe context check before showing processing message
        if (ref.context.mounted) {
          _showProcessingMessage(ref, 'Dosya işleniyor: ${platformFile.name}');
        }
        
        if (platformFile.path != null) {
          final File file = File(platformFile.path!);
          final attachment = await FileProcessingService.createAttachmentFromFile(file);
          
          ref.read(mailComposeProvider.notifier).addAttachment(attachment);
          
          // Safe context check before showing success message
          if (ref.context.mounted) {
            _showSuccessMessage(ref, '${platformFile.name} eklendi');
          }
        }
        
      } catch (e) {
        // Safe context check before showing error message
        if (ref.context.mounted) {
          if (e is FileProcessingException) {
            _showErrorMessage(ref, e.message);
          } else {
            _showErrorMessage(ref, 'Dosya işleme hatası: ${e.toString()}');
          }
        }
      }
    }
  }

  // ========== UTILITY METHODS ==========

  /// Remove attachment
  void _removeAttachment(WidgetRef ref, int index) {
    ref.read(mailComposeProvider.notifier).removeAttachment(index);
    
    // Safe context check before showing message
    if (ref.context.mounted) {
      _showSuccessMessage(ref, 'Dosya kaldırıldı');
    }
  }

  /// Preview attachment (placeholder - can be implemented later)
  void _previewAttachment(BuildContext context, AttachmentUpload attachment) {
    // Safe context check
    if (!context.mounted) return;
    
    // TODO: Implement attachment preview for compose
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Önizleme: ${attachment.filename}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ========== MESSAGE METHODS ==========

  /// Show processing message
  void _showProcessingMessage(WidgetRef ref, String message) {
    // Safe context check
    if (!ref.context.mounted) return;
    
    final context = ref.context;
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
  void _showSuccessMessage(WidgetRef ref, String message) {
    // Safe context check
    if (!ref.context.mounted) return;
    
    final context = ref.context;
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
  void _showErrorMessage(WidgetRef ref, String message) {
    // Safe context check
    if (!ref.context.mounted) return;
    
    final context = ref.context;
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
}