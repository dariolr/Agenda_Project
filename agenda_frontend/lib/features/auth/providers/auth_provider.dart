import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

/// Provider per il repository di autenticazione
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

/// Provider per lo stato di autenticazione
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Tenta ripristino sessione all'avvio
    _tryRestoreSession();
    return AuthState.initial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Tenta di ripristinare la sessione da refresh token
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

  /// Login con email e password
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

  /// Logout
  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  /// Registrazione nuovo utente
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
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

  /// Reset password (invia email con link)
  Future<bool> resetPassword({required String email}) async {
    state = AuthState.loading();
    try {
      await _repository.resetPassword(email: email);
      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Conferma reset password con token
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    await _repository.confirmResetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  /// Cambia password (utente loggato)
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
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Aggiorna il profilo utente
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

  /// Pulisce errore
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Verifica se è autenticato
  bool get isAuthenticated => state.isAuthenticated;
}
