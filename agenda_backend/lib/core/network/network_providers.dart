import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'token_storage.dart';

part 'network_providers.g.dart';

/// Provider per TokenStorage (singleton)
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return createTokenStorage();
}

/// Provider per ApiClient (singleton)
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
}
