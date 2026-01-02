import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/services/preferences_service.dart';
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
  static bool _sessionRestored = false;
  static AuthState? _lastState;

  @override
  AuthState build() {
    // Se abbiamo già uno stato salvato (es. errore), mantienilo
    if (_lastState != null && _lastState!.status == AuthStatus.error) {
      final savedState = _lastState!;
      _lastState = null; // Consuma lo stato salvato
      return savedState;
    }

    // Tenta ripristino sessione solo al primo avvio dell'app
    if (!_sessionRestored) {
      _sessionRestored = true;
      _tryRestoreSession();
    }
    return AuthState.initial();
  }

  /// Reset per testing o logout completo
  static void resetSessionFlag() {
    _sessionRestored = false;
    _lastState = null;
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
  /// Se silent=true, non fa chiamata API (per sessione già scaduta)
  /// Se clearPreferences=true, pulisce tutte le preferenze salvate
  Future<void> logout({
    bool silent = false,
    bool clearPreferences = false,
  }) async {
    if (!silent) {
      try {
        await _repository.logout();
      } catch (_) {
        // Ignora errori durante logout (es. token già invalido)
      }
    }

    // Pulisce le preferenze se richiesto
    if (clearPreferences) {
      try {
        await ref.read(preferencesServiceProvider).clearAll();
      } catch (_) {
        // Ignora errori durante pulizia preferenze
      }
    }

    state = AuthState.unauthenticated();
  }

  /// Pulisce l'errore corrente.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Verifica se l'utente è autenticato.
  bool get isAuthenticated => state.isAuthenticated;

  /// Ritorna l'utente corrente (se autenticato).
  User? get currentUser => state.user as User?;

  /// Aggiorna il profilo dell'utente corrente.
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final updatedUser = await _repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );
    state = AuthState.authenticated(updatedUser);
  }

  /// Verifica se un token di reset è valido.
  /// Lancia eccezione se il token è invalido o scaduto.
  Future<void> verifyResetToken(String token) async {
    await _repository.verifyResetToken(token);
  }

  /// Reset password con token (da email di invito/reset).
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    await _repository.resetPasswordWithToken(
      token: token,
      newPassword: newPassword,
    );
  }

  /// Cambia password utente autenticato.
  /// Ritorna true se successo, false se errore.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
