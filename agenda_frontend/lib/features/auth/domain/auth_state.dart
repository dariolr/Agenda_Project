import '../../../core/models/user.dart';

/// Stati possibili dell'autenticazione
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Stato dell'autenticazione
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email}, errorMessage: $errorMessage)';
}
