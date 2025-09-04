// lib/src/features/auth/presentation/providers/auth_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../utils/app_logger.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../state/auth_state.dart';

/// Authentication state notifier with stream support for GoRouter refresh
///
/// Bu notifier mevcut mail pattern'inize uygun şekilde tasarlandı.
/// StateNotifier pattern with use cases for business logic.
/// 🆕 ADDED: Stream support for GoRouter refreshListenable pattern
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final ApiClient _apiClient;

  /// 🆕 Stream controller for GoRouter refresh notifications
  final StreamController<AuthState> _streamController =
      StreamController<AuthState>.broadcast();

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required ApiClient apiClient,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _refreshTokenUseCase = refreshTokenUseCase,
       _apiClient = apiClient,
       super(AuthState.initial());

  /// 🆕 Stream for GoRouter refreshListenable
  /// Bu stream auth state değişikliklerini GoRouter'a bildirir
  Stream<AuthState> get stream => _streamController.stream;

  /// 🆕 Override state setter to emit stream events
  @override
  set state(AuthState newState) {
    final oldState = state;
    super.state = newState;

    // Sadece önemli state değişikliklerinde stream emit et
    if (_shouldEmitStreamEvent(oldState, newState)) {
      AppLogger.debug('Auth: State changed - emitting stream event');
      _streamController.add(newState);
    }
  }

  /// 🆕 Determine if state change should trigger GoRouter refresh
  bool _shouldEmitStreamEvent(AuthState oldState, AuthState newState) {
    // Auth status değişikliklerinde refresh tetikle
    if (oldState.status != newState.status) {
      return true;
    }

    // Loading state değişikliklerinde refresh tetikleme
    // (Çok fazla refresh'e sebep olur)
    return false;
  }

  // ========== PUBLIC AUTH METHODS ==========

  /// Login with email and password
  Future<void> login({required String email, required String password}) async {
    if (state.isLoggingIn) {
      AppLogger.warning(
        'Login already in progress, ignoring duplicate request',
      );
      return;
    }

    AppLogger.info('Auth: Login attempt for $email');
    state = state.copyWithLoggingIn();

    try {
      final result = await _loginUseCase.execute(
        email: email,
        password: password,
      );

      result.when(
        success: (data) {
          AppLogger.info('Auth: Login successful for $email');

          // Update state with authenticated user
          state = state.copyWithAuthenticated(
            user: data.user,
            token: data.token,
          );

          // Initialize auth interceptor for automatic token handling
          _initializeAuthInterceptor();
        },
        failure: (failure) {
          AppLogger.error('Auth: Login failed - ${failure.message}');
          state = state.copyWithError(failure.message);
        },
      );
    } catch (e) {
      AppLogger.error('Auth: Login unexpected error - $e');
      state = state.copyWithError('Giriş yapılırken beklenmeyen hata oluştu');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (state.isLoggingOut) {
      AppLogger.warning(
        'Logout already in progress, ignoring duplicate request',
      );
      return;
    }

    AppLogger.info('Auth: Logout attempt');
    state = state.copyWithLoggingOut();

    try {
      // Remove auth interceptor first
      _removeAuthInterceptor();

      final result = await _logoutUseCase.execute();

      result.when(
        success: (_) {
          AppLogger.info('Auth: Logout successful');
          state = state.copyWithUnauthenticated();
        },
        failure: (failure) {
          // Even on failure, logout locally
          AppLogger.warning(
            'Auth: Server logout failed but local logout successful - ${failure.message}',
          );
          state = state.copyWithUnauthenticated();
        },
      );
    } catch (e) {
      // Even on error, logout locally
      AppLogger.warning('Auth: Logout error but local logout successful - $e');
      state = state.copyWithUnauthenticated();
    }
  }

  /// Check current authentication status
/// Check current authentication status  
Future<void> checkAuthStatus() async {
    if (state.isCheckingAuth) {
      return;
    }

    AppLogger.info('Auth: Checking authentication status');
    state = state.copyWithCheckingAuth();

    try {
      final result = await _checkAuthStatusUseCase.execute();

      result.when(
        success: (isAuthenticated) async {
          if (isAuthenticated) {
            AppLogger.info('Auth: User is authenticated - fetching profile');

            // ✅ DÜZELTME: Her zaman interceptor kurulumunu kontrol et
            if (!_apiClient.hasAuthInterceptor) {
              AppLogger.info('DEBUG: Setting up auth interceptor...');
              _initializeAuthInterceptor();
              AppLogger.info(
                'DEBUG: Auth interceptor setup completed: ${_apiClient.hasAuthInterceptor}',
              );
            } else {
              AppLogger.info('DEBUG: Auth interceptor already exists');
            }

            await _fetchCurrentUser();
          } else {
            AppLogger.info('Auth: User is not authenticated');
            state = state.copyWithUnauthenticated();
          }
        },
        failure: (failure) {
          AppLogger.error(
            'Auth: Auth status check failed - ${failure.message}',
          );
          state = state.copyWithUnauthenticated();
        },
      );
    } catch (e) {
      AppLogger.error('Auth: Auth status check unexpected error - $e');
      state = state.copyWithUnauthenticated();
    }
  }
  
    /// Refresh user profile data
  Future<void> refreshUserProfile() async {
    if (!state.isAuthenticated) {
      AppLogger.warning(
        'Auth: Cannot refresh profile - user not authenticated',
      );
      return;
    }

    AppLogger.info('Auth: Refreshing user profile');

    try {
      final result = await _getCurrentUserUseCase.execute();

      result.when(
        success: (user) {
          AppLogger.info('Auth: User profile refreshed successfully');
          state = state.copyWith(user: user);
        },
        failure: (failure) {
          AppLogger.error('Auth: Profile refresh failed - ${failure.message}');

          // If auth failure, logout user
          if (failure is failures.AuthFailure) {
            AppLogger.warning(
              'Auth: Profile refresh requires re-authentication - logging out',
            );
            logout();
          }
        },
      );
    } catch (e) {
      AppLogger.error('Auth: Profile refresh unexpected error - $e');
    }
  }

  /// Refresh access token (usually called by interceptor)
  Future<bool> refreshToken() async {
    if (state.isRefreshingToken) {
      AppLogger.warning('Token refresh already in progress');
      return false;
    }

    AppLogger.info('Auth: Refreshing access token');
    state = state.copyWithRefreshingToken();

    try {
      final result = await _refreshTokenUseCase.execute();

      return result.when(
        success: (success) {
          if (success) {
            AppLogger.info('Auth: Token refresh successful');
            state = state.copyWithLoadingComplete();
            return true;
          } else {
            AppLogger.error('Auth: Token refresh failed');
            state = state.copyWithError('Token yenilenemedi');
            return false;
          }
        },
        failure: (failure) {
          AppLogger.error('Auth: Token refresh failed - ${failure.message}');
          state = state.copyWithError(failure.message);
          return false;
        },
      );
    } catch (e) {
      AppLogger.error('Auth: Token refresh unexpected error - $e');
      state = state.copyWithError('Token yenileme sırasında hata oluştu');
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      AppLogger.debug('Auth: Clearing error state');
      state = state.copyWith(clearError: true);
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  /// Fetch current user profile
  Future<void> _fetchCurrentUser() async {
    try {
      final result = await _getCurrentUserUseCase.execute();

      result.when(
        success: (user) {
          AppLogger.info('Auth: Current user fetched successfully');
          // Create token placeholder - actual token is in storage
          final token = AuthToken.empty(); // We don't expose actual tokens

          state = state.copyWithAuthenticated(user: user, token: token);
        },
        failure: (failure) {
          AppLogger.error(
            'Auth: Failed to fetch current user - ${failure.message}',
          );
          state = state.copyWithError(failure.message);
        },
      );
    } catch (e) {
      AppLogger.error('Auth: Fetch current user unexpected error - $e');
      state = state.copyWith(
        error: 'Kullanıcı bilgileri alınırken hata oluştu',
        isCheckingAuth: false,
        // status ve user değişmesin - auth durumu korunsun
      );
    }
  }

  /// Initialize auth interceptor for automatic token handling
void _initializeAuthInterceptor() {
    AppLogger.info('Auth: Initializing auth interceptor');

    // ✅ Debug: Mevcut interceptor durumunu kontrol et
    final currentStats = _apiClient.hasAuthInterceptor;
    AppLogger.info('Auth: Current interceptor status: $currentStats');

    // ✅ Auth interceptor'ı doğru callback'lerle ekle
    _apiClient.addAuthInterceptor(
      refreshTokenCallback: () async {
        AppLogger.info('🔄 INTERCEPTOR: Refresh callback triggered!');
        try {
          final result = await _refreshTokenUseCase.execute();
          final success = result.isSuccess;
          AppLogger.info('🔄 INTERCEPTOR: Refresh result: $success');

          // ✅ State'i güncelle
          if (!success) {
            AppLogger.warning(
              '🔄 INTERCEPTOR: Token refresh failed, will logout',
            );
            // State'i güncelle ama logout'u callback'e bırak
            state = state.copyWithError('Token yenilenemedi');
          }

          return success;
        } catch (e) {
          AppLogger.error('🔄 INTERCEPTOR: Refresh callback error: $e');
          state = state.copyWithError('Token yenileme hatası');
          return false;
        }
      },
      onTokenRefreshFailed: () {
        AppLogger.warning('Auth: Token refresh failed - logging out user');
        // ✅ Async işlemi sync callback'te güvenli şekilde çalıştır
        Future.microtask(() => logout());
      },
    );

    AppLogger.info('Auth: Auth interceptor initialization completed');

    // ✅ Debug: Final state'i kontrol et
    final finalStats = _apiClient.hasAuthInterceptor;
    AppLogger.info('Auth: Final interceptor status: $finalStats');
  }
  /// Remove auth interceptor on logout
  void _removeAuthInterceptor() {
    AppLogger.info('Auth: Removing auth interceptor');
    _apiClient.removeAuthInterceptor();
  }

  // ========== LIFECYCLE ==========

  @override
  void dispose() {
    AppLogger.info('Auth: AuthNotifier disposed');
    _streamController.close(); // 🆕 Close stream controller
    super.dispose();
  }
}
