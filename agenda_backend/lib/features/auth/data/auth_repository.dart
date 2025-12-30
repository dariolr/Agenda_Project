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
}
