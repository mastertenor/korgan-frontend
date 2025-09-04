// lib/src/features/auth/presentation/providers/auth_providers.dart
// SIMPLIFIED VERSION - authInterceptorManagerProvider güncellendi

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

/// API Client Provider (singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
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

// ========== ✅ SIMPLIFIED INTERCEPTOR MANAGER ==========

/// Auth Interceptor Manager - Stateless interceptor kurulumu
///
/// Bootstrap Gate tarafından tetiklenir ve interceptor'ın
/// her zaman hazır olmasını garanti eder
final authInterceptorManagerProvider = Provider<bool>((ref) {
  final apiClient = ref.read(apiClientProvider);

  AppLogger.info('🔧 Provider: Stateless auth interceptor kuruluyor...');

  // Stateless interceptor kurulumu - Riverpod'a bağımlı değil
  // refreshAccessTokenStateless fonksiyonu ApiClient içinde tanımlı
  apiClient.setupAuthInterceptor();

  AppLogger.info('✅ Provider: Stateless auth interceptor hazır');
  return true;
});

// ========== MAIN AUTH PROVIDER ==========

/// Main Authentication Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  // Bootstrap Gate sayesinde interceptor zaten kurulu olacak
  // Burada ekstra birşey yapmaya gerek yok

  final notifier = AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.read(getCurrentUserUseCaseProvider),
    checkAuthStatusUseCase: ref.read(checkAuthStatusUseCaseProvider),
    refreshTokenUseCase: ref.read(refreshTokenUseCaseProvider),
    apiClient: ref.read(apiClientProvider),
  );

  final apiClient = ref.read(apiClientProvider);
  AppLogger.info(
    '🔧 AuthNotifier: Interceptor status = ${apiClient.hasAuthInterceptor}',
  );

  return notifier;
});

// ========== CONVENIENCE PROVIDERS (değişmedi) ==========

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

/// Auth Actions Provider
final authActionsProvider = Provider<AuthNotifier>((ref) {
  return ref.read(authNotifierProvider.notifier);
});

// ========== INITIALIZATION PROVIDER ==========

/// Auth Initialization Provider
/// Bootstrap Gate tarafından kullanılır
final authInitProvider = FutureProvider<void>((ref) async {
  try {
    AppLogger.info('🔐 Auth Init: Başlatılıyor...');

    // Storage durumunu kontrol et
    final debugInfo = await SimpleTokenStorage.getDebugInfo();
    AppLogger.info('🔐 Auth Init: Storage - $debugInfo');

    // Token'lar var mı kontrol et
    final hasAccessToken = await SimpleTokenStorage.getAccessToken() != null;
    final hasRefreshToken = await SimpleTokenStorage.getRefreshToken() != null;

    if (!hasAccessToken || !hasRefreshToken) {
      AppLogger.info('🔐 Auth Init: No tokens found, user not authenticated');
      return; // Token yoksa devam etme
    }

    // Token var - expired olabilir ama silme!
    AppLogger.info(
      '🔐 Auth Init: Tokens found, will try to fetch user profile...',
    );

    // Token expired mı kontrol et
    final isExpired = await SimpleTokenStorage.isTokenExpired();
    if (isExpired) {
      AppLogger.warning(
        '🔐 Auth Init: Token expired - interceptor will handle refresh on first API call',
      );
      // TOKEN'LARI SİLME! İnterceptor refresh yapacak
      // Sadece state'i unauthenticated bırak, ilk API çağrısında interceptor devreye girecek
      return;
    }

    // Token valid ise profile'ı almayı dene
    final authNotifier = ref.read(authNotifierProvider.notifier);

    try {
      // Kullanıcı profilini al
      await authNotifier.checkAuthStatus();

      // State'in güncellenmesini bekle
      await Future.delayed(const Duration(milliseconds: 200));

      final finalState = ref.read(authNotifierProvider);
      AppLogger.info(
        '🔐 Auth Init: Final state = ${finalState.isAuthenticated}',
      );

      // Eğer profile alınamadıysa ama token expired değilse, başka bir sorun var
      if (!finalState.isAuthenticated && !isExpired) {
        AppLogger.error(
          '🔐 Auth Init: Failed to fetch profile with valid token - network issue?',
        );
        // TOKEN'LARI HALA SİLME - network sorunu olabilir
      }
    } catch (e) {
      AppLogger.error('🔐 Auth Init: Error fetching user profile - $e');
      // Profile alınamadı ama token'lar var, TOKEN'LARI SİLME
      // İlk API çağrısında interceptor refresh deneyecek
    }

    AppLogger.info('✅ Auth Init: Tamamlandı');
  } catch (e) {
    AppLogger.error('❌ Auth Init: Hata - $e');
    // Hata olsa bile app açılmalı ve TOKEN'LAR SİLİNMEMELİ
  }
}); 

// ========== FAMILY PROVIDERS ==========

/// User Permission Provider
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  switch (permission) {
    case 'admin':
      return user.isAdmin;
    case 'user_management':
      return user.canManageUsers;
    default:
      return false;
  }
});
