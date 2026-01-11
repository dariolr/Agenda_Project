import '../../../core/models/user.dart';

/// Stati possibili dell'autenticazione
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Stato dell'autenticazione
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? errorCode;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? errorCode,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
  );

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message, {String? code}) =>
      AuthState(status: AuthStatus.error, errorMessage: message, errorCode: code);

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email}, errorMessage: $errorMessage, errorCode: $errorCode)';
}
