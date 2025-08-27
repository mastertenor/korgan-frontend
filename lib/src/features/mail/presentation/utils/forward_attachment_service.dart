// lib/src/features/mail/services/forward_attachment_service.dart

import 'dart:convert';
import '../../domain/entities/attachment_upload.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/mail_repository.dart';
import '../../../../utils/app_logger.dart';

/// Forward Attachment Service
///
/// Downloads attachments from original mail and converts them to AttachmentUpload
/// for forward functionality. Based on CID resolver pattern.
///
/// Features:
/// - Parallel downloading for performance
/// - Progress tracking
/// - Error handling and retry
/// - File size validation
/// - MIME type filtering
class ForwardAttachmentService {
  final MailRepository _repository;
  
  /// Max file size to download (20MB - same as CID resolver)
  static const int kMaxAttachmentBytes = 20 * 1024 * 1024; // 20MB

  ForwardAttachmentService(this._repository);

  /// Download all attachments from original mail for forward
  ///
  /// [originalMail] - Mail containing attachments to forward
  /// [userEmail] - User's email address
  /// [onProgress] - Optional progress callback (0.0 - 1.0)
  ///
  /// Returns list of AttachmentUpload with downloaded content
  Future<List<AttachmentUpload>> downloadForwardAttachments({
    required MailDetail originalMail,
    required String userEmail,
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    AppLogger.info('🔧 ForwardAttachmentService: Starting download for ${originalMail.attachments.length} attachments');

    if (!originalMail.hasAttachments || originalMail.attachments.isEmpty) {
      AppLogger.info('ℹ️ ForwardAttachmentService: No attachments to download');
      return [];
    }

    final results = <AttachmentUpload>[];
    final futures = <Future<void>>[];
    final totalAttachments = originalMail.attachments.length;
    int completedCount = 0;

    // Download all attachments in parallel (same pattern as CID resolver)
    for (int i = 0; i < originalMail.attachments.length; i++) {
      final attachment = originalMail.attachments[i];
      
      futures.add(() async {
        try {
          AppLogger.info('📥 Downloading attachment: ${attachment.filename}');
          
          // Report progress - starting download
          onProgress?.call(completedCount / totalAttachments, attachment.filename);

          final downloadResult = await _repository.downloadAttachment(
            messageId: originalMail.id,
            attachmentId: attachment.id,
            filename: attachment.filename,
            email: userEmail,
            mimeType: attachment.mimeType,
          );

          downloadResult.when(
            success: (bytes) {
              if (bytes.isEmpty) {
                AppLogger.warning('⚠️ Empty content for ${attachment.filename}');
                return;
              }
              
              if (bytes.length > kMaxAttachmentBytes) {
                AppLogger.warning('⚠️ Attachment too large (${_formatFileSize(bytes.length)}): ${attachment.filename}');
                return;
              }

              // Convert to base64 and create AttachmentUpload
              final base64Content = base64Encode(bytes);
              final attachmentUpload = AttachmentUpload.fromMailAttachment(
                attachmentId: attachment.id,
                filename: attachment.filename,
                mimeType: attachment.mimeType,
                content: base64Content,
                disposition: attachment.isInline ? 'inline' : 'attachment',
                contentId: attachment.contentId,
                isPlaceholder: false, // Real content downloaded
              );

              results.add(attachmentUpload);
              AppLogger.info('✅ Downloaded ${attachment.filename} → ${_formatFileSize(bytes.length)}');
            },
            failure: (error) {
              AppLogger.error('❌ Download failed for ${attachment.filename}: ${error.message}');
            },
          );

          // Update progress - completed
          completedCount++;
          onProgress?.call(completedCount / totalAttachments, attachment.filename);

        } catch (e) {
          AppLogger.error('❌ Exception downloading ${attachment.filename}: $e');
          completedCount++;
          onProgress?.call(completedCount / totalAttachments, attachment.filename);
        }
      }());
    }

    // Wait for all downloads to complete
    await Future.wait(futures);

    AppLogger.info('🎯 ForwardAttachmentService: Downloaded ${results.length}/${totalAttachments} attachments successfully');
    
    return results;
  }

  /// Download single attachment (for retry scenarios)
  Future<AttachmentUpload?> downloadSingleAttachment({
    required MailDetail originalMail,
    required MailAttachment attachment,
    required String userEmail,
  }) async {
    try {
      AppLogger.info('📥 Downloading single attachment: ${attachment.filename}');

      final downloadResult = await _repository.downloadAttachment(
        messageId: originalMail.id,
        attachmentId: attachment.id,
        filename: attachment.filename,
        email: userEmail,
        mimeType: attachment.mimeType,
      );

      return downloadResult.when(
        success: (bytes) {
          if (bytes.isEmpty) {
            AppLogger.warning('⚠️ Empty content for ${attachment.filename}');
            return null;
          }
          
          if (bytes.length > kMaxAttachmentBytes) {
            AppLogger.warning('⚠️ Attachment too large: ${attachment.filename}');
            return null;
          }

          final base64Content = base64Encode(bytes);
          final attachmentUpload = AttachmentUpload.fromMailAttachment(
            attachmentId: attachment.id,
            filename: attachment.filename,
            mimeType: attachment.mimeType,
            content: base64Content,
            disposition: attachment.isInline ? 'inline' : 'attachment',
            contentId: attachment.contentId,
            isPlaceholder: false,
          );

          AppLogger.info('✅ Single download successful: ${attachment.filename}');
          return attachmentUpload;
        },
        failure: (error) {
          AppLogger.error('❌ Single download failed: ${error.message}');
          return null;
        },
      );
    } catch (e) {
      AppLogger.error('❌ Exception in single download: $e');
      return null;
    }
  }

  /// Validate if mail has downloadable attachments
  bool canDownloadAttachments(MailDetail originalMail) {
    if (!originalMail.hasAttachments || originalMail.attachments.isEmpty) {
      return false;
    }

    // Check if any attachment is downloadable
    return originalMail.attachments.any((att) => 
      att.filename.isNotEmpty && 
      att.id.isNotEmpty &&
      att.mimeType.isNotEmpty
    );
  }

  /// Get estimated download size
  int getEstimatedDownloadSize(MailDetail originalMail) {
    if (!originalMail.hasAttachments) return 0;
    
    return originalMail.attachments
        .map((att) => att.size)
        .fold(0, (a, b) => a + b);
  }

  /// Get formatted download size
  String getFormattedDownloadSize(MailDetail originalMail) {
    final size = getEstimatedDownloadSize(originalMail);
    return _formatFileSize(size);
  }

  /// Check if download size is acceptable
  bool isDownloadSizeAcceptable(MailDetail originalMail) {
    final totalSize = getEstimatedDownloadSize(originalMail);
    return totalSize <= kMaxAttachmentBytes;
  }

  /// Get download summary for UI
  ForwardAttachmentSummary getDownloadSummary(MailDetail originalMail) {
    if (!originalMail.hasAttachments) {
      return ForwardAttachmentSummary(
        totalAttachments: 0,
        totalSize: 0,
        formattedSize: '0B',
        canDownload: false,
        exceedsLimit: false,
        attachmentNames: [],
      );
    }

    final totalSize = getEstimatedDownloadSize(originalMail);
    final exceedsLimit = totalSize > kMaxAttachmentBytes;
    
    return ForwardAttachmentSummary(
      totalAttachments: originalMail.attachments.length,
      totalSize: totalSize,
      formattedSize: _formatFileSize(totalSize),
      canDownload: canDownloadAttachments(originalMail) && !exceedsLimit,
      exceedsLimit: exceedsLimit,
      attachmentNames: originalMail.attachments.map((att) => att.filename).toList(),
    );
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Forward attachment download summary
class ForwardAttachmentSummary {
  final int totalAttachments;
  final int totalSize;
  final String formattedSize;
  final bool canDownload;
  final bool exceedsLimit;
  final List<String> attachmentNames;

  const ForwardAttachmentSummary({
    required this.totalAttachments,
    required this.totalSize,
    required this.formattedSize,
    required this.canDownload,
    required this.exceedsLimit,
    required this.attachmentNames,
  });

  bool get hasAttachments => totalAttachments > 0;

  String get summaryText {
    if (totalAttachments == 0) return 'No attachments';
    if (totalAttachments == 1) return '1 attachment ($formattedSize)';
    return '$totalAttachments attachments ($formattedSize)';
  }

  String get statusText {
    if (!hasAttachments) return 'No attachments to forward';
    if (exceedsLimit) return 'Attachments too large to download';
    if (canDownload) return 'Ready to download';
    return 'Cannot download attachments';
  }
}