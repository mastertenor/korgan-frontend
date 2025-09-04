// lib/src/features/auth/domain/usecases/refresh_token_usecase.dart

import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing access token
///
/// Bu use case token refresh business logic'ini encapsulate eder.
/// Genellikle auth interceptor tarafından otomatik olarak çağrılır.
///
/// Business rules:
/// - Valid refresh token storage'da olmalı
/// - Yeni token'lar otomatik store edilir
/// - Refresh token rotation handle edilir
/// - Failed refresh durumunda false döner (logout trigger)
class RefreshTokenUseCase {
  final AuthRepository _repository;

  RefreshTokenUseCase(this._repository);

  /// Execute token refresh operation
  ///
  /// Returns Result with bool indicating success
  /// - true: Token successfully refreshed
  /// - false: Refresh failed (should trigger logout)
  Future<Result<bool>> execute() async {
    return await _repository.refreshToken();
  }
}
