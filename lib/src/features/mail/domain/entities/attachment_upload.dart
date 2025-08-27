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

  /// Content-ID for inline attachments (used for CID references)
  final String? contentId;

  // 🆕 FORWARD SUPPORT - Enhanced fields
  /// Whether this attachment was forwarded from another email
  final bool isForwarded;

  /// Original attachment ID (for forwarded attachments)
  final String? originalAttachmentId;

  /// 🆕 Whether this is a placeholder attachment (content not yet downloaded)
  final bool isPlaceholder;

  const AttachmentUpload({
    required this.content,
    required this.type,
    required this.filename,
    this.disposition = 'attachment',
    this.contentId,
    // Forward support parameters
    this.isForwarded = false,
    this.originalAttachmentId,
    // 🆕 Placeholder support parameter
    this.isPlaceholder = false,
  });

  // 🆕 Enhanced forward factory constructor
  /// Create forwarded attachment from MailAttachment
  factory AttachmentUpload.fromMailAttachment({
    required String attachmentId,
    required String filename,
    required String mimeType,
    required String content,
    String disposition = 'attachment',
    String? contentId,
    bool isPlaceholder = false, // 🆕 NEW PARAMETER
  }) {
    return AttachmentUpload(
      content: content,
      type: mimeType,
      filename: filename,
      disposition: disposition,
      contentId: contentId,
      isForwarded: true,
      originalAttachmentId: attachmentId,
      isPlaceholder: isPlaceholder, // 🆕 SET PLACEHOLDER STATUS
    );
  }

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
      isForwarded: false, // New file, not forwarded
      isPlaceholder: false, // Real file, not placeholder
    );
  }

  /// Convert to JSON format for API request
  Map<String, dynamic> toJson() {
    final json = {
      'content': content,
      'type': type,
      'filename': filename,
      'disposition': disposition,
    };

    if (contentId != null && contentId!.isNotEmpty) {
      json['content_id'] = contentId!;
    }

    return json;
  }

  /// Create from JSON
  factory AttachmentUpload.fromJson(Map<String, dynamic> json) {
    return AttachmentUpload(
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'application/octet-stream',
      filename: json['filename']?.toString() ?? 'attachment.bin',
      disposition: json['disposition']?.toString() ?? 'attachment',
      contentId: json['content_id']?.toString(),
      isForwarded: json['is_forwarded'] == true,
      originalAttachmentId: json['original_attachment_id']?.toString(),
      isPlaceholder: json['is_placeholder'] == true, // 🆕 PARSE PLACEHOLDER
    );
  }

  /// Get file size estimate from base64 content
  int get estimatedSizeBytes {
    // 🆕 Placeholder attachments have no real size
    if (isPlaceholder) return 0;
    
    // Base64 encoding increases size by ~33%
    // Remove padding characters and calculate original size
    final contentLength = content.replaceAll('=', '').length;
    return (contentLength * 0.75).round();
  }

  /// Get formatted file size for display
  String get sizeFormatted {
    // 🆕 Special formatting for placeholders
    if (isPlaceholder) return 'Downloading...';
    
    final size = estimatedSizeBytes;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if attachment is inline
  bool get isInline => disposition.toLowerCase() == 'inline';

  /// Check if content is valid base64
  bool get hasValidContent {
    // 🆕 Placeholders don't have valid content yet
    if (isPlaceholder) return false;
    if (content.isEmpty) return false;
    
    // Basic base64 validation
    final base64RegExp = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64RegExp.hasMatch(content);
  }

  /// 🆕 Check if attachment is ready to send
  bool get isReadyToSend {
    return !isPlaceholder && hasValidContent;
  }

  /// 🆕 Get display status text
  String get statusText {
    if (isPlaceholder) return 'Downloading...';
    if (isForwarded && hasValidContent) return 'Forwarded';
    if (hasValidContent) return 'Ready';
    return 'Invalid';
  }

  /// Copy with updated values
  AttachmentUpload copyWith({
    String? content,
    String? type,
    String? filename,
    String? disposition,
    String? contentId,
    // Forward support in copyWith
    bool? isForwarded,
    String? originalAttachmentId,
    // 🆕 Placeholder support in copyWith
    bool? isPlaceholder,
  }) {
    return AttachmentUpload(
      content: content ?? this.content,
      type: type ?? this.type,
      filename: filename ?? this.filename,
      disposition: disposition ?? this.disposition,
      contentId: contentId ?? this.contentId,
      isForwarded: isForwarded ?? this.isForwarded,
      originalAttachmentId: originalAttachmentId ?? this.originalAttachmentId,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder, // 🆕 INCLUDE IN COPYWITH
    );
  }

  /// 🆕 Create a resolved version of placeholder attachment
  AttachmentUpload resolveWithContent(String downloadedContent) {
    if (!isPlaceholder) {
      throw StateError('Cannot resolve non-placeholder attachment');
    }
    
    return copyWith(
      content: downloadedContent,
      isPlaceholder: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttachmentUpload &&
           other.content == content &&
           other.type == type &&
           other.filename == filename &&
           other.disposition == disposition &&
           other.contentId == contentId &&
           other.isForwarded == isForwarded &&
           other.originalAttachmentId == originalAttachmentId &&
           other.isPlaceholder == isPlaceholder; // 🆕 INCLUDE IN EQUALITY
  }

  @override
  int get hashCode => Object.hash(
    content, 
    type, 
    filename, 
    disposition, 
    contentId,
    isForwarded,
    originalAttachmentId,
    isPlaceholder, // 🆕 INCLUDE IN HASHCODE
  );

  @override
  String toString() {
    return 'AttachmentUpload(filename: $filename, type: $type, size: $sizeFormatted, disposition: $disposition, isForwarded: $isForwarded, isPlaceholder: $isPlaceholder)';
  }

  /// Helper method to encode bytes to base64
  static String _encodeBase64(List<int> bytes) {
    // This would typically use dart:convert base64 encoding
    // For now, placeholder - will be implemented properly
    return ''; // TODO: Implement proper base64 encoding
  }
}