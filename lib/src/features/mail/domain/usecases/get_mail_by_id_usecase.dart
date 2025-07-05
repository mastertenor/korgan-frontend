// lib/src/features/mail/domain/usecases/get_mail_by_id_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../entities/mail.dart';
import '../repositories/mail_repository.dart';

/// Use case for getting a single email by ID
///
/// This use case encapsulates the business logic for fetching a specific email.
/// It validates input parameters and coordinates with the repository.
class GetMailByIdUseCase {
  final MailRepository _repository;

  GetMailByIdUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] - Parameters for getting email by ID
  ///
  /// Returns a Result containing either a Mail entity or a Failure
  Future<Result<Mail>> call(GetMailByIdParams params) async {
    // Validate parameters
    if (!_isValidParams(params)) {
      return Failure(_getValidationFailure(params));
    }

    // Call repository
    return await _repository.getMailById(id: params.id, email: params.email);
  }

  /// Validate parameters
  bool _isValidParams(GetMailByIdParams params) {
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

  /// Get validation failure with context
  failures.Failure _getValidationFailure(GetMailByIdParams params) {
    if (params.id.isEmpty) {
      return failures.ValidationFailure.requiredField('E-posta ID');
    }

    if (params.email.isEmpty) {
      return failures.ValidationFailure.requiredField('E-posta adresi');
    }

    if (!_isValidEmail(params.email)) {
      return failures.ValidationFailure.invalidEmail(email: params.email);
    }

    return failures.ValidationFailure(
      message: 'Geçersiz parametreler',
      code: 'INVALID_PARAMS',
    );
  }
}

/// Parameters for GetMailByIdUseCase
class GetMailByIdParams {
  final String id;
  final String email;

  const GetMailByIdParams({required this.id, required this.email});

  @override
  String toString() {
    return 'GetMailByIdParams(id: $id, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMailByIdParams && other.id == id && other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, email);
}
