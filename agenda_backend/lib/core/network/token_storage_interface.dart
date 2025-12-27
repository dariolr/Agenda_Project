/// Gestione storage per refresh token
/// - Web: localStorage (con considerazioni di sicurezza per production)
/// - Mobile: secure storage
abstract class TokenStorage {
  Future<String?> getRefreshToken();
  Future<void> saveRefreshToken(String token);
  Future<void> clearRefreshToken();
}
