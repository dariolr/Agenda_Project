import 'credentials_storage.dart';

/// Stub per conditional import
CredentialsStorage createCredentialsStorage() => throw UnsupportedError(
  'Cannot create credentials storage without dart:html or flutter_secure_storage',
);
