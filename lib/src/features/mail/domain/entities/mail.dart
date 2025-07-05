// lib/src/features/mail/domain/entities/mail.dart

/// Mail domain entity representing a mail item in the system
///
/// This entity contains the core business data for a mail item
/// and is platform-agnostic. Used across the entire mail feature.
class Mail {
  final String id; // Unique mail ID from Gmail API
  final String senderName;
  final String subject;
  final String content;
  final String time;
  bool isRead;
  bool isStarred;
  bool isDeleted;

  Mail({
    required this.id,
    required this.senderName,
    required this.subject,
    required this.content,
    required this.time,
    required this.isRead,
    required this.isStarred,
    this.isDeleted = false, // Default to false (not deleted)
  });

  /// Creates a copy of this mail with updated properties
  Mail copyWith({
    String? id,
    String? senderName,
    String? subject,
    String? content,
    String? time,
    bool? isRead,
    bool? isStarred,
    bool? isDeleted,
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
    );
  }

  /// Checks if this mail is in trash (soft deleted)
  bool get isInTrash => isDeleted;

  /// Checks if this mail is active (not deleted)
  bool get isActive => !isDeleted;

  @override
  String toString() {
    return 'Mail(id: $id, senderName: $senderName, subject: $subject, isRead: $isRead, isStarred: $isStarred, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
