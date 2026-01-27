import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credentials_storage.dart';

/// Implementazione secure storage per mobile/desktop.
/// Usa flutter_secure_storage per salvare in modo sicuro le credenziali.
class SecureCredentialsStorage implements CredentialsStorage {
  static const _emailKey = 'agenda_backend_saved_email';
  static const _passwordKey = 'agenda_backend_saved_password';

  final FlutterSecureStorage _storage;

  SecureCredentialsStorage()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  @override
  Future<({String? email, String? password})> getSavedCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);

      return (email: email, password: password);
    } catch (e) {
      debugPrint('CredentialsStorage: Error reading credentials: $e');
      return (email: null, password: null);
    }
  }

  @override
  Future<void> saveCredentials(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    } catch (e) {
      debugPrint('CredentialsStorage: Error saving credentials: $e');
    }
  }

  @override
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } catch (e) {
      debugPrint('CredentialsStorage: Error clearing credentials: $e');
    }
  }

  @override
  Future<bool> hasCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      return email != null && password != null;
    } catch (e) {
      return false;
    }
  }
}

/// Factory per creare storage su mobile/desktop
CredentialsStorage createCredentialsStorage() => SecureCredentialsStorage();
