// lib/src/features/mail/domain/usecases/download_attachment_usecase.dart

import 'dart:typed_data';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';

/// Use case for downloading email attachments
///
/// This use case handles the business logic for downloading attachments
/// from emails, including validation and error handling.
class DownloadAttachmentUseCase {
  final MailRepository _repository;

  DownloadAttachmentUseCase(this._repository);

  /// Execute the download attachment use case
  ///
  /// [messageId] - Gmail message ID containing the attachment
  /// [attachmentId] - Unique attachment identifier
  /// [filename] - Original filename of the attachment
  /// [email] - User's email address
  /// [mimeType] - Optional MIME type of the attachment
  ///
  /// Returns a Result containing either the attachment bytes or a Failure
  Future<Result<Uint8List>> call({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
    String? mimeType,
  }) async {
    // Validate parameters
    final validation = _validateParams(
      messageId: messageId,
      attachmentId: attachmentId,
      filename: filename,
      email: email,
    );

    if (validation != null) {
      return Failure(validation);
    }

    // Call repository to download attachment
    return await _repository.downloadAttachment(
      messageId: messageId,
      attachmentId: attachmentId,
      filename: filename,
      email: email,
      mimeType: mimeType,
    );
  }

  /// Validate input parameters
  failures.Failure? _validateParams({
    required String messageId,
    required String attachmentId,
    required String filename,
    required String email,
  }) {
    if (messageId.isEmpty) {
      return failures.ValidationFailure(
        message: 'Message ID cannot be empty',
        code: 'INVALID_MESSAGE_ID',
      );
    }

    if (attachmentId.isEmpty) {
      return failures.ValidationFailure(
        message: 'Attachment ID cannot be empty',
        code: 'INVALID_ATTACHMENT_ID',
      );
    }

    if (filename.isEmpty) {
      return failures.ValidationFailure(
        message: 'Filename cannot be empty',
        code: 'INVALID_FILENAME',
      );
    }

    if (email.isEmpty) {
      return failures.ValidationFailure(
        message: 'Email cannot be empty',
        code: 'INVALID_EMAIL',
      );
    }

    // Basic email validation
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return failures.ValidationFailure(
        message: 'Invalid email format',
        code: 'INVALID_EMAIL_FORMAT',
      );
    }

    return null; // No validation errors
  }
}
