enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Represents the authentication state of the application.
class AuthState {
  final AuthStatus status;
  final String? token;
  final String? userId;
  final String? email;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.userId,
    this.email,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && token != null && token!.isNotEmpty;

  bool get isInitialized => status != AuthStatus.initial;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated({
    required String token,
    required String userId,
    String? email,
  }) =>
      AuthState(
        status: AuthStatus.authenticated,
        token: token,
        userId: userId,
        email: email,
      );

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? userId,
    String? email,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, userId: $userId, hasToken: ${token != null})';
}
