// lib/src/features/mail/presentation/widgets/mobile/mail_attachment_list_tile_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../domain/entities/attachment.dart';
import '../../../../../../../core/services/file_cache_service.dart';
import '../../../../../../../core/services/file_type_detector.dart';
import '../../../../../../../utils/app_logger.dart';
import '../../../../pages/mobile/attachment_preview_page_mobile.dart';

/// Enhanced attachment list tile widget for displaying email attachments
///
/// 🆕 Updated to work with new cache system and CachedFile
/// 🚀 Phase 2: Real preview navigation with Hero animations
class AttachmentListTile extends StatefulWidget {
  final MailAttachment attachment;
  final String messageId;
  final String email;
  final Future<CachedFile> Function() onDownload;

  const AttachmentListTile({
    super.key,
    required this.attachment,
    required this.messageId,
    required this.email,
    required this.onDownload,
  });

  @override
  State<AttachmentListTile> createState() => _AttachmentListTileState();
}

class _AttachmentListTileState extends State<AttachmentListTile> {
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  CachedFile? _cachedFile;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: ListTile(
        leading: _buildFileIcon(),
        title: Text(
          widget.attachment.filename,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailingWidget(),
        onTap: _isDownloading ? null : _handleTap,
      ),
    );
  }

  /// Build file type icon with Hero animation support
  Widget _buildFileIcon() {
    // Use enhanced file type detection
    final fileType = FileTypeDetector.autoDetect(
      mimeType: widget.attachment.mimeType,
      filename: widget.attachment.filename,
    );

    return Hero(
      tag: 'attachment_${widget.attachment.id}', // Unique hero tag
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: FileTypeDetector.getColor(fileType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          FileTypeDetector.getIcon(fileType),
          color: FileTypeDetector.getColor(fileType),
          size: 24,
        ),
      ),
    );
  }

  /// Build subtitle with enhanced file type info
  Widget _buildSubtitle() {
    final theme = Theme.of(context);

    // Enhanced file type detection
    final fileType = FileTypeDetector.autoDetect(
      mimeType: widget.attachment.mimeType,
      filename: widget.attachment.filename,
    );

    final canPreview = FileTypeDetector.canPreview(fileType);

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
      );
    }

    if (_downloadCompleted && _cachedFile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info
          Text(
            '${FileTypeDetector.getTypeName(fileType)} • ${_formatFileSize(widget.attachment.size)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),

          // Preview availability indicator
          if (canPreview) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.visibility, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Önizleme mevcut',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Text(
      '${FileTypeDetector.getTypeName(fileType)} • ${_formatFileSize(widget.attachment.size)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  /// Build trailing widget (download button or progress)
  Widget _buildTrailingWidget() {
    if (_isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_downloadCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 24);
    }

    return Icon(
      Icons.download,
      color: Theme.of(context).colorScheme.primary,
      size: 24,
    );
  }

  /// Handle tap - download or preview
  Future<void> _handleTap() async {
    if (_downloadCompleted && _cachedFile != null) {
      // File is already downloaded, navigate to preview
      _navigateToPreview();
      return;
    }

    // Start download
    await _handleDownload();
  }

  /// Handle download process
  Future<void> _handleDownload() async {
    if (_isDownloading || _downloadCompleted) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      AppLogger.info('📎 Starting download for: ${widget.attachment.filename}');

      // Call the download function
      final cachedFile = await widget.onDownload();

      AppLogger.info('📎 Download completed: ${widget.attachment.filename}');

      setState(() {
        _downloadCompleted = true;
        _cachedFile = cachedFile;
      });

      // Enhanced success feedback with preview info
      if (mounted) {
        final fileType = FileTypeDetector.autoDetect(
          mimeType: widget.attachment.mimeType,
          filename: widget.attachment.filename,
        );
        final canPreview = FileTypeDetector.canPreview(fileType);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.attachment.filename} indirildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: canPreview
                ? SnackBarAction(
                    label: 'Görüntüle',
                    textColor: Colors.white,
                    onPressed: _navigateToPreview,
                  )
                : null,
            duration: Duration(seconds: canPreview ? 4 : 2),
          ),
        );
      }

      // Auto-navigate to preview for previewable files
      final fileType = FileTypeDetector.autoDetect(
        mimeType: widget.attachment.mimeType,
        filename: widget.attachment.filename,
      );

      if (FileTypeDetector.canPreview(fileType)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToPreview();
          }
        });
      }
    } catch (e) {
      AppLogger.error('❌ Download failed: $e');

      setState(() {
        _errorMessage = 'İndirme başarısız';
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme başarısız: ${widget.attachment.filename}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Navigate to preview page (Phase 2 implementation)
  void _navigateToPreview() {
    if (_cachedFile == null) {
      AppLogger.warning('Cannot navigate to preview: cachedFile is null');
      return;
    }

    AppLogger.info(
      '🚀 Navigating to preview for ${widget.attachment.filename}',
    );

    // Add haptic feedback for navigation
    HapticFeedback.selectionClick();

    // Navigate to AttachmentPreviewPage with custom transition
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AttachmentPreviewPage(
              cachedFile: _cachedFile!,
              attachment: widget.attachment,
              heroTag: 'attachment_${widget.attachment.id}',
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Custom fade + scale transition for smooth UX
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeOutCubic;

          final fadeAnimation = Tween<double>(
            begin: begin,
            end: end,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final scaleAnimation = Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Format file size for display
  String _formatFileSize(int size) {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
