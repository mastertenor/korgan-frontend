// lib/src/features/mail/data/models/mail_response_model.dart

import 'mail_model.dart';

/// Simple model for Gmail API list response - Gmail mobile style
class MailResponseModel {
  final List<MailModel> messages;
  final String? nextPageToken;
  final int resultSizeEstimate;

  const MailResponseModel({
    required this.messages,
    this.nextPageToken,
    required this.resultSizeEstimate,
  });

  /// Create from JSON
  factory MailResponseModel.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List? ?? [];
    final messages = messagesList
        .map(
          (messageJson) =>
              MailModel.fromJson(messageJson as Map<String, dynamic>),
        )
        .toList();

    return MailResponseModel(
      messages: messages,
      nextPageToken: json['nextPageToken'] as String?,
      resultSizeEstimate: json['resultSizeEstimate'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((m) => m.toJson()).toList(),
      'nextPageToken': nextPageToken,
      'resultSizeEstimate': resultSizeEstimate,
    };
  }

  /// Check if has more pages (older emails)
  bool get hasNextPage => nextPageToken != null && nextPageToken!.isNotEmpty;

  /// Check if empty
  bool get isEmpty => messages.isEmpty;

  /// Get message count
  int get messageCount => messages.length;

  /// Get unread count
  int get unreadCount => messages.where((mail) => mail.isUnread).length;

  /// Create empty response
  factory MailResponseModel.empty() {
    return const MailResponseModel(messages: [], resultSizeEstimate: 0);
  }

  @override
  String toString() {
    return 'MailResponseModel(messages: ${messages.length}, hasNextPage: $hasNextPage)';
  }
}
