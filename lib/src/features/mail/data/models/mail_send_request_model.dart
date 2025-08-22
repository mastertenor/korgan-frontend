// lib/src/features/mail/data/models/mail_send_request_model.dart

import '../../domain/entities/mail_compose_request.dart';
import '../../domain/entities/mail_recipient.dart';
import '../../domain/entities/attachment_upload.dart';

/// Data model for mail send API request
///
/// This model converts domain entities to the exact JSON format
/// expected by the /api/sendmailrequest endpoint.
class MailSendRequestModel {
  final RecipientModel from;
  final List<RecipientModel> to;
  final List<RecipientModel>? cc;
  final List<RecipientModel>? bcc;
  final String subject;
  final String text;
  final String? html;
  final List<AttachmentModel>? attachments;
  final String? category;

  const MailSendRequestModel({
    required this.from,
    required this.to,
    required this.subject,
    required this.text,
    this.cc,
    this.bcc,
    this.html,
    this.attachments,
    this.category,
  });

  /// Create from domain entity
  factory MailSendRequestModel.fromDomain(MailComposeRequest request) {
    return MailSendRequestModel(
      from: RecipientModel.fromDomain(request.from),
      to: request.to.map((r) => RecipientModel.fromDomain(r)).toList(),
      cc: request.cc?.map((r) => RecipientModel.fromDomain(r)).toList(),
      bcc: request.bcc?.map((r) => RecipientModel.fromDomain(r)).toList(),
      subject: request.subject,
      text: request.text,
      html: request.html,
      attachments: request.attachments?.map((a) => AttachmentModel.fromDomain(a)).toList(),
      category: null, // Not implemented yet
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'from': from.toJson(),
      'to': to.map((r) => r.toJson()).toList(),
      'subject': subject,
      'text': text,
    };

    if (html != null && html!.isNotEmpty) {
      json['html'] = html;
    }

    if (cc != null && cc!.isNotEmpty) {
      json['cc'] = cc!.map((r) => r.toJson()).toList();
    }

    if (bcc != null && bcc!.isNotEmpty) {
      json['bcc'] = bcc!.map((r) => r.toJson()).toList();
    }

    if (attachments != null && attachments!.isNotEmpty) {
      json['attachments'] = attachments!.map((a) => a.toJson()).toList();
    }

    if (category != null) {
      json['category'] = category;
    }

    return json;
  }

  /// Create from JSON
  factory MailSendRequestModel.fromJson(Map<String, dynamic> json) {
    return MailSendRequestModel(
      from: RecipientModel.fromJson(json['from'] as Map<String, dynamic>),
      to: (json['to'] as List)
          .map((item) => RecipientModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subject: json['subject']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      cc: json['cc'] != null
          ? (json['cc'] as List)
              .map((item) => RecipientModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      bcc: json['bcc'] != null
          ? (json['bcc'] as List)
              .map((item) => RecipientModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      html: json['html']?.toString(),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((item) => AttachmentModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      category: json['category']?.toString(),
    );
  }

  @override
  String toString() {
    return 'MailSendRequestModel(from: ${from.email}, to: ${to.length} recipients, subject: $subject)';
  }
}

/// Recipient model for API requests
class RecipientModel {
  final String email;
  final String name;

  const RecipientModel({
    required this.email,
    required this.name,
  });

  /// Create from domain entity
  factory RecipientModel.fromDomain(MailRecipient recipient) {
    return RecipientModel(
      email: recipient.email,
      name: recipient.name,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
    };
  }

  /// Create from JSON
  factory RecipientModel.fromJson(Map<String, dynamic> json) {
    return RecipientModel(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'RecipientModel(email: $email, name: $name)';
  }
}

/// Attachment model for API requests
class AttachmentModel {
  final String content;
  final String type;
  final String filename;
  final String disposition;
  final String? contentId;

  const AttachmentModel({
    required this.content,
    required this.type,
    required this.filename,
    required this.disposition,
    this.contentId,
  });

  /// Create from domain entity
  factory AttachmentModel.fromDomain(AttachmentUpload attachment) {
    return AttachmentModel(
      content: attachment.content,
      type: attachment.type,
      filename: attachment.filename,
      disposition: attachment.disposition,
      contentId: attachment.contentId,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final json = {
      'content': content,
      'type': type,
      'filename': filename,
      'disposition': disposition,
    };

    // 🆕 Add Content-ID if present
    if (contentId != null && contentId!.isNotEmpty) {
      json['content_id'] = contentId!;
    }

    return json;
  }

  /// Create from JSON
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'application/octet-stream',
      filename: json['filename']?.toString() ?? 'attachment.bin',
      disposition: json['disposition']?.toString() ?? 'attachment',
      contentId: json['content_id']?.toString(),
    );
  }

  @override
  String toString() {
    return 'AttachmentModel(filename: $filename, type: $type, disposition: $disposition)';
  }
}