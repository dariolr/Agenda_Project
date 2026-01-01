import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'token_storage.dart';

part 'network_providers.g.dart';

/// Provider per TokenStorage (singleton)
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return createTokenStorage();
}

/// Provider per notificare quando la sessione è scaduta.
/// I listener (es. AuthNotifier) possono reagire a questo evento.
final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(
  SessionExpiredNotifier.new,
);

/// Notifier che incrementa un contatore ogni volta che la sessione scade.
/// Gli observer possono fare ref.listen() su questo provider.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() {
    state++;
  }
}

/// Provider per ApiClient (singleton)
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final storage = ref.watch(tokenStorageProvider);
  final sessionExpired = ref.read(sessionExpiredProvider.notifier);

  return ApiClient(
    tokenStorage: storage,
    onSessionExpired: () => sessionExpired.trigger(),
  );
}
