// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'token_storage_interface.dart';

/// Implementazione Web che usa localStorage
/// NOTA: In produzione si dovrebbe preferire cookie httpOnly server-side
class WebTokenStorage implements TokenStorage {
  static const _refreshTokenKey = 'agenda_backend_refresh_token';

  @override
  Future<String?> getRefreshToken() async {
    try {
      return html.window.localStorage[_refreshTokenKey];
    } catch (e) {
      debugPrint('TokenStorage: Error reading token from localStorage: $e');
      return null;
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      html.window.localStorage[_refreshTokenKey] = token;
    } catch (e) {
      debugPrint('TokenStorage: Error saving token to localStorage: $e');
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      html.window.localStorage.remove(_refreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage: Error clearing token from localStorage: $e');
    }
  }
}

/// Factory per creare storage su Web
TokenStorage createTokenStorage() => WebTokenStorage();
