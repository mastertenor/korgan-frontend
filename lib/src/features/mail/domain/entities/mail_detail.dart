// lib/src/features/mail/domain/entities/mail_detail.dart

import 'mail.dart';

/// Extended mail entity for detailed view containing full content and metadata
///
/// This entity extends the base Mail class with additional properties needed
/// for displaying mail detail view including HTML content, labels, and
/// parsed sender information.
class MailDetail extends Mail {
  /// Full HTML content of the email
  final String htmlContent;

  /// Plain text version of the email content (fallback)
  final String textContent;

  /// Gmail labels associated with this email
  final List<String> labels;

  /// Parsed sender email address (extracted from sender info)
  final String senderEmail;

  /// List of recipient email addresses
  final List<String> recipients;

  /// List of CC email addresses
  final List<String> ccRecipients;

  /// List of BCC email addresses (if available)
  final List<String> bccRecipients;

  /// Reply-to email address (if different from sender)
  final String? replyTo;

  /// Message threading ID for conversation grouping
  final String? threadId;

  /// Priority level of the email (HIGH, NORMAL, LOW)
  final EmailPriority priority;

  /// Whether the email has attachments
  final bool hasAttachments;

  /// Number of attachments
  final int attachmentCount;

  /// Size of the email in bytes
  final int? sizeBytes;

  /// Date when the email was received (might differ from sent date)
  final DateTime? receivedDate;

  /// Raw message ID from Gmail API
  final String? messageId;

  MailDetail({
    // Base Mail properties
    required super.id,
    required super.senderName,
    required super.subject,
    required super.content, // This will be snippet for MailDetail
    required super.time,
    required super.isRead,
    required super.isStarred,
    super.isDeleted = false,

    // Extended MailDetail properties
    required this.htmlContent,
    required this.textContent,
    required this.labels,
    required this.senderEmail,
    this.recipients = const [],
    this.ccRecipients = const [],
    this.bccRecipients = const [],
    this.replyTo,
    this.threadId,
    this.priority = EmailPriority.normal,
    this.hasAttachments = false,
    this.attachmentCount = 0,
    this.sizeBytes,
    this.receivedDate,
    this.messageId,
  });

  /// Creates a copy of this MailDetail with updated properties
  @override
  MailDetail copyWith({
    String? id,
    String? senderName,
    String? subject,
    String? content,
    String? time,
    bool? isRead,
    bool? isStarred,
    bool? isDeleted,
    String? htmlContent,
    String? textContent,
    List<String>? labels,
    String? senderEmail,
    List<String>? recipients,
    List<String>? ccRecipients,
    List<String>? bccRecipients,
    String? replyTo,
    String? threadId,
    EmailPriority? priority,
    bool? hasAttachments,
    int? attachmentCount,
    int? sizeBytes,
    DateTime? receivedDate,
    String? messageId,
  }) {
    return MailDetail(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      htmlContent: htmlContent ?? this.htmlContent,
      textContent: textContent ?? this.textContent,
      labels: labels ?? this.labels,
      senderEmail: senderEmail ?? this.senderEmail,
      recipients: recipients ?? this.recipients,
      ccRecipients: ccRecipients ?? this.ccRecipients,
      bccRecipients: bccRecipients ?? this.bccRecipients,
      replyTo: replyTo ?? this.replyTo,
      threadId: threadId ?? this.threadId,
      priority: priority ?? this.priority,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      receivedDate: receivedDate ?? this.receivedDate,
      messageId: messageId ?? this.messageId,
    );
  }

  // ========== CONTENT UTILITIES ==========

  /// Get the best available content (HTML if available, otherwise text)
  String get bestContent => htmlContent.isNotEmpty ? htmlContent : textContent;

  /// Check if HTML content is available and safe to use
  bool get hasHtmlContent => htmlContent.isNotEmpty;

  /// Check if only plain text content is available
  bool get isTextOnly => htmlContent.isEmpty && textContent.isNotEmpty;

  /// Get content suitable for display (strips HTML if needed)
  String get displayContent {
    if (textContent.isNotEmpty) return textContent;
    if (htmlContent.isNotEmpty) return _stripHtmlTags(htmlContent);
    return content; // Fallback to snippet
  }

  /// Strip HTML tags for plain text display
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  // ========== LABEL UTILITIES ==========

  /// Check if email is in inbox
  bool get isInInbox => labels.contains('INBOX');

