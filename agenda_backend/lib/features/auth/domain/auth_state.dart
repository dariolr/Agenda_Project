/// Stati possibili dell'autenticazione.
enum AuthStatus {
  /// Stato iniziale, verifica sessione in corso.
  initial,

  /// Operazione di login/logout in corso.
  loading,

  /// Utente autenticato.
  authenticated,

  /// Utente non autenticato.
  unauthenticated,

  /// Errore durante autenticazione.
  error,
}

/// Stato dell'autenticazione nel gestionale.
class AuthState {
  final AuthStatus status;
  final dynamic user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Verifica se l'utente è autenticato.
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Verifica se è in corso un'operazione.
  bool get isLoading => status == AuthStatus.loading;

  /// Verifica se è nello stato iniziale.
  bool get isInitial => status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    dynamic user,
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

  factory AuthState.authenticated(dynamic user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}
