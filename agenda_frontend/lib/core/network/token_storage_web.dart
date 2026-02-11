// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'token_storage_interface.dart';

/// Implementazione Web che usa localStorage con fallback a sessionStorage
/// NOTA: In produzione si dovrebbe preferire cookie httpOnly server-side
class WebTokenStorage implements TokenStorage {
  static const _refreshTokenKey = 'agenda_refresh_token';
  static const _businessIdKey = 'agenda_business_id';

  html.Storage? _resolveStorage() {
    final candidates = [html.window.localStorage, html.window.sessionStorage];
    for (final storage in candidates) {
      try {
        const probeKey = '__agenda_storage_probe__';
        storage[probeKey] = '1';
        storage.remove(probeKey);
        return storage;
      } catch (_) {
        // Storage non disponibile/bloccato (es. browser embedded o modalità privata).
      }
    }
    return null;
  }

  String? _getValue(String key) {
    try {
      final localValue = html.window.localStorage[key];
      if (localValue != null) {
        return localValue;
      }
    } catch (_) {}

    try {
      return html.window.sessionStorage[key];
    } catch (_) {
      return null;
    }
  }

  void _setValue(String key, String value) {
    final storage = _resolveStorage();
    storage?[key] = value;
  }

  void _removeValue(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
    try {
      html.window.sessionStorage.remove(key);
    } catch (_) {}
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return _getValue(_refreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage: Error reading token from web storage: $e');
      return null;
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      _setValue(_refreshTokenKey, token);
    } catch (e) {
      debugPrint('TokenStorage: Error saving token to web storage: $e');
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      _removeValue(_refreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage: Error clearing token from web storage: $e');
    }
  }

  @override
  Future<int?> getBusinessId() async {
    try {
      final value = _getValue(_businessIdKey);
      return value != null ? int.tryParse(value) : null;
    } catch (e) {
      debugPrint('TokenStorage: Error reading businessId from web storage: $e');
      return null;
    }
  }

  @override
  Future<void> saveBusinessId(int businessId) async {
    try {
      _setValue(_businessIdKey, businessId.toString());
    } catch (e) {
      debugPrint('TokenStorage: Error saving businessId to web storage: $e');
    }
  }

  @override
  Future<void> clearBusinessId() async {
    try {
      _removeValue(_businessIdKey);
    } catch (e) {
      debugPrint(
        'TokenStorage: Error clearing businessId from web storage: $e',
      );
    }
  }
}

/// Factory per creare storage su Web
TokenStorage createTokenStorage() => WebTokenStorage();
