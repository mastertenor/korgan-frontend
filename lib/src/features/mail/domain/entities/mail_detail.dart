// lib/src/features/mail/domain/entities/mail_detail.dart

import 'mail.dart';
import 'attachment.dart';

/// Extended mail entity for detailed view containing full content and metadata
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

  final List<String> recipientNames;
  final List<String> ccRecipientNames;
  final List<String> bccRecipientNames;

  /// Reply-to email address (if different from sender)
  final String? replyTo;

  /// Message threading ID for conversation grouping
  final String? threadId;

  /// Priority level of the email (HIGH, NORMAL, LOW)
  final EmailPriority priority;

  /// Size of the email in bytes
  final int? sizeBytes;

  /// Date when the email was received (might differ from sent date)
  final DateTime? receivedDate;

  /// Raw message ID from Gmail API
  final String? messageId;

  MailDetail({
    // Base Mail properties - including attachments from parent
    required super.id,
    required super.senderName,
    required super.subject,
    required super.content,
    required super.time,
    required super.isRead,
    required super.isStarred,
    super.isDeleted = false,
    super.attachments = const [],
    super.highlightedSnippet,
    super.highlightInfo,
    // Extended MailDetail properties
    required this.htmlContent,
    required this.textContent,
    required this.labels,
    required this.senderEmail,
    this.recipients = const [],
    this.ccRecipients = const [],
    this.bccRecipients = const [],
    this.recipientNames = const [],
    this.ccRecipientNames = const [],
    this.bccRecipientNames = const [],
    this.replyTo,
    this.threadId,
    this.priority = EmailPriority.normal,
    this.sizeBytes,
    this.receivedDate,
    this.messageId,
  });

  // 🔧 Backward compatibility
  List<MailAttachment> get attachmentsList => attachments;

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
    List<MailAttachment>? attachments,
    String? highlightedSnippet, // 🆕 EKLE
    Map<String, dynamic>? highlightInfo, // 🆕 EKLE
    String? htmlContent,
    String? textContent,
    List<String>? labels,
    String? senderEmail,
    List<String>? recipients,
    List<String>? ccRecipients,
    List<String>? bccRecipients,
    List<String>? recipientNames,
    List<String>? ccRecipientNames,
    List<String>? bccRecipientNames,
    String? replyTo,
    String? threadId,
    EmailPriority? priority,
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
      attachments: attachments ?? this.attachments,
      highlightedSnippet: highlightedSnippet ?? this.highlightedSnippet, // 🆕
      highlightInfo: highlightInfo ?? this.highlightInfo, // 🆕
      htmlContent: htmlContent ?? this.htmlContent,
      textContent: textContent ?? this.textContent,
      labels: labels ?? this.labels,
      senderEmail: senderEmail ?? this.senderEmail,
      recipients: recipients ?? this.recipients,
      ccRecipients: ccRecipients ?? this.ccRecipients,
      bccRecipients: bccRecipients ?? this.bccRecipients,
      recipientNames: recipientNames ?? this.recipientNames,
      ccRecipientNames: ccRecipientNames ?? this.ccRecipientNames,
      bccRecipientNames: bccRecipientNames ?? this.bccRecipientNames,
      replyTo: replyTo ?? this.replyTo,
      threadId: threadId ?? this.threadId,
      priority: priority ?? this.priority,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      receivedDate: receivedDate ?? this.receivedDate,
      messageId: messageId ?? this.messageId,
    );
  }

  // ========== ORJİNAL'DEN GELEN GÜZEL CONTENT UTILITIES ==========

  /// Get the best available content (HTML if available, otherwise text)
  String get bestContent => htmlContent.isNotEmpty ? htmlContent : textContent;

  /// Check if HTML content is available and safe to use
  bool get hasHtmlContent => htmlContent.isNotEmpty;

  /// Check if only plain text content is available
  bool get isTextOnly => htmlContent.isEmpty && textContent.isNotEmpty;

  /// Get safe plain text content (never null/empty)
  String get safeTextContent {
    if (textContent.isNotEmpty) return textContent;
    if (content.isNotEmpty) return content;
    return 'İçerik bulunamadı';
  }

  /// Get safe HTML content (never null/empty)
  String get safeHtmlContent {
    if (htmlContent.isNotEmpty) return htmlContent;
    if (textContent.isNotEmpty) {
      return '<div>${textContent.replaceAll('\n', '<br>')}</div>';
    }
    return '<div>İçerik bulunamadı</div>';
  }

  /// Get content suitable for display (strips HTML if needed)
  String get displayContent {
    if (textContent.isNotEmpty) return textContent;
    if (htmlContent.isNotEmpty) return _stripHtmlTags(htmlContent);
    return content;
  }

  /// Strip HTML tags for plain text display
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ========== ORJİNAL'DEN GELEN LABEL UTILITIES ==========

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

  // ========== ORJİNAL'DEN GELEN EMAIL PARSING UTILITIES ==========

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
    if (sizeBytes == null) return '';

    final bytes = sizeBytes!;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
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

  // ========== DATE & TIME UTILITIES ==========

  /// Lokal saat olarak döner (UTC gelirse toLocal ile dönüştürür)
  DateTime? get localReceivedDate => receivedDate?.toLocal();

  /// Lokal formatlı ve insan dostu string döner
  String get formattedReceivedDate {
    if (localReceivedDate == null) return '';
    final now = DateTime.now();
    final difference = now.difference(localReceivedDate!);
    if (difference.inDays == 0) {
      return '${localReceivedDate!.hour.toString().padLeft(2, '0')}:${localReceivedDate!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${localReceivedDate!.day.toString().padLeft(2, '0')}/'
          '${localReceivedDate!.month.toString().padLeft(2, '0')}/'
          '${localReceivedDate!.year}';
    }
  }

  String get formattedReceivedUtcLocalDateTime {
    if (localReceivedDate == null) return '';

    final date = localReceivedDate!;

    // Türkçe ay isimleri
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    // Türkçe gün isimleri (DateTime.weekday: 1=Pazartesi, 7=Pazar)
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final weekday = weekdays[date.weekday - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year $weekday $hour:$minute';
  }

  // ========== THREAD & REPLY UTILITIES ==========

  /// Check if this email is part of a conversation thread
  bool get isPartOfThread => threadId != null && threadId!.isNotEmpty;

  /// Check if this email can be replied to
  bool get canReply => !isDraft && !isSent;

  /// Check if this email can be forwarded
  bool get canForward => !isDraft;

  /// Check if email is a reply (based on subject)
  bool get isReply => subject.toLowerCase().startsWith('re:');

  /// Check if email is forwarded (based on subject)
  bool get isForwarded =>
      subject.toLowerCase().startsWith('fwd:') ||
      subject.toLowerCase().startsWith('fw:');

  // ========== FACTORY METHOD ==========

  /// Create MailDetail from base Mail
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
      attachments: mail.attachments,
      highlightedSnippet: mail.highlightedSnippet,
      highlightInfo: mail.highlightInfo,
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
      sizeBytes: sizeBytes,
      receivedDate: receivedDate,
      messageId: messageId,
    );
  }

  @override
  String toString() {
    return 'MailDetail(id: $id, senderName: $senderName, subject: $subject, '
        'htmlContent: ${htmlContent.length} chars, labels: $labels, '
        'priority: $priority, hasAttachments: $hasAttachments, '
        'attachmentCount: $attachmentCount)';
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
