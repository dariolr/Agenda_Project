import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'token_storage.dart';

/// Provider per TokenStorage
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return createTokenStorage();
});

/// Provider per ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

/// Provider per l'ID del business per cui l'utente è autenticato.
/// Legge il businessId salvato in localStorage/secureStorage dopo il login.
/// Ritorna null se l'utente non è autenticato.
final authenticatedBusinessIdProvider = FutureProvider<int?>((ref) async {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return tokenStorage.getBusinessId();
});
