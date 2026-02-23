import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

/// Repository per l'autenticazione CUSTOMER - API reale
/// Usa endpoint /v1/customer/{business_id}/auth/* per clienti (tabella clients)
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Login cliente
  /// POST /v1/customer/{business_id}/auth/login
  Future<User> login({
    required int businessId,
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.customerLogin(
      businessId: businessId,
      email: email,
      password: password,
    );
    return User.fromJson(data['client'] as Map<String, dynamic>);
  }

  /// Logout cliente
  /// POST /v1/customer/{business_id}/auth/logout
  Future<void> logout({required int businessId}) async {
    await _apiClient.customerLogout(businessId: businessId);
  }

  /// Recupera profilo cliente corrente
  /// GET /v1/customer/me
  Future<User> getCurrentUser() async {
    final data = await _apiClient.getCustomerMe();
    return User.fromJson(data);
  }

  /// Tenta di ripristinare sessione da refresh token
  Future<User?> tryRestoreSession({int? businessId}) async {
    final data = await _apiClient.tryRestoreSession(businessId: businessId);
    if (data != null) {
      return User.fromJson(data);
    }
    return null;
  }

  /// Registrazione nuovo cliente
  /// POST /v1/customer/{business_id}/auth/register
  Future<User> register({
    required int businessId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final data = await _apiClient.customerRegister(
      businessId: businessId,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
    return User.fromJson(data['client'] as Map<String, dynamic>);
  }

  /// Reset password (invia email con link)
  /// POST /v1/customer/{business_id}/auth/forgot-password
  Future<void> resetPassword({
    required int businessId,
    required String email,
  }) async {
    await _apiClient.customerForgotPassword(
      businessId: businessId,
      email: email,
    );
  }

  /// Conferma reset password con token
  /// POST /v1/customer/auth/reset-password
  Future<void> confirmResetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.customerResetPassword(token: token, password: newPassword);
  }

  /// Cambia password (utente loggato)
  /// POST /v1/customer/me/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.customerChangePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Aggiorna profilo cliente
  /// PUT /v1/customer/me
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    bool? marketingOptIn,
    bool? profilingOptIn,
    String? preferredChannel,
  }) async {
    final data = await _apiClient.customerUpdateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      marketingOptIn: marketingOptIn,
      profilingOptIn: profilingOptIn,
      preferredChannel: preferredChannel,
    );
    return User.fromJson(data);
  }
}
