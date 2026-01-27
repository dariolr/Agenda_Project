// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'credentials_storage.dart';

/// Implementazione Web che usa localStorage con encoding base64.
/// NOTA: Non è una soluzione sicura al 100% ma offre una protezione
/// minima contro lettura casuale. Il browser comunque protegge
/// localStorage per dominio (same-origin policy).
class WebCredentialsStorage implements CredentialsStorage {
  static const _emailKey = 'agenda_backend_saved_email';
  static const _passwordKey = 'agenda_backend_saved_password';

  @override
  Future<({String? email, String? password})> getSavedCredentials() async {
    try {
      final encodedEmail = html.window.localStorage[_emailKey];
      final encodedPassword = html.window.localStorage[_passwordKey];

      if (encodedEmail == null || encodedPassword == null) {
        return (email: null, password: null);
      }

      final email = utf8.decode(base64Decode(encodedEmail));
      final password = utf8.decode(base64Decode(encodedPassword));

      return (email: email, password: password);
    } catch (e) {
      debugPrint('CredentialsStorage: Error reading credentials: $e');
      return (email: null, password: null);
    }
  }

  @override
  Future<void> saveCredentials(String email, String password) async {
    try {
      final encodedEmail = base64Encode(utf8.encode(email));
      final encodedPassword = base64Encode(utf8.encode(password));

      html.window.localStorage[_emailKey] = encodedEmail;
      html.window.localStorage[_passwordKey] = encodedPassword;
    } catch (e) {
      debugPrint('CredentialsStorage: Error saving credentials: $e');
    }
  }

  @override
  Future<void> clearCredentials() async {
    try {
      html.window.localStorage.remove(_emailKey);
      html.window.localStorage.remove(_passwordKey);
    } catch (e) {
      debugPrint('CredentialsStorage: Error clearing credentials: $e');
    }
  }

  @override
  Future<bool> hasCredentials() async {
    try {
      return html.window.localStorage[_emailKey] != null &&
          html.window.localStorage[_passwordKey] != null;
    } catch (e) {
      return false;
    }
  }
}

/// Factory per creare storage su Web
CredentialsStorage createCredentialsStorage() => WebCredentialsStorage();
