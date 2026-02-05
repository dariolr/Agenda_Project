import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/services/credentials_provider.dart';
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
  /// Se fallisce, prova con le credenziali salvate ("Ricordami")
  Future<void> _tryRestoreSession() async {
    debugPrint('AUTH: _tryRestoreSession started');
    state = AuthState.loading();

    int? savedBusinessId;

    try {
      // Recupera il businessId salvato
      final tokenStorage = ref.read(tokenStorageProvider);
      savedBusinessId = await tokenStorage.getBusinessId();
      debugPrint('AUTH: savedBusinessId=$savedBusinessId');

      final user = await _repository.tryRestoreSession(
        businessId: savedBusinessId,
      );
      debugPrint('AUTH: tryRestoreSession result: user=${user?.email}');
      if (user != null) {
        state = AuthState.authenticated(user);
        debugPrint('AUTH: state set to authenticated');
        return;
      }

      // Refresh token non valido, prova con credenziali salvate
      debugPrint('AUTH: no session, trying saved credentials');
    } catch (e, st) {
      debugPrint('AUTH: tryRestoreSession error: $e');
      debugPrint('AUTH: stack trace: $st');
    }

    // Prova auto-login con credenziali salvate (anche in caso di errore sopra)
    try {
      await _tryAutoLoginWithSavedCredentials(savedBusinessId);
    } catch (e) {
      debugPrint(
        'AUTH: _tryAutoLoginWithSavedCredentials unexpected error: $e',
      );
      // Assicurati che lo stato sia sempre settato
      state = AuthState.unauthenticated();
    }
  }

  /// Tenta auto-login con credenziali salvate da "Ricordami"
  Future<void> _tryAutoLoginWithSavedCredentials(int? businessId) async {
    try {
      final credentialsStorage = ref.read(credentialsStorageProvider);
      final credentials = await credentialsStorage.getSavedCredentials();

      if (credentials.email != null &&
          credentials.password != null &&
          businessId != null) {
        debugPrint(
          'AUTH: auto-login with saved credentials for ${credentials.email}',
        );

        final user = await _repository.login(
          businessId: businessId,
          email: credentials.email!,
          password: credentials.password!,
        );

        state = AuthState.authenticated(user);
        debugPrint('AUTH: auto-login successful');
        return;
      }
    } catch (e) {
      debugPrint('AUTH: auto-login with saved credentials failed: $e');
      // Credenziali non più valide (es. password cambiata) - puliscile
      try {
        final credentialsStorage = ref.read(credentialsStorageProvider);
        await credentialsStorage.clearCredentials();
        debugPrint('AUTH: cleared invalid saved credentials');
      } catch (_) {}
    }

    // Nessuna credenziale salvata o login fallito
    state = AuthState.unauthenticated();
    debugPrint('AUTH: state set to unauthenticated');
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
      debugPrint('AUTH PROVIDER: calling repository.login');
      final user = await _repository.login(
        businessId: businessId,
        email: email,
        password: password,
      );
      debugPrint('AUTH PROVIDER: login success, user=${user.email}');
      state = AuthState.authenticated(user);
      return true;
    } on ApiException catch (e) {
      debugPrint('AUTH PROVIDER: ApiException: ${e.code} - ${e.message}');
      state = AuthState.error(e.message, code: e.code);
      return false;
    } catch (e, st) {
      debugPrint('AUTH PROVIDER: generic error: $e');
      debugPrint('AUTH PROVIDER: stack trace: $st');
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
    debugPrint('=== REGISTER START ===');
    debugPrint(
      'Current state before register: errorCode=${state.errorCode}, errorMessage=${state.errorMessage}',
    );
    state = AuthState.loading();
    try {
      debugPrint(
        'Register: businessId=$businessId, email=$email, firstName=$firstName, lastName=$lastName',
      );
      final user = await _repository.register(
        businessId: businessId,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      debugPrint('Register SUCCESS: user=${user.email}');
      state = AuthState.authenticated(user);
      return true;
    } on ApiException catch (e) {
      debugPrint('Register ApiException: code=${e.code}, message=${e.message}');
      state = AuthState.error(e.message, code: e.code);
      return false;
    } catch (e, st) {
      debugPrint('Register generic error: $e');
      debugPrint('Stack trace: $st');
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Reset password (invia email con link)
  /// Lancia ApiException se l'email non esiste (code: email_not_found)
  Future<void> resetPassword({
    required int businessId,
    required String email,
  }) async {
    await _repository.resetPassword(businessId: businessId, email: email);
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
      state = state.copyWith(errorMessage: e.toString());
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