  /// Check if email is sent
  bool get isSent => labels.contains('SENT');

  /// Check if email is draft
  bool get isDraft => labels.contains('DRAFT');

  /// Check if email is spam
  bool get isSpam => labels.contains('SPAM');

  /// Check if email is important
  bool get isImportant => labels.contains('IMPORTANT');

  /// Get category labels (CATEGORY_PERSONAL, CATEGORY_SOCIAL, etc.)
  List<String> get categoryLabels =>
      labels.where((label) => label.startsWith('CATEGORY_')).toList();

  /// Get custom user labels (excluding system labels)
  List<String> get userLabels =>
      labels.where((label) => !_isSystemLabel(label)).toList();

  /// Check if a label is a system label
  bool _isSystemLabel(String label) {
    const systemLabels = [
      'INBOX',
      'SENT',
      'DRAFT',
      'SPAM',
      'TRASH',
      'STARRED',
      'IMPORTANT',
      'UNREAD',
      'CHAT',
    ];
    return systemLabels.contains(label) || label.startsWith('CATEGORY_');
  }

  // ========== EMAIL PARSING UTILITIES ==========

  /// Get formatted sender display (Name <email> or just email)
  String get formattedSender {
    if (senderName.isNotEmpty && senderName != senderEmail) {
      return '$senderName <$senderEmail>';
    }
    return senderEmail;
  }

  /// Get all recipients (TO + CC) as formatted strings
  List<String> get allRecipients => [...recipients, ...ccRecipients];

  /// Get total recipient count
  int get totalRecipientCount => recipients.length + ccRecipients.length;

  /// Check if this is a mass email (many recipients)
  bool get isMassEmail => totalRecipientCount > 5;

  /// Get the effective reply-to address
  String get effectiveReplyTo => replyTo ?? senderEmail;

  // ========== SIZE & PRIORITY UTILITIES ==========

  /// Get human-readable size string
  String get formattedSize {
    if (sizeBytes == null) return 'Unknown size';

    final size = sizeBytes!;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if email is large (over 1MB)
  bool get isLargeEmail => sizeBytes != null && sizeBytes! > 1024 * 1024;

  /// Get priority icon
  String get priorityIcon {
    switch (priority) {
      case EmailPriority.high:
        return '🔴';
      case EmailPriority.low:
        return '🔵';
      case EmailPriority.normal:
        return '';
    }
  }

  // ========== THREAD UTILITIES ==========

  /// Check if this email is part of a conversation thread
  bool get isPartOfThread => threadId != null && threadId!.isNotEmpty;

  /// Check if this email can be replied to
  bool get canReply => !isDraft && !isSent;

  /// Check if this email can be forwarded
  bool get canForward => !isDraft;

  // ========== FACTORY METHODS ==========

  /// Create MailDetail from base Mail entity
  factory MailDetail.fromMail(
    Mail mail, {
    required String htmlContent,
    required String textContent,
    required List<String> labels,
    required String senderEmail,
    List<String> recipients = const [],
    List<String> ccRecipients = const [],
    List<String> bccRecipients = const [],
    String? replyTo,
    String? threadId,
    EmailPriority priority = EmailPriority.normal,
    bool hasAttachments = false,
    int attachmentCount = 0,
    int? sizeBytes,
    DateTime? receivedDate,
    String? messageId,
  }) {
    return MailDetail(
      id: mail.id,
      senderName: mail.senderName,
      subject: mail.subject,
      content: mail.content,
      time: mail.time,
      isRead: mail.isRead,
      isStarred: mail.isStarred,
      isDeleted: mail.isDeleted,
      htmlContent: htmlContent,
      textContent: textContent,
      labels: labels,
      senderEmail: senderEmail,
      recipients: recipients,
      ccRecipients: ccRecipients,
      bccRecipients: bccRecipients,
      replyTo: replyTo,
      threadId: threadId,
      priority: priority,
      hasAttachments: hasAttachments,
      attachmentCount: attachmentCount,
      sizeBytes: sizeBytes,
      receivedDate: receivedDate,
      messageId: messageId,
    );
  }

  @override
  String toString() {
    return 'MailDetail(id: $id, senderName: $senderName, subject: $subject, '
        'htmlContent: ${htmlContent.length} chars, labels: $labels, '
        'priority: $priority, hasAttachments: $hasAttachments)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailDetail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Email priority levels
enum EmailPriority { high, normal, low }
