// lib/src/features/mail/data/models/mail_model.dart

import '../../domain/entities/mail.dart';
import '../../domain/entities/attachment.dart';

class MailModel {
  final String id;
  final String threadId;
  final String from;
  final String to;
  final String subject;
  final String date;
  final List<String> labels;
  final String snippet;
  final bool isUnread;
  final bool isAttachments; // 🔧 API'de bu isimle geliyor
  final List<dynamic> attachments;
  
  // 🆕 HIGHLIGHT FIELDS
  final String? highlightedSnippet;
  final Map<String, dynamic>? highlightInfo;

  const MailModel({
    required this.id,
    required this.threadId,
    required this.from,
    required this.to,
    required this.subject,
    required this.date,
    required this.labels,
    required this.snippet,
    required this.isUnread,
    this.isAttachments = false,
    this.attachments = const [],
    this.highlightedSnippet,
    this.highlightInfo,
  });

  factory MailModel.fromJson(Map<String, dynamic> json) {
    return MailModel(
      id: json['id']?.toString() ?? '',
      threadId: json['threadId']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      labels:
          (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      snippet: json['snippet']?.toString() ?? '',
      isUnread: json['isUnread'] == true,
      isAttachments: json['isAttachments'] == true, // 🔧 API field
      attachments: json['attachments'] as List<dynamic>? ?? [],
      // 🆕 HIGHLIGHT PARSING
      highlightedSnippet: json['highlightedSnippet']?.toString(),
      highlightInfo: json['highlightInfo'] as Map<String, dynamic>?,
    );
  }

  List<MailAttachment> parseAttachments() {
    if (!isAttachments || attachments.isEmpty) return [];

    return attachments.map((data) {
      final map = data as Map<String, dynamic>;
      return MailAttachment(
        id: map['attachmentId']?.toString() ?? 'unknown',
        filename: map['filename']?.toString() ?? 'attachment.bin',
        mimeType: map['mimeType']?.toString() ?? 'application/octet-stream',
        size: map['size'] is int ? map['size'] : 0,
        isInline: false,
      );
    }).toList();
  }

  Mail toDomain() {
    return Mail(
      id: id,
      senderName: _extractSenderName(),
      subject: subject,
      content: snippet,
      time: _formatDate(),
      isRead: !isUnread,
      isStarred: labels.contains('STARRED'),
      isDeleted: labels.contains('TRASH'),
      attachments: parseAttachments(),
      // 🆕 HIGHLIGHT MAPPING
      highlightedSnippet: highlightedSnippet,
      highlightInfo: highlightInfo,
    );
  }

  /// Extract sender name from "Name" <email> format
  String _extractSenderName() {
    if (from.contains('<')) {
      final parts = from.split('<');
      String name = parts.first.trim();
      // Remove quotes if present
      name = name.replaceAll(RegExp(r'^"|"$'), '');
      return name.isNotEmpty ? name : _extractEmailUsername();
    }

    if (from.contains('@')) {
      return _extractEmailUsername();
    }

    return from.trim();
  }

  /// Extract username from email
  String _extractEmailUsername() {
    if (from.contains('@')) {
      String email = from;
      if (from.contains('<') && from.contains('>')) {
        final match = RegExp(r'<([^>]+)>').firstMatch(from);
        email = match?.group(1) ?? from;
      }
      return email.split('@').first;
    }
    return from;
  }

  /// Format date for display
  String _formatDate() {
    if (date.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final mailDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (mailDate == today) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (mailDate == yesterday) {
        return 'Dün';
      } else if (now.difference(dateTime).inDays < 7) {
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        return days[dateTime.weekday - 1];
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return date.length > 10 ? date.substring(0, 10) : date;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'from': from,
      'to': to,
      'subject': subject,
      'date': date,
      'labels': labels,
      'snippet': snippet,
      'isUnread': isUnread,
      'isAttachments': isAttachments, // 🔧 Correct field name
      'attachments': attachments,
      // 🆕 HIGHLIGHT SERIALIZATION
      if (highlightedSnippet != null) 'highlightedSnippet': highlightedSnippet,
      if (highlightInfo != null) 'highlightInfo': highlightInfo,
    };
  }

  @override
  String toString() {
    return 'MailModel(id: $id, from: $from, isAttachments: $isAttachments, attachments: ${attachments.length})';
  }
}