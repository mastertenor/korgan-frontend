// lib/src/features/mail/domain/entities/attachment.dart

import 'package:flutter/material.dart';

/// Mail attachment domain entity
///
/// Represents an email attachment with basic properties
/// needed for display and download functionality.
class MailAttachment {
  /// Unique attachment ID from Gmail API
  final String id;

  /// Original filename of the attachment
  final String filename;

  /// MIME type (e.g., 'application/pdf', 'image/jpeg')
  final String mimeType;

  /// File size in bytes
  final int size;

  /// Whether this attachment is inline (embedded in email body)
  final bool isInline;

  const MailAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.isInline = false,
  });

  /// Get formatted file size for display (e.g., "1.2 MB", "500 KB")
  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Get appropriate icon based on file type
  IconData get icon {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('doc')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    if (mimeType.contains('zip') || mimeType.contains('rar')) {
      return Icons.folder_zip;
    }
    return Icons.attach_file;
  }

  /// Get color based on file type
  Color get color {
    if (mimeType.startsWith('image/')) return Colors.green;
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('doc')) return Colors.blue;
    if (mimeType.contains('excel')) return Colors.green.shade700;
    return Colors.grey;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailAttachment &&
        other.id == id &&
        other.filename == filename;
  }

  @override
  int get hashCode => Object.hash(id, filename);

  @override
  String toString() {
    return 'MailAttachment(id: $id, filename: $filename, size: $sizeFormatted)';
  }
}
