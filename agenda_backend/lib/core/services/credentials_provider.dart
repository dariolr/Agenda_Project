import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'credentials_storage.dart';
import 'credentials_storage_stub.dart'
    if (dart.library.html) 'credentials_storage_web.dart'
    if (dart.library.io) 'credentials_storage_mobile.dart';

/// Provider per accedere al credentials storage
final credentialsStorageProvider = Provider<CredentialsStorage>((ref) {
  return createCredentialsStorage();
});

/// Provider per le credenziali salvate
final savedCredentialsProvider =
    FutureProvider<({String? email, String? password})>((ref) async {
      final storage = ref.watch(credentialsStorageProvider);
      return storage.getSavedCredentials();
    });
