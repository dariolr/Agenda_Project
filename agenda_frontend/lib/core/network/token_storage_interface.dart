/// Gestione storage per refresh token e business ID
/// - Web: localStorage (con considerazioni di sicurezza per production)
/// - Mobile: secure storage
abstract class TokenStorage {
  Future<String?> getRefreshToken();
  Future<void> saveRefreshToken(String token);
  Future<void> clearRefreshToken();

  /// Business ID per customer auth (necessario per refresh token)
  Future<int?> getBusinessId();
  Future<void> saveBusinessId(int businessId);
  Future<void> clearBusinessId();
}
