// lib/src/features/auth/domain/usecases/get_current_user_usecase.dart

import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting current authenticated user
///
/// Bu use case mevcut kullanıcı bilgilerini getirme business logic'ini encapsulate eder.
///
/// Business rules:
/// - Valid access token gerekli
/// - Başarılı durumda user data storage güncellenir
/// - 401 durumunda auto-refresh attempt yapılabilir (interceptor seviyesinde)
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Execute get current user operation
  ///
  /// Returns Result with User on success
  Future<Result<User>> execute() async {
    return await _repository.getCurrentUser();
  }
}
