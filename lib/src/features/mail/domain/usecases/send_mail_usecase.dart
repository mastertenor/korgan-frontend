// lib/src/features/mail/domain/usecases/send_mail_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../entities/mail_compose_request.dart';
import '../entities/compose_result.dart';
import '../entities/mail_recipient.dart';
import '../repositories/mail_repository.dart';

/// Use case for sending emails with validation and business logic
///
/// This use case handles the complete email sending flow including:
/// - Input validation (email formats, required fields, limits)
/// - Business rule enforcement (attachment size, recipient count)
/// - Repository coordination
/// - Error handling and user-friendly messaging
class SendMailUseCase {
  final MailRepository _repository;

  SendMailUseCase(this._repository);

  /// Execute the send mail use case
  ///
  /// [params] - Parameters containing the mail compose request
  ///
  /// Returns a Result containing either a ComposeResult or a Failure
  Future<Result<ComposeResult>> call(SendMailParams params) async {
    // 1. Validate the request
    final validation = _validateRequest(params.request);
    if (validation != null) {
      return Failure(validation);
    }

    // 2. Check business rules
    final businessRuleCheck = _checkBusinessRules(params.request);
    if (businessRuleCheck != null) {
      return Failure(businessRuleCheck);
    }

    // 3. Call repository to send mail
    return await _repository.sendMail(params.request);
  }

  /// Validate the mail compose request
  ///
  /// Returns null if validation passes, or a Failure if validation fails
  failures.Failure? _validateRequest(MailComposeRequest request) {
    // Check basic validation from entity
    if (!request.isValid) {
      final errors = request.validationErrors;
      return failures.ValidationFailure(
        message: 'Mail gönderilemedi: ${errors.join(', ')}',
        code: 'INVALID_REQUEST',
        details: {'validation_errors': errors},
      );
    }

    // Validate sender email format
    if (!_isValidEmail(request.from.email)) {
      return failures.ValidationFailure.invalidEmail(
        email: request.from.email,
        
      );
    }

    // Validate all recipient email formats
    for (final recipient in request.allRecipients) {
      if (!_isValidEmail(recipient.email)) {
        return failures.ValidationFailure.invalidEmail(
          email: recipient.email,
        
        );
      }
    }

    return null; // Validation passed
  }

  /// Check business rules and limits
  ///
  /// Returns null if all rules pass, or a Failure if any rule fails
  failures.Failure? _checkBusinessRules(MailComposeRequest request) {
    // 1. Check recipient count limit (max 42)
    if (request.recipientCount > 42) {
      return failures.ValidationFailure(
        message: 'En fazla 42 alıcıya mail gönderebilirsiniz. Şu anda: ${request.recipientCount}',
        code: 'TOO_MANY_RECIPIENTS',
        details: {'max_recipients': 42, 'current_count': request.recipientCount},
      );
    }

    // 2. Check subject length (ideal range: 10-78 characters)
    if (request.subject.length > 100) {
      return failures.ValidationFailure(
        message: 'Konu satırı çok uzun. Maksimum 100 karakter olmalı.',
        code: 'SUBJECT_TOO_LONG',
        details: {'max_length': 100, 'current_length': request.subject.length},
      );
    }

    if (request.subject.length < 3) {
      return failures.ValidationFailure(
        message: 'Konu satırı çok kısa. En az 3 karakter olmalı.',
        code: 'SUBJECT_TOO_SHORT',
        details: {'min_length': 3, 'current_length': request.subject.length},
      );
    }

    // 3. Check total attachment size (max 25MB)
    if (request.hasAttachments) {
      final totalSizeMB = request.totalAttachmentSize / (1024 * 1024);
      const maxSizeMB = 25;

      if (totalSizeMB > maxSizeMB) {
        return failures.ValidationFailure(
          message: 'Toplam ek dosya boyutu ${maxSizeMB}MB\'ı geçemez. '
                   'Şu anki boyut: ${request.totalAttachmentSizeFormatted}',
          code: 'ATTACHMENTS_TOO_LARGE',
          details: {
            'max_size_mb': maxSizeMB,
            'current_size_mb': totalSizeMB.toStringAsFixed(2),
            'attachment_count': request.attachmentCount,
          },
        );
      }

      // 4. Validate attachment content
      for (final attachment in request.attachments!) {
        if (!attachment.hasValidContent) {
          return failures.ValidationFailure(
            message: 'Ek dosya "${attachment.filename}" geçersiz veya bozuk.',
            code: 'INVALID_ATTACHMENT',
            details: {'filename': attachment.filename},
          );
        }
      }
    }

    // 5. Check content requirements
    final hasText = request.text.trim().isNotEmpty;
    final hasHtml = request.html != null && request.html!.trim().isNotEmpty;

    if (!hasText && !hasHtml) {
      return failures.ValidationFailure(
        message: 'Mail içeriği boş olamaz. Lütfen mesajınızı yazın.',
        code: 'EMPTY_CONTENT',
      );
    }

    return null; // All business rules passed
  }

  /// Validate email format using regex
  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Get human-readable validation summary
  ///
  /// Useful for displaying validation status to users
  String getValidationSummary(MailComposeRequest request) {
    final issues = <String>[];

    // Check basic issues
    if (!request.isValid) {
      issues.addAll(request.validationErrors);
    }

    // Check business rules
    if (request.recipientCount > 42) {
      issues.add('Çok fazla alıcı (${request.recipientCount}/42)');
    }

    if (request.subject.length > 100) {
      issues.add('Konu çok uzun (${request.subject.length}/100)');
    }

    if (request.hasAttachments) {
      final sizeMB = request.totalAttachmentSize / (1024 * 1024);
      if (sizeMB > 25) {
        issues.add('Ekler çok büyük (${sizeMB.toStringAsFixed(1)}/25 MB)');
      }
    }

    if (issues.isEmpty) {
      return '✅ Mail gönderilmeye hazır';
    } else {
      return '⚠️ Sorunlar: ${issues.join(', ')}';
    }
  }
}

/// Parameters for send mail use case
class SendMailParams {
  /// The complete mail compose request
  final MailComposeRequest request;

  const SendMailParams({
    required this.request,
  });

  /// Create params from individual components (convenience method)
  factory SendMailParams.create({
    required String fromEmail,
    required String fromName,
    required List<String> toEmails,
    required String subject,
    required String content,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? htmlContent,
  }) {
    final request = MailComposeRequest.forSend(
      from: MailRecipient(email: fromEmail, name: fromName),
      to: toEmails.map((email) => MailRecipient.fromEmail(email)).toList(),
      subject: subject,
      text: content,
      cc: ccEmails?.map((email) => MailRecipient.fromEmail(email)).toList(),
      bcc: bccEmails?.map((email) => MailRecipient.fromEmail(email)).toList(),
      html: htmlContent,
    );

    return SendMailParams(request: request);
  }

  @override
  String toString() {
    return 'SendMailParams(from: ${request.from.email}, '
           'to: ${request.to.length} recipients, '
           'subject: "${request.subject}")';
  }
}