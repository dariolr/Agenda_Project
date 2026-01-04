import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

/// Repository per l'autenticazione nel gestionale.
/// Gestisce login, logout e recupero profilo utente.
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Login utente con email e password.
  /// Ritorna l'utente autenticato.
  Future<User> login({required String email, required String password}) async {
    final data = await _apiClient.login(email, password);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Logout utente corrente.
  /// Invalida la sessione e pulisce i token.
  Future<void> logout() async {
    await _apiClient.logout();
  }

  /// Recupera il profilo dell'utente corrente.
  Future<User> getCurrentUser() async {
    final data = await _apiClient.getMe();
    return User.fromJson(data);
  }

  /// Tenta di ripristinare la sessione da refresh token.
  /// Ritorna l'utente se la sessione è valida, null altrimenti.
  Future<User?> tryRestoreSession() async {
    final data = await _apiClient.tryRestoreSession();
    if (data != null) {
      return User.fromJson(data);
    }
    return null;
  }

  /// Aggiorna il profilo dell'utente corrente.
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final data = await _apiClient.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );
    return User.fromJson(data);
  }

  /// Verifica se un token di reset è valido.
  /// Lancia eccezione se il token è invalido o scaduto.
  Future<void> verifyResetToken(String token) async {
    await _apiClient.verifyResetToken(token);
  }

  /// Richiede il reset della password (invia email con link).
  /// L'API ritorna sempre successo per non rivelare se l'email esiste.
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.forgotPassword(email);
  }

  /// Reset password con token (da email di invito/reset).
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.resetPassword(token: token, password: newPassword);
  }

  /// Cambia password utente autenticato.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
