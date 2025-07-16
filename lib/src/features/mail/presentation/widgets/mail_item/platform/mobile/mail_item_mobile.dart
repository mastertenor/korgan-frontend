// lib/src/features/mail/presentation/widgets/mail_item/platform/mobile/mail_item_mobile.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

/// Mobile-specific implementation of mail item widget
class MailItemMobile extends StatelessWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemMobile({
    super.key,
    required this.mail,
    this.isSelected = false,
    this.onTap,
    this.onArchive,
    this.onToggleStar,
    this.onToggleSelection,
    this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 4,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: MailUtils.getAvatarColor(mail.senderName),
                    child: Text(
                      MailUtils.getAvatarInitial(mail.senderName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender + Time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mail.senderName,
                                style: TextStyle(
                                  fontWeight: mail.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: mail.isRead
                                      ? Colors.black87
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              mail.time,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Subject
                        Text(
                          mail.subject.isNotEmpty ? mail.subject : '(konu yok)',
                          style: TextStyle(
                            fontWeight: mail.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                            color: mail.isRead
                                ? Colors.grey[700]
                                : Colors.black,
                            fontStyle: mail.subject.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),

                        // Content (if not empty)
                        if (mail.content.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            mail.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],

                        // Attachments (if any)
                        if (mail.hasAttachments) ...[
                          const SizedBox(height: 6),
                          _buildAttachmentIndicator(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: onToggleStar,
              child: Icon(
                mail.isStarred ? Icons.star : Icons.star_border,
                color: mail.isStarred ? Colors.amber : Colors.grey[400],
                size: 20,
              ),
            ),

            if (!mail.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentIndicator() {
    final firstAttachment = mail.attachments.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(firstAttachment.mimeType),
            size: 16,
            color: _getFileColor(firstAttachment.mimeType),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _truncateFilename(firstAttachment.filename),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('rar') ||
        mimeType.contains('zip') ||
        mimeType.contains('compressed'))
      return Icons.folder_zip;
    if (mimeType.contains('csv') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('excel'))
      return Icons.table_chart;
    if (mimeType.contains('doc') || mimeType.contains('word'))
      return Icons.description;
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.contains('audio') || mimeType.contains('wav'))
      return Icons.audiotrack;
    return Icons.attach_file;
  }

  Color _getFileColor(String mimeType) {
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('rar') ||
        mimeType.contains('zip') ||
        mimeType.contains('compressed'))
      return Colors.blue;
    if (mimeType.contains('csv') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('excel'))
      return Colors.blue;
    if (mimeType.contains('doc') || mimeType.contains('word'))
      return Colors.blue;
    if (mimeType.startsWith('image/')) return Colors.green;
    if (mimeType.contains('audio') || mimeType.contains('wav'))
      return Colors.orange;
    return Colors.grey;
  }

  String _truncateFilename(String filename) {
    if (filename.length <= 15) return filename;

    final parts = filename.split('.');
    if (parts.length > 1) {
      final extension = parts.last;
      final nameWithoutExt = parts.sublist(0, parts.length - 1).join('.');

      if (nameWithoutExt.length > (15 - extension.length - 1)) {
        final maxNameLength = 15 - extension.length - 4;
        return '${nameWithoutExt.substring(0, maxNameLength)}...$extension';
      }
    }

    return '${filename.substring(0, 12)}...';
  }
}
