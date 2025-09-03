// lib/src/features/auth/presentation/providers/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/simple_token_storage.dart';
import '../../../../utils/app_logger.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../state/auth_state.dart';
import 'auth_notifier.dart';

// ========== DEPENDENCY INJECTION PROVIDERS ==========
// Mail pattern'inize uygun dependency injection hierarchy

/// API Client Provider (shared with mail module)
/// Bu provider mail module'ünüzdeki ile aynı - tek instance kullanılır
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance; // Singleton instance
});

/// Auth Remote DataSource Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.read(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

// ========== USE CASE PROVIDERS ==========

/// Login UseCase Provider
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Logout UseCase Provider
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LogoutUseCase(repository);
});

/// Get Current User UseCase Provider
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

/// Check Auth Status UseCase Provider
final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return CheckAuthStatusUseCase(repository);
});

/// Refresh Token UseCase Provider
final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return RefreshTokenUseCase(repository);
});

// ========== MAIN AUTH PROVIDER ==========

/// Main Authentication Provider
/// Bu provider mail pattern'inizdeki StateNotifierProvider ile aynı yapıda
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.read(getCurrentUserUseCaseProvider),
    checkAuthStatusUseCase: ref.read(checkAuthStatusUseCaseProvider),
    refreshTokenUseCase: ref.read(refreshTokenUseCaseProvider),
    apiClient: ref.read(apiClientProvider),
  );
});

// ========== CONVENIENCE PROVIDERS ==========
// Mail pattern'inizdeki convenience provider'lara benzer

/// Current Auth Status Provider
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authNotifierProvider).status;
});

/// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Current User Provider
final currentUserProvider = Provider((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Auth Loading State Provider
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAnyLoading;
});

/// Auth Error Provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).error;
});

/// User Display Name Provider
final userDisplayNameProvider = Provider<String>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state.userDisplayName;
});

/// User Email Provider
final userEmailProvider = Provider<String>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state.userEmail;
});

// ========== SPECIFIC STATE PROVIDERS ==========

/// Is Logging In Provider
final isLoggingInProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoggingIn;
});

/// Is Logging Out Provider
final isLoggingOutProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoggingOut;
});

/// Is Checking Auth Provider
final isCheckingAuthProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isCheckingAuth;
});

/// Token Expiry Information Provider
final tokenExpiryProvider = Provider<int>((ref) {
  return ref.watch(authNotifierProvider).tokenExpirySeconds;
});

/// Is Token Expired Provider
final isTokenExpiredProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isTokenExpired;
});

// ========== AUTH ACTIONS PROVIDERS ==========
// StateNotifier method'larına erişim için convenience provider'lar

/// Auth Actions Provider
/// AuthNotifier method'larına erişim sağlar
final authActionsProvider = Provider<AuthNotifier>((ref) {
  return ref.read(authNotifierProvider.notifier);
});

// ========== INITIALIZATION PROVIDER ==========

/// Auth Initialization Provider - FIXED: Proper async await handling
///
/// 🔧 CRITICAL FIX: AuthNotifier.checkAuthStatus() properly awaited
/// to ensure state is fully updated before proceeding to router
final authInitProvider = FutureProvider<void>((ref) async {
  try {
    AppLogger.info('Auth Init: Starting auth status check');

    final debugInfo = await SimpleTokenStorage.getDebugInfo();
    AppLogger.info('Auth Init: Storage Debug - $debugInfo');

    final checkAuthStatusUseCase = ref.read(checkAuthStatusUseCaseProvider);
    final result = await checkAuthStatusUseCase.execute();

    // when() yerine direct property access kullanın
    if (result.isSuccess) {
      final isAuthenticated = result.getOrThrow();
      AppLogger.info(
        'Auth Init: Repository isAuthenticated = $isAuthenticated',
      );

      if (isAuthenticated) {
        AppLogger.info('Auth Init: Updating AuthNotifier state...');
        final authNotifier = ref.read(authNotifierProvider.notifier);

        // 🔧 CRITICAL FIX: AWAIT the checkAuthStatus to ensure state is fully updated
        await authNotifier.checkAuthStatus();

        // 🔧 ADDITIONAL FIX: Wait a bit more to ensure all async operations complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify the state is actually updated
        final finalState = ref.read(authNotifierProvider);
        AppLogger.info(
          'Auth Init: Final auth state - isAuthenticated=${finalState.isAuthenticated}',
        );

        if (finalState.isAuthenticated) {
          AppLogger.info('Auth Init: AuthNotifier state fully updated');
        } else {
          AppLogger.warning(
            'Auth Init: AuthNotifier state not updated properly - forcing unauthenticated',
          );
        }
      } else {
        AppLogger.info(
          'Auth Init: User not authenticated - no further action needed',
        );
      }
    } else {
      AppLogger.warning(
        'Auth Init: Auth check failed - ${result.errorMessage}',
      );
    }

    AppLogger.info('Auth Init: ✅ Initialization completed');
  } catch (e) {
    AppLogger.error('Auth Init: Unexpected error - $e');
    // Don't rethrow - let the app continue with unauthenticated state
  }
});

// ========== FAMILY PROVIDERS ==========
// İleride gerekebilecek family provider'lar için placeholder

/// User Permission Provider (future enhancement)
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  // İleride role-based permission checking
  switch (permission) {
    case 'admin':
      return user.isAdmin;
    case 'user_management':
      return user.canManageUsers;
    default:
      return false;
  }
});
