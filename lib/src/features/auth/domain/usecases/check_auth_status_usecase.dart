// lib/src/features/auth/domain/usecases/check_auth_status_usecase.dart

import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking authentication status
///
/// Bu use case kullanıcının auth durumunu kontrol etme business logic'ini encapsulate eder.
/// App startup'ta veya periodic auth check'lerde kullanılır.
///
/// Business rules:
/// - Local storage önce kontrol edilir
/// - Token validity check yapılır
/// - Invalid token'lar otomatik temizlenir
/// - Network bağımsız çalışır (önce local check)
class CheckAuthStatusUseCase {
  final AuthRepository _repository;

  CheckAuthStatusUseCase(this._repository);

  /// Execute authentication status check
  ///
  /// Returns Result with bool indicating if user is authenticated
  /// - true: User is authenticated with valid tokens
  /// - false: User is not authenticated or tokens are invalid
  Future<Result<bool>> execute() async {
    return await _repository.isAuthenticated();
  }
}
