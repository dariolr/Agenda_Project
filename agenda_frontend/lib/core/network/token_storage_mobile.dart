import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage_interface.dart';

/// Implementazione secure storage per mobile/desktop
class SecureTokenStorage implements TokenStorage {
  static const _refreshTokenKey = 'agenda_refresh_token';
  static const _businessIdKey = 'agenda_business_id';

  final FlutterSecureStorage _storage;

  SecureTokenStorage()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage: Error reading token: $e');
      return null;
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      debugPrint('TokenStorage: Error saving token: $e');
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage: Error clearing token: $e');
    }
  }

  @override
  Future<int?> getBusinessId() async {
    try {
      final value = await _storage.read(key: _businessIdKey);
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      debugPrint('TokenStorage: Error reading businessId: $e');
      return null;
    }
  }

  @override
  Future<void> saveBusinessId(int businessId) async {
    try {
      await _storage.write(key: _businessIdKey, value: businessId.toString());
    } catch (e) {
      debugPrint('TokenStorage: Error saving businessId: $e');
    }
  }

  @override
  Future<void> clearBusinessId() async {
    try {
      await _storage.delete(key: _businessIdKey);
    } catch (e) {
      debugPrint('TokenStorage: Error clearing businessId: $e');
    }
  }
}

/// Factory per creare storage su mobile/desktop
TokenStorage createTokenStorage() => SecureTokenStorage();
