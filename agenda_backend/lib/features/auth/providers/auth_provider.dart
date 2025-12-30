import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

/// Provider per il repository di autenticazione.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

/// Provider per lo stato di autenticazione.
/// Gestisce il ciclo di vita dell'autenticazione nel gestionale.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Notifier per la gestione dell'autenticazione.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Tenta ripristino sessione all'avvio
    _tryRestoreSession();
    return AuthState.initial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Tenta di ripristinare la sessione da refresh token salvato.
  Future<void> _tryRestoreSession() async {
    state = AuthState.loading();
    try {
      final user = await _repository.tryRestoreSession();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  /// Login con email e password.
  /// Ritorna true se il login ha successo, false altrimenti.
  Future<bool> login({required String email, required String password}) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logout dell'utente corrente.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  /// Pulisce l'errore corrente.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Verifica se l'utente è autenticato.
  bool get isAuthenticated => state.isAuthenticated;

  /// Ritorna l'utente corrente (se autenticato).
  User? get currentUser => state.user as User?;
}
