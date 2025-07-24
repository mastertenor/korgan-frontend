// lib/src/features/mail/domain/entities/mail_compose_request.dart

import 'mail_recipient.dart';
import 'attachment_upload.dart';

/// Mail compose request entity for sending emails
///
/// Represents a complete email composition request that will be sent to
/// the /api/sendmailrequest endpoint. Includes all necessary fields
/// and supports draft functionality for future use.
class MailComposeRequest {
  /// Sender information
  final MailRecipient from;

  /// Primary recipients (required)
  final List<MailRecipient> to;

  /// Carbon copy recipients (optional)
  final List<MailRecipient>? cc;

  /// Blind carbon copy recipients (optional)
  final List<MailRecipient>? bcc;

  /// Email subject
  final String subject;

  /// Plain text content
  final String text;

  /// HTML content (optional, takes precedence over text)
  final String? html;

  /// File attachments (optional)
  final List<AttachmentUpload>? attachments;

  // ========== DRAFT SUPPORT (for future use) ==========

  /// Whether this is a draft (not sent)
  final bool isDraft;

  /// Draft ID for updating existing drafts
  final String? draftId;

  /// Auto-save timestamp for drafts
  final DateTime? lastSaved;

  const MailComposeRequest({
    required this.from,
    required this.to,
    required this.subject,
    required this.text,
    this.cc,
    this.bcc,
    this.html,
    this.attachments,
    this.isDraft = false,
    this.draftId,
    this.lastSaved,
  });

  /// Create a new compose request for sending
  factory MailComposeRequest.forSend({
    required MailRecipient from,
    required List<MailRecipient> to,
    required String subject,
    required String text,
    List<MailRecipient>? cc,
    List<MailRecipient>? bcc,
    String? html,
    List<AttachmentUpload>? attachments,
  }) {
    return MailComposeRequest(
      from: from,
      to: to,
      subject: subject,
      text: text,
      cc: cc,
      bcc: bcc,
      html: html,
      attachments: attachments,
      isDraft: false,
    );
  }

  /// Create a draft request for saving
  factory MailComposeRequest.forDraft({
    required MailRecipient from,
    required List<MailRecipient> to,
    required String subject,
    required String text,
    List<MailRecipient>? cc,
    List<MailRecipient>? bcc,
    String? html,
    List<AttachmentUpload>? attachments,
    String? draftId,
  }) {
    return MailComposeRequest(
      from: from,
      to: to,
      subject: subject,
      text: text,
      cc: cc,
      bcc: bcc,
      html: html,
      attachments: attachments,
      isDraft: true,
      draftId: draftId,
      lastSaved: DateTime.now(),
    );
  }

  /// Convert to JSON format for API request
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'from': from.toJson(),
      'to': to.map((recipient) => recipient.toJson()).toList(),
      'subject': subject,
      'text': text,
    };

    // Add optional fields
    if (html != null && html!.isNotEmpty) {
      json['html'] = html;
    }

    if (cc != null && cc!.isNotEmpty) {
      json['cc'] = cc!.map((recipient) => recipient.toJson()).toList();
    }

    if (bcc != null && bcc!.isNotEmpty) {
      json['bcc'] = bcc!.map((recipient) => recipient.toJson()).toList();
    }

    if (attachments != null && attachments!.isNotEmpty) {
      json['attachments'] = attachments!.map((attachment) => attachment.toJson()).toList();
    }

    // Draft fields (for future use)
    if (isDraft) {
      json['is_draft'] = true;
      if (draftId != null) json['draft_id'] = draftId;
    }

    return json;
  }

  /// Create from JSON
  factory MailComposeRequest.fromJson(Map<String, dynamic> json) {
    return MailComposeRequest(
      from: MailRecipient.fromJson(json['from'] as Map<String, dynamic>),
      to: (json['to'] as List)
          .map((item) => MailRecipient.fromJson(item as Map<String, dynamic>))
          .toList(),
      subject: json['subject']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      cc: json['cc'] != null
          ? (json['cc'] as List)
              .map((item) => MailRecipient.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      bcc: json['bcc'] != null
          ? (json['bcc'] as List)
              .map((item) => MailRecipient.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      html: json['html']?.toString(),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((item) => AttachmentUpload.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      isDraft: json['is_draft'] == true,
      draftId: json['draft_id']?.toString(),
    );
  }

  /// Get all recipients (to + cc + bcc)
  List<MailRecipient> get allRecipients {
    final all = <MailRecipient>[...to];
    if (cc != null) all.addAll(cc!);
    if (bcc != null) all.addAll(bcc!);
    return all;
  }

  /// Get total recipient count
  int get recipientCount => allRecipients.length;

  /// Check if request has attachments
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  /// Get total attachment count
  int get attachmentCount => attachments?.length ?? 0;

  /// Get total estimated size of all attachments
  int get totalAttachmentSize {
    if (!hasAttachments) return 0;
    return attachments!
        .map((attachment) => attachment.estimatedSizeBytes)
        .reduce((a, b) => a + b);
  }

  /// Get formatted total attachment size
  String get totalAttachmentSizeFormatted {
    final size = totalAttachmentSize;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Check if request is valid for sending
  bool get isValid {
    return from.email.isNotEmpty &&
           to.isNotEmpty &&
           to.every((recipient) => recipient.email.isNotEmpty) &&
           subject.isNotEmpty &&
           (text.isNotEmpty || (html != null && html!.isNotEmpty));
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (from.email.isEmpty) {
      errors.add('Gönderen email adresi gerekli');
    }

    if (to.isEmpty) {
      errors.add('En az bir alıcı gerekli');
    }

    if (to.any((recipient) => recipient.email.isEmpty)) {
      errors.add('Tüm alıcı email adresleri geçerli olmalı');
    }

    if (subject.isEmpty) {
      errors.add('Konu satırı gerekli');
    }

    if (text.isEmpty && (html == null || html!.isEmpty)) {
      errors.add('Email içeriği gerekli');
    }

    return errors;
  }

  /// Copy with updated values
  MailComposeRequest copyWith({
    MailRecipient? from,
    List<MailRecipient>? to,
    List<MailRecipient>? cc,
    List<MailRecipient>? bcc,
    String? subject,
    String? text,
    String? html,
    List<AttachmentUpload>? attachments,
    bool? isDraft,
    String? draftId,
    DateTime? lastSaved,
  }) {
    return MailComposeRequest(
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      text: text ?? this.text,
      html: html ?? this.html,
      attachments: attachments ?? this.attachments,
      isDraft: isDraft ?? this.isDraft,
      draftId: draftId ?? this.draftId,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailComposeRequest &&
           other.from == from &&
           other.subject == subject &&
           other.text == text &&
           other.isDraft == isDraft;
  }

  @override
  int get hashCode => Object.hash(from, subject, text, isDraft);

  @override
  String toString() {
    return 'MailComposeRequest('
           'from: ${from.email}, '
           'to: ${to.length} recipients, '
           'subject: $subject, '
           'attachments: $attachmentCount, '
           'isDraft: $isDraft'
           ')';
  }
}