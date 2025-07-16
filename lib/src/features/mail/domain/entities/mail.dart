// lib/src/features/mail/domain/entities/mail.dart

import 'attachment.dart';

class Mail {
  final String id;
  final String senderName;
  final String subject;
  final String content;
  final String time;
  bool isRead;
  bool isStarred;
  bool isDeleted;
  final List<MailAttachment> attachments; // 🆕 TEK EKLEMEMİZ

  Mail({
    required this.id,
    required this.senderName,
    required this.subject,
    required this.content,
    required this.time,
    required this.isRead,
    required this.isStarred,
    this.isDeleted = false,
    this.attachments = const [], // 🆕 TEK EKLEMEMİZ
  });

  // 🆕 COMPUTED PROPERTIES - Ayrı field'lara gerek yok
  bool get hasAttachments => attachments.isNotEmpty;
  int get attachmentCount => attachments.length;

  // copyWith, toString, == operator aynı kalır + attachments eklenir
  Mail copyWith({
    String? id,
    String? senderName,
    String? subject,
    String? content,
    String? time,
    bool? isRead,
    bool? isStarred,
    bool? isDeleted,
    List<MailAttachment>? attachments,
  }) {
    return Mail(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      attachments: attachments ?? this.attachments,
    );
  }

  /// Checks if this mail is in trash (soft deleted)
  bool get isInTrash => isDeleted;

  /// Checks if this mail is active (not deleted)
  bool get isActive => !isDeleted;

  @override
  String toString() {
    return 'Mail(id: $id, senderName: $senderName, subject: $subject, isRead: $isRead, isStarred: $isStarred, isDeleted: $isDeleted, attachments: ${attachmentCount})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
