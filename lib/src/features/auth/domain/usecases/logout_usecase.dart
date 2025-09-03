// lib/src/features/auth/domain/usecases/logout_usecase.dart

import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for user logout
///
/// Bu use case logout business logic'ini encapsulate eder.
///
/// Business rules:
/// - Her zaman başarılı olur (server hatası olsa bile)
/// - Önce local storage temizlenir
/// - Sonra server'a logout isteği gönderilir (best effort)
/// - Auth interceptor'lar temizlenir
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  /// Execute logout operation
  ///
  /// Always succeeds - even if server call fails,
  /// local logout is considered successful
  Future<Result<void>> execute() async {
    return await _repository.logout();
  }
}
