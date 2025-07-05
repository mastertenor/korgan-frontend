// lib/src/features/mail/domain/usecases/mail_actions_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';

/// Use case for mail actions (mark as read, delete, star, trash operations, etc.)
///
/// This use case encapsulates the business logic for mail operations.
/// It validates input parameters and coordinates with the repository.
class MailActionsUseCase {
  final MailRepository _repository;

  MailActionsUseCase(this._repository);

  /// Mark email as read
  Future<Result<void>> markAsRead(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.markAsRead(id: params.id, email: params.email);
  }

  /// Mark email as unread
  Future<Result<void>> markAsUnread(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.markAsUnread(id: params.id, email: params.email);
  }

  /// Move email to trash (soft delete)
  Future<Result<void>> moveToTrash(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.moveToTrash(id: params.id, email: params.email);
  }

  /// Restore email from trash
  Future<Result<void>> restoreFromTrash(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.restoreFromTrash(
      id: params.id,
      email: params.email,
    );
  }

  /// Permanently delete email (hard delete)
  Future<Result<void>> deleteMail(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.deleteMail(id: params.id, email: params.email);
  }

  /// Empty trash (permanently delete all emails in trash)
  Future<Result<void>> emptyTrash(EmptyTrashParams params) async {
    if (!_isValidEmail(params.email)) {
      return Failure(
        failures.ValidationFailure.invalidEmail(email: params.email),
      );
    }

    return await _repository.emptyTrash(email: params.email);
  }

  /// Archive email
  Future<Result<void>> archiveMail(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.archiveMail(id: params.id, email: params.email);
  }

  /// Star email
  Future<Result<void>> starMail(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.starMail(id: params.id, email: params.email);
  }

  /// Unstar email
  Future<Result<void>> unstarMail(MailActionParams params) async {
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure());
    }

    return await _repository.unstarMail(id: params.id, email: params.email);
  }

  /// Validate parameters
  bool _isValidParams(MailActionParams params) {
    return params.id.isNotEmpty &&
        params.email.isNotEmpty &&
        _isValidEmail(params.email);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Get validation failure
  failures.Failure _getValidationFailure() {
    return failures.ValidationFailure(
      message: 'Geçersiz e-posta ID\'si veya e-posta adresi',
      code: 'INVALID_MAIL_PARAMS',
    );
  }
}

/// Parameters for mail actions
class MailActionParams {
  final String id;
  final String email;

  const MailActionParams({required this.id, required this.email});

  @override
  String toString() {
    return 'MailActionParams(id: $id, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailActionParams && other.id == id && other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, email);
}

/// Parameters for empty trash operation
class EmptyTrashParams {
  final String email;

  const EmptyTrashParams({required this.email});

  @override
  String toString() {
    return 'EmptyTrashParams(email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmptyTrashParams && other.email == email;
  }

  @override
  int get hashCode => email.hashCode;
}
