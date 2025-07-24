// lib/src/features/mail/presentation/widgets/mobile/compose/attachments_manager_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/attachment_upload.dart';
import '../../../providers/mail_compose_provider.dart';
import '../../../providers/mail_providers.dart';

/// Attachments manager widget for compose form
class AttachmentsManagerWidget extends ConsumerWidget {
  const AttachmentsManagerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composeState = ref.watch(mailComposeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add attachment button
        _buildAddButton(context, ref),
        
        const SizedBox(height: 12),
        
        // Existing attachments
        if (composeState.attachments.isNotEmpty) ...[
          _buildAttachmentsList(context, ref, composeState.attachments),
        ] else ...[
          _buildEmptyState(),
        ],
        
        // Size warning
        _buildSizeWarning(context, composeState),
      ],
    );
  }

  /// Build add attachment button
  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showAttachmentOptions(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('Dosya Ekle'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  /// Build attachments list
  Widget _buildAttachmentsList(BuildContext context, WidgetRef ref, List<AttachmentUpload> attachments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        return _buildAttachmentTile(context, ref, attachment, index);
      },
    );
  }

  /// Build individual attachment tile
  Widget _buildAttachmentTile(BuildContext context, WidgetRef ref, AttachmentUpload attachment, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileIcon(attachment.type),
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.sizeFormatted,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: () => ref.read(mailComposeProvider.notifier).removeAttachment(index),
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Henüz dosya eklenmedi',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Build size warning
  Widget _buildSizeWarning(BuildContext context, MailComposeState state) {
    if (!state.hasAttachments) return const SizedBox.shrink();
    
    final totalSizeMB = state.totalAttachmentSize / (1024 * 1024);
    const maxSizeMB = 25;
    final isOverLimit = totalSizeMB > maxSizeMB;
    
    if (!isOverLimit && totalSizeMB < 20) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOverLimit ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOverLimit ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverLimit ? Icons.error : Icons.warning,
            color: isOverLimit ? Colors.red.shade700 : Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isOverLimit
                  ? 'Toplam dosya boyutu ${maxSizeMB}MB limitini aşıyor!'
                  : 'Dosya boyutu ${maxSizeMB}MB limitine yaklaşıyor',
              style: TextStyle(
                color: isOverLimit ? Colors.red.shade700 : Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show attachment options
  void _showAttachmentOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Dosyalar'),
              onTap: () {
                Navigator.pop(context);
                _pickFromFiles(ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Pick from gallery (placeholder)
  void _pickFromGallery(WidgetRef ref) {
    // TODO: Implement gallery picker
    _showComingSoonMessage(ref);
  }

  /// Pick from camera (placeholder)
  void _pickFromCamera(WidgetRef ref) {
    // TODO: Implement camera picker
    _showComingSoonMessage(ref);
  }

  /// Pick from files (placeholder)
  void _pickFromFiles(WidgetRef ref) {
    // TODO: Implement file picker
    _showComingSoonMessage(ref);
  }

  /// Show coming soon message
  void _showComingSoonMessage(WidgetRef ref) {
    // For demo, add a dummy attachment
    final dummyAttachment = AttachmentUpload(
      content: 'base64-encoded-content',
      type: 'application/pdf',
      filename: 'example-document.pdf',
    );
    
    ref.read(mailComposeProvider.notifier).addAttachment(dummyAttachment);
  }

  /// Get file icon based on MIME type
  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('doc')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('zip') || mimeType.contains('rar')) return Icons.folder_zip;
    return Icons.attach_file;
  }
}