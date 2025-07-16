// lib/src/features/mail/presentation/widgets/mobile/mail_attachment_list_tile_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../domain/entities/attachment.dart';
import '../../../../../../../core/services/file_cache_service.dart';
import '../../../../../../../utils/app_logger.dart';

/// Enhanced attachment list tile widget for displaying email attachments
///
/// 🆕 Updated to work with new cache system and CachedFile
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

  /// Build file type icon
  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    // Determine icon based on MIME type
    if (widget.attachment.mimeType.startsWith('image/')) {
      iconData = Icons.image;
      iconColor = Colors.green;
    } else if (widget.attachment.mimeType.contains('pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (widget.attachment.mimeType.contains('word') ||
        widget.attachment.mimeType.contains('document')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (widget.attachment.mimeType.contains('spreadsheet') ||
        widget.attachment.mimeType.contains('excel')) {
      iconData = Icons.table_chart;
      iconColor = Colors.green.shade700;
    } else if (widget.attachment.mimeType.contains('zip') ||
        widget.attachment.mimeType.contains('rar')) {
      iconData = Icons.folder_zip;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.attach_file;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  /// Build subtitle with file info
  Widget _buildSubtitle() {
    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
      );
    }

    if (_downloadCompleted && _cachedFile != null) {
      return Text(
        '✅ İndirildi • ${_formatFileSize(widget.attachment.size)}',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
      );
    }

    return Text(
      _formatFileSize(widget.attachment.size),
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
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
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

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.attachment.filename} indirildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Görüntüle',
              textColor: Colors.white,
              onPressed: _navigateToPreview,
            ),
          ),
        );
      }

      // Auto-navigate to preview after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToPreview();
        }
      });
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

  /// Navigate to preview page (placeholder for Phase 2)
  void _navigateToPreview() {
    if (_cachedFile == null) return;

    // 🚀 Phase 2: This will navigate to AttachmentPreviewPage
    AppLogger.info(
      '🔮 Phase 2: Navigate to preview for ${widget.attachment.filename}',
    );

    // Placeholder: Show simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview: ${widget.attachment.filename}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Type: ${_cachedFile!.type.name}'),
            Text('Size: ${_formatFileSize(_cachedFile!.size)}'),
            Text(
              'Cached: ${_cachedFile!.cachedAt.toString().substring(0, 16)}',
            ),
            const SizedBox(height: 16),
            const Text('🚀 Phase 2: Full preview coming soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
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
