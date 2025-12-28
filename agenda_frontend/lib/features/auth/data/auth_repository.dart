import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

/// Repository per l'autenticazione - API reale
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Login utente
  /// POST /v1/auth/login
  Future<User> login({required String email, required String password}) async {
    final data = await _apiClient.login(email, password);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Logout utente
  /// POST /v1/auth/logout
  Future<void> logout() async {
    await _apiClient.logout();
  }

  /// Recupera profilo utente corrente
  /// GET /v1/me
  Future<User> getCurrentUser() async {
    final data = await _apiClient.getMe();
    return User.fromJson(data);
  }

  /// Tenta di ripristinare sessione da refresh token
  Future<User?> tryRestoreSession() async {
    final data = await _apiClient.tryRestoreSession();
    if (data != null) {
      return User.fromJson(data);
    }
    return null;
  }

  /// Registrazione nuovo utente
  /// POST /v1/auth/register
  Future<User> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final data = await _apiClient.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Reset password (invia email con link)
  /// POST /v1/auth/forgot-password
  Future<void> resetPassword({required String email}) async {
    await _apiClient.forgotPassword(email: email);
  }

  /// Conferma reset password con token
  /// POST /v1/auth/reset-password
  Future<void> confirmResetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.resetPasswordWithToken(
      token: token,
      password: newPassword,
    );
  }

  /// Cambia password (utente loggato)
  /// POST /v1/me/change-password
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
