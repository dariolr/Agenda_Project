import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/token_storage.dart';
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
      // Recupera il businessId salvato
      final tokenStorage = createTokenStorage();
      final savedBusinessId = await tokenStorage.getBusinessId();

      final user = await _repository.tryRestoreSession(
        businessId: savedBusinessId,
      );
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
  /// Richiede businessId per usare l'endpoint customer corretto
  Future<bool> login({
    required int businessId,
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(
        businessId: businessId,
        email: email,
        password: password,
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

  /// Logout
  Future<void> logout({required int businessId}) async {
    try {
      await _repository.logout(businessId: businessId);
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  /// Registrazione nuovo cliente
  Future<bool> register({
    required int businessId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.register(
        businessId: businessId,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
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
