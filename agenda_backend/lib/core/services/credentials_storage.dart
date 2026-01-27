/// Gestione sicura delle credenziali salvate per accesso rapido.
/// - Web: usa localStorage (base64 encoded, non sicuro per dati sensibili in produzione reale)
/// - Mobile: usa flutter_secure_storage
abstract class CredentialsStorage {
  /// Recupera le credenziali salvate (email, password)
  Future<({String? email, String? password})> getSavedCredentials();

  /// Salva le credenziali per accesso rapido futuro
  Future<void> saveCredentials(String email, String password);

  /// Cancella le credenziali salvate
  Future<void> clearCredentials();

  /// Verifica se ci sono credenziali salvate
  Future<bool> hasCredentials();
}
