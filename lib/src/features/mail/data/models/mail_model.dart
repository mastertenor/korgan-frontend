// lib/src/features/mail/data/models/mail_model.dart

import '../../domain/entities/mail.dart';

/// Simple model for parsing Gmail messages
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
  });

  /// Create from JSON
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
    );
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
    };
  }

  /// Convert to domain entity
  Mail toDomain() {
    return Mail(
      id: id, // Pass the Gmail message ID
      senderName: _extractSenderName(),
      subject: subject,
      content: snippet,
      time: _formatDate(),
      isRead: !isUnread,
      isStarred: labels.contains('STARRED'),
      isDeleted: labels.contains('TRASH'), // Check if mail is in trash
    );
  }

  /// Extract sender name - simple version
  String _extractSenderName() {
    // Simple extraction: if contains <>, take part before it
    if (from.contains('<')) {
      final parts = from.split('<');
      final name = parts.first.trim();
      return name.isNotEmpty ? name : from;
    }
    return from;
  }

  /// Format date - simple version
  String _formatDate() {
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();

      // Same day: show time
      if (parsedDate.day == now.day &&
          parsedDate.month == now.month &&
          parsedDate.year == now.year) {
        return '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
      }

      // Different day: show date
      return '${parsedDate.day} ${_getMonthName(parsedDate.month)}';
    } catch (e) {
      return date;
    }
  }

  /// Get Turkish month name
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
    return months[month - 1];
  }

  /// Check if starred
  bool get isStarred => labels.contains('STARRED');

  /// Check if read
  bool get isRead => !isUnread;

  /// Check if deleted (in trash)
  bool get isDeleted => labels.contains('TRASH');

  /// Check if active (not deleted)
  bool get isActive => !isDeleted;
}
