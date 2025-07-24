// lib/src/features/mail/domain/entities/attachment_upload.dart

/// Attachment upload entity for mail composition
///
/// Represents a file attachment to be uploaded with base64 content.
/// Used when composing or replying to emails with file attachments.
class AttachmentUpload {
  /// Base64 encoded file content
  final String content;

  /// MIME type of the file (e.g., 'application/pdf', 'image/jpeg')
  final String type;

  /// Original filename of the attachment
  final String filename;

  /// Content disposition - "attachment" or "inline"
  final String disposition;

  const AttachmentUpload({
    required this.content,
    required this.type,
    required this.filename,
    this.disposition = 'attachment',
  });

  /// Create from file data
  factory AttachmentUpload.fromFileData({
    required List<int> bytes,
    required String filename,
    required String mimeType,
    String disposition = 'attachment',
  }) {
    final base64Content = _encodeBase64(bytes);
    return AttachmentUpload(
      content: base64Content,
      type: mimeType,
      filename: filename,
      disposition: disposition,
    );
  }

  /// Convert to JSON format for API request
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type,
      'filename': filename,
      'disposition': disposition,
    };
  }

  /// Create from JSON
  factory AttachmentUpload.fromJson(Map<String, dynamic> json) {
    return AttachmentUpload(
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'application/octet-stream',
      filename: json['filename']?.toString() ?? 'attachment.bin',
      disposition: json['disposition']?.toString() ?? 'attachment',
    );
  }

  /// Get file size estimate from base64 content
  int get estimatedSizeBytes {
    // Base64 encoding increases size by ~33%
    // Remove padding characters and calculate original size
    final contentLength = content.replaceAll('=', '').length;
    return (contentLength * 0.75).round();
  }

  /// Get formatted file size for display
  String get sizeFormatted {
    final size = estimatedSizeBytes;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if attachment is inline
  bool get isInline => disposition.toLowerCase() == 'inline';

  /// Check if content is valid base64
  bool get hasValidContent {
    if (content.isEmpty) return false;
    
    // Basic base64 validation
    final base64RegExp = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64RegExp.hasMatch(content);
  }

  /// Copy with updated values
  AttachmentUpload copyWith({
    String? content,
    String? type,
    String? filename,
    String? disposition,
  }) {
    return AttachmentUpload(
      content: content ?? this.content,
      type: type ?? this.type,
      filename: filename ?? this.filename,
      disposition: disposition ?? this.disposition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttachmentUpload &&
           other.content == content &&
           other.type == type &&
           other.filename == filename &&
           other.disposition == disposition;
  }

  @override
  int get hashCode => Object.hash(content, type, filename, disposition);

  @override
  String toString() {
    return 'AttachmentUpload(filename: $filename, type: $type, size: $sizeFormatted, disposition: $disposition)';
  }

  /// Helper method to encode bytes to base64
  static String _encodeBase64(List<int> bytes) {
    // This would typically use dart:convert base64 encoding
    // For now, placeholder - will be implemented properly
    return ''; // TODO: Implement proper base64 encoding
  }
}