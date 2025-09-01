// lib/src/features/mail/domain/entities/label_stats.dart

/// Domain entity for Gmail label statistics
///
/// Represents the count statistics for a specific Gmail label,
/// including total messages, unread count, and threading information.
class LabelStats {
  /// Label ID from Gmail API (e.g., 'INBOX', 'SENT', 'SPAM')
  final String id;

  /// Display name of the label
  final String name;

  /// Label type: 'system' or 'user'
  final String type;

  /// Total number of messages in this label
  final int messagesTotal;

  /// Number of unread messages in this label
  final int messagesUnread;

  /// Total number of threads in this label
  final int threadsTotal;

  /// Number of unread threads in this label
  final int threadsUnread;

  const LabelStats({
    required this.id,
    required this.name,
    required this.type,
    required this.messagesTotal,
    required this.messagesUnread,
    required this.threadsTotal,
    required this.threadsUnread,
  });

  /// Create empty stats for fallback scenarios
  factory LabelStats.empty(String labelId) {
    return LabelStats(
      id: labelId,
      name: labelId,
      type: 'system',
      messagesTotal: 0,
      messagesUnread: 0,
      threadsTotal: 0,
      threadsUnread: 0,
    );
  }

  /// Check if label has any unread messages
  bool get hasUnreadMessages => messagesUnread > 0;

  /// Check if label has any messages at all
  bool get hasMessages => messagesTotal > 0;

  /// Get formatted display text for UI badge (e.g., "116/17570")
  String get badgeText => '$messagesUnread/$messagesTotal';

  /// Get short badge text (only unread count when > 0)
  String get shortBadgeText => messagesUnread > 0 ? '$messagesUnread' : '';

  /// Create copy with updated values
  LabelStats copyWith({
    String? id,
    String? name,
    String? type,
    int? messagesTotal,
    int? messagesUnread,
    int? threadsTotal,
    int? threadsUnread,
  }) {
    return LabelStats(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      messagesTotal: messagesTotal ?? this.messagesTotal,
      messagesUnread: messagesUnread ?? this.messagesUnread,
      threadsTotal: threadsTotal ?? this.threadsTotal,
      threadsUnread: threadsUnread ?? this.threadsUnread,
    );
  }

  @override
  String toString() {
    return 'LabelStats(id: $id, name: $name, messagesTotal: $messagesTotal, messagesUnread: $messagesUnread)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabelStats &&
        other.id == id &&
        other.messagesTotal == messagesTotal &&
        other.messagesUnread == messagesUnread;
  }

  @override
  int get hashCode => Object.hash(id, messagesTotal, messagesUnread);
}
