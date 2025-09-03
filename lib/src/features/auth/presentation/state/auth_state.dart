// lib/src/features/auth/presentation/state/auth_state.dart

import '../../domain/entities/user.dart';
import '../../domain/entities/auth_token.dart';

/// Authentication state representation
///
/// Bu state class mevcut mail pattern'inize uygun olarak tasarlandı.
/// Immutable state with copyWith pattern.
class AuthState {
  /// Current authenticated user (null if not authenticated)
  final User? user;

  /// Current auth token (null if not authenticated)
  final AuthToken? token;

  /// Authentication status flags
  final bool isLoading;
  final bool isLoggingIn;
  final bool isLoggingOut;
  final bool isRefreshingToken;
  final bool isCheckingAuth;

  /// Error state
  final String? error;

  /// Authentication status
  final AuthStatus status;

  /// Last authentication check timestamp
  final DateTime? lastChecked;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.isLoggingIn = false,
    this.isLoggingOut = false,
    this.isRefreshingToken = false,
    this.isCheckingAuth = false,
    this.error,
    this.status = AuthStatus.initial,
    this.lastChecked,
  });

  // ========== FACTORY CONSTRUCTORS ==========

  /// Create initial state
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  /// Create loading state
  factory AuthState.loading() {
    return const AuthState(isLoading: true, status: AuthStatus.loading);
  }

  /// Create authenticated state
  factory AuthState.authenticated({
    required User user,
    required AuthToken token,
  }) {
    return AuthState(
      user: user,
      token: token,
      status: AuthStatus.authenticated,
      lastChecked: DateTime.now(),
    );
  }

  /// Create unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState(
      status: AuthStatus.unauthenticated,
      lastChecked: null,
    );
  }

  /// Create error state
  factory AuthState.error(String error) {
    return AuthState(
      error: error,
      status: AuthStatus.error,
      lastChecked: DateTime.now(),
    );
  }

  // ========== COPY WITH METHODS ==========

  /// Copy with updated values
  AuthState copyWith({
    User? user,
    AuthToken? token,
    bool? isLoading,
    bool? isLoggingIn,
    bool? isLoggingOut,
    bool? isRefreshingToken,
    bool? isCheckingAuth,
    String? error,
    AuthStatus? status,
    DateTime? lastChecked,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      isRefreshingToken: isRefreshingToken ?? this.isRefreshingToken,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      error: clearError ? null : (error ?? this.error),
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// Set loading state for login
  AuthState copyWithLoggingIn() {
    return copyWith(
      isLoggingIn: true,
      isLoading: true,
      clearError: true,
      status: AuthStatus.loading,
    );
  }

  /// Set loading state for logout
  AuthState copyWithLoggingOut() {
    return copyWith(isLoggingOut: true, isLoading: true, clearError: true);
  }

  /// Set loading state for token refresh
  AuthState copyWithRefreshingToken() {
    return copyWith(isRefreshingToken: true, clearError: true);
  }

  /// Set loading state for auth check
  AuthState copyWithCheckingAuth() {
    return copyWith(isCheckingAuth: true, clearError: true);
  }

  /// Set authenticated state after successful login
  AuthState copyWithAuthenticated({
    required User user,
    required AuthToken token,
  }) {
    return copyWith(
      user: user,
      token: token,
      isLoading: false,
      isLoggingIn: false,
      status: AuthStatus.authenticated,
      lastChecked: DateTime.now(),
      clearError: true,
    );
  }

  /// Set unauthenticated state after logout
  AuthState copyWithUnauthenticated() {
    return copyWith(
      isLoading: false,
      isLoggingOut: false,
      status: AuthStatus.unauthenticated,
      lastChecked: DateTime.now(),
      clearUser: true,
      clearToken: true,
      clearError: true,
    );
  }

  /// Set error state
  AuthState copyWithError(String error) {
    return copyWith(
      error: error,
      isLoading: false,
      isLoggingIn: false,
      isLoggingOut: false,
      isRefreshingToken: false,
      isCheckingAuth: false,
      status: AuthStatus.error,
      lastChecked: DateTime.now(),
    );
  }

  /// Clear all loading states
  AuthState copyWithLoadingComplete() {
    return copyWith(
      isLoading: false,
      isLoggingIn: false,
      isLoggingOut: false,
      isRefreshingToken: false,
      isCheckingAuth: false,
    );
  }

  // ========== COMPUTED PROPERTIES ==========

  /// Check if user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Check if any operation is in progress
  bool get isAnyLoading =>
      isLoading ||
      isLoggingIn ||
      isLoggingOut ||
      isRefreshingToken ||
      isCheckingAuth;

  /// Check if auth state is initial (not checked yet)
  bool get isInitial => status == AuthStatus.initial;

  /// Check if there's an error
  bool get hasError => error != null;

  /// Get user display name
  String get userDisplayName => user?.displayName ?? 'User';

  /// Get user email
  String get userEmail => user?.email ?? '';

  /// Check if token is expired or will expire soon
  bool get isTokenExpired => token?.isExpired ?? true;

  /// Check if token will expire soon
  bool get willTokenExpireSoon => token?.willExpireSoon ?? true;

  /// Get time until token expires (in seconds)
  int get tokenExpirySeconds => token?.remainingSeconds ?? 0;

  @override
  String toString() {
    return 'AuthState('
        'status: $status, '
        'isAuthenticated: $isAuthenticated, '
        'isAnyLoading: $isAnyLoading, '
        'hasError: $hasError, '
        'user: ${user?.email ?? 'null'}, '
        'tokenExpired: $isTokenExpired'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.user == user &&
        other.status == status &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(user, status, isLoading, error);
}

/// Authentication status enumeration
enum AuthStatus {
  /// Initial state - auth status not checked yet
  initial,

  /// Loading state - checking authentication
  loading,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Error occurred during authentication
  error,
}
