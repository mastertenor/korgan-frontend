// lib/src/features/mail/presentation/pages/mobile/attachment_list_tile_mobile.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../../../domain/entities/attachment.dart';

/// Simple attachment list tile widget for displaying email attachments
///
/// Shows attachment info with download functionality and progress indicator
class AttachmentListTile extends StatefulWidget {
  final MailAttachment attachment;
  final String messageId;
  final String email;
  final Future<Uint8List> Function({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
    String? mimeType,
  })
  onDownload;

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
  String? _errorMessage;

  Future<void> _handleDownload() async {
    if (_isDownloading || _downloadCompleted) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      print('📎 Starting download for: ${widget.attachment.filename}');

      // Call the download function
      final bytes = await widget.onDownload(
        messageId: widget.messageId,
        attachmentId: widget.attachment.id,
        filename: widget.attachment.filename,
        email: widget.email,
        mimeType: widget.attachment.mimeType,
      );

      print('📎 Download completed: ${bytes.length} bytes');

      setState(() {
        _downloadCompleted = true;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.attachment.filename} indirildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Download failed: $e');

      setState(() {
        _errorMessage = e.toString();
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme hatası: $e'),
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

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: _handleDownload,
      tooltip: 'İndir',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.attachment.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.attachment.icon,
            color: widget.attachment.color,
            size: 20,
          ),
        ),
        title: Text(
          widget.attachment.filename,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.attachment.sizeFormatted,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hata: $_errorMessage',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_downloadCompleted) ...[
              const SizedBox(height: 4),
              Text(
                'İndirildi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: _buildTrailingWidget(),
      ),
    );
  }
}
