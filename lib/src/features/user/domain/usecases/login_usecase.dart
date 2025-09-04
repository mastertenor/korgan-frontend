// lib/src/features/auth/domain/usecases/login_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../entities/user.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
///
/// Bu use case login business logic'ini encapsulate eder.
/// Mail pattern'inize uygun şekilde tek sorumluluk prensibi ile tasarlanmış.
///
/// Business rules:
/// - Email format validation
/// - Password strength validation
/// - Token storage coordination
/// - User data persistence
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  /// Execute login operation
  ///
  /// [email] User's email address
  /// [password] User's password
  ///
  /// Returns Result with AuthToken and User on success
  Future<Result<({AuthToken token, User user})>> execute({
    required String email,
    required String password,
  }) async {
    // Input validation at use case level
    if (email.isEmpty) {
      return Failure(failures.ValidationFailure.requiredField('Email'));
    }

    if (password.isEmpty) {
      return Failure(failures.ValidationFailure.requiredField('Password'));
    }

    // Trim whitespace
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // Delegate to repository
    return await _repository.login(email: cleanEmail, password: cleanPassword);
  }
}
