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
