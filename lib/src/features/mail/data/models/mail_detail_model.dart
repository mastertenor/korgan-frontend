// lib/src/features/mail/data/models/mail_detail_model.dart

import '../../domain/entities/mail_detail.dart';

/// Data model for parsing backend mail detail API response
///
/// This model handles parsing of detailed mail information from the backend API
/// including HTML content, labels, metadata, and converts it to domain entity.
class MailDetailModel {
  final String id;
  final String threadId;
  final String from;
  final String to;
  final String cc;
  final String bcc;
  final String replyTo;
  final String subject;
  final String date;
  final String snippet;
  final bool isUnread;
  final String internalDate;
  final Map<String, dynamic> content;
  final List<dynamic> attachments;
  final bool hasAttachments;
  final List<String> labels;
  final String priority;
  final int messageSize;
  final bool isImportant;
  final String receivedAt;
  final String sentAt;
  final String displayName;

  const MailDetailModel({
    required this.id,
    required this.threadId,
    required this.from,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.replyTo,
    required this.subject,
    required this.date,
    required this.snippet,
    required this.isUnread,
    required this.internalDate,
    required this.content,
    required this.attachments,
    required this.hasAttachments,
    required this.labels,
    required this.priority,
    required this.messageSize,
    required this.isImportant,
    required this.receivedAt,
    required this.sentAt,
    required this.displayName,
  });

  /// Create from backend API JSON response
  factory MailDetailModel.fromJson(Map<String, dynamic> json) {
    return MailDetailModel(
      id: json['id']?.toString() ?? '',
      threadId: json['threadId']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      cc: json['cc']?.toString() ?? '',
      bcc: json['bcc']?.toString() ?? '',
      replyTo: json['replyTo']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
      isUnread: json['isUnread'] == true,
      internalDate: json['internalDate']?.toString() ?? '',
      content: json['content'] as Map<String, dynamic>? ?? {},
      attachments: json['attachments'] as List<dynamic>? ?? [],
      hasAttachments: json['hasAttachments'] == true,
      labels:
          (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      priority: json['priority']?.toString() ?? 'normal',
      messageSize: json['messageSize'] as int? ?? 0,
      isImportant: json['isImportant'] == true,
      receivedAt: json['receivedAt']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'from': from,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'replyTo': replyTo,
      'subject': subject,
      'date': date,
      'snippet': snippet,
      'isUnread': isUnread,
      'internalDate': internalDate,
      'content': content,
      'attachments': attachments,
      'hasAttachments': hasAttachments,
      'labels': labels,
      'priority': priority,
      'messageSize': messageSize,
      'isImportant': isImportant,
      'receivedAt': receivedAt,
      'sentAt': sentAt,
      'displayName': displayName,
    };
  }

  /// Convert to domain entity
  MailDetail toDomain() {
    return MailDetail(
      // Base Mail properties
      id: id,
      senderName: _extractSenderName(),
      subject: subject.isNotEmpty ? subject : 'No Subject',
      content: snippet.isNotEmpty ? snippet : _extractTextContent(),
      time: _formatDisplayTime(),
      isRead: !isUnread,
      isStarred: labels.contains('STARRED'),
      isDeleted: labels.contains('TRASH'),

      // Extended MailDetail properties
      htmlContent: _getHtmlContent(),
      textContent: _getTextContent(),
      labels: labels,
      senderEmail: _extractSenderEmail(),
      recipients: _parseEmailList(to),
      ccRecipients: _parseEmailList(cc),
      bccRecipients: _parseEmailList(bcc),
      replyTo: _extractSenderEmail(replyTo),
      threadId: threadId,
      priority: _parsePriority(),
      hasAttachments: hasAttachments,
      attachmentCount: attachments.length,
      sizeBytes: messageSize,
      receivedDate: _parseDateTime(receivedAt),
      messageId: id, // Use id as messageId
    );
  }

  // ========== CONTENT EXTRACTION ==========

  /// Get HTML content from content object
  String _getHtmlContent() {
    return content['html']?.toString() ?? '';
  }

  /// Get text content from content object or generate from HTML
  String _getTextContent() {
    // Check if text content is provided
    final textContent = content['text']?.toString();
    if (textContent != null && textContent.isNotEmpty) {
      return textContent;
    }

    // Fallback: extract from HTML content
    final htmlContent = _getHtmlContent();
    if (htmlContent.isNotEmpty) {
      return _stripHtmlTags(htmlContent);
    }

    // Last fallback: use snippet
    return snippet;
  }

  /// Extract plain text content for display (fallback method)
  String _extractTextContent() {
    final textContent = _getTextContent();
    return textContent.isNotEmpty ? textContent : snippet;
  }

  /// Strip HTML tags for plain text display
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll('&nbsp;', ' ') // Replace HTML entities
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&ouml;', 'ö')
        .trim();
  }

  // ========== EMAIL PARSING ==========

  /// Extract sender name from from field or use displayName
  String _extractSenderName() {
    // First try displayName if available
    if (displayName.isNotEmpty && displayName != from) {
      return displayName;
    }

    // Extract name from "Name" <email> format
    return _extractNameFromEmailField(from);
  }

  /// Extract sender email from from field
  String _extractSenderEmail([String? emailField]) {
    final field = emailField ?? from;
    return _extractEmailFromField(field);
  }

  /// Extract name from email header field
  String _extractNameFromEmailField(String emailField) {
    if (emailField.isEmpty) return 'Unknown Sender';

    // Format: "Name" <email@domain.com> or Name <email@domain.com>
    final match = RegExp(r'^"?([^"<]+)"?\s*<').firstMatch(emailField);
    if (match != null) {
      return match.group(1)?.trim() ?? 'Unknown Sender';
    }

    // Format: email@domain.com (extract username)
    if (emailField.contains('@') && !emailField.contains('<')) {
      return emailField.split('@').first;
    }

    return emailField.trim();
  }

  /// Extract email address from email header field
  String _extractEmailFromField(String emailField) {
    if (emailField.isEmpty) return '';

    // Extract email from angle brackets: Name <email@domain.com>
    final match = RegExp(r'<([^>]+)>').firstMatch(emailField);
    if (match != null) {
      return match.group(1) ?? '';
    }

    // If no brackets, check if it's a direct email
    if (emailField.contains('@') && !emailField.contains(' ')) {
      return emailField.trim();
    }

    return '';
  }

  /// Parse comma-separated email list
  List<String> _parseEmailList(String emailList) {
    if (emailList.isEmpty) return [];

    return emailList
        .split(',')
        .map((email) => _extractEmailFromField(email.trim()))
        .where((email) => email.isNotEmpty)
        .toList();
  }

  // ========== METADATA PARSING ==========

  /// Parse priority from string to enum
  EmailPriority _parsePriority() {
    switch (priority.toLowerCase()) {
      case 'high':
        return EmailPriority.high;
      case 'low':
        return EmailPriority.low;
      case 'normal':
      default:
        return EmailPriority.normal;
    }
  }

  /// Parse datetime string to DateTime object
  DateTime? _parseDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return null;

    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      // Try parsing the date field as fallback
      return _parseDateField();
    }
  }

  /// Parse the date field (RFC 2822 format)
  DateTime? _parseDateField() {
    if (date.isEmpty) return null;

    try {
      // Parse RFC 2822 format: "Fri, 11 Jul 2025 18:56:24 +0300"
      return DateTime.parse(date);
    } catch (e) {
      try {
        // Try parsing internal date (milliseconds since epoch)
        if (internalDate.isNotEmpty) {
          final timestamp = int.tryParse(internalDate);
          if (timestamp != null) {
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }
      } catch (e2) {
        // Ignore parsing errors
      }
      return null;
    }
  }

  // ========== DATE FORMATTING ==========

  /// Format date for display (consistent with existing mail formatting)
  String _formatDisplayTime() {
    final dateTime =
        _parseDateTime(receivedAt) ??
        _parseDateTime(sentAt) ??
        _parseDateField();
    if (dateTime == null) return 'Unknown';

    try {
      final now = DateTime.now();

      // Same day: show time
      if (dateTime.day == now.day &&
          dateTime.month == now.month &&
          dateTime.year == now.year) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      // Different day: show date
      return '${dateTime.day} ${_getMonthName(dateTime.month)}';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get Turkish month name (consistent with existing code)
  String _getMonthName(int month) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : 'Unknown';
  }

  // ========== UTILITY METHODS ==========

  /// Create empty/default model for error cases
  factory MailDetailModel.empty(String id) {
    return MailDetailModel(
      id: id,
      threadId: '',
      from: '',
      to: '',
      cc: '',
      bcc: '',
      replyTo: '',
      subject: '',
      date: '',
      snippet: '',
      isUnread: false,
      internalDate: '',
      content: {},
      attachments: [],
      hasAttachments: false,
      labels: [],
      priority: 'normal',
      messageSize: 0,
      isImportant: false,
      receivedAt: '',
      sentAt: '',
      displayName: '',
    );
  }

  /// Check if this mail has valid content
  bool get hasValidContent =>
      _getHtmlContent().isNotEmpty || _getTextContent().isNotEmpty;

  /// Get content type (html, text, or empty)
  String get contentType {
    if (_getHtmlContent().isNotEmpty) return 'html';
    if (_getTextContent().isNotEmpty) return 'text';
    return 'empty';
  }

  /// Get formatted size for display
  String get formattedSize {
    if (messageSize <= 0) return 'Unknown size';

    if (messageSize < 1024) return '${messageSize}B';
    if (messageSize < 1024 * 1024) {
      return '${(messageSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(messageSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if this is a large email (over 1MB)
  bool get isLargeEmail => messageSize > 1024 * 1024;

  @override
  String toString() {
    return 'MailDetailModel(id: $id, threadId: $threadId, '
        'from: $from, subject: $subject, '
        'hasAttachments: $hasAttachments, size: $formattedSize, '
        'contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailDetailModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
