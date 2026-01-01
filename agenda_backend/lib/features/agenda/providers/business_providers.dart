import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/business.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/business_providers.dart';

/// Notifier per forzare il refresh della lista business
class BusinessesRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}

final businessesRefreshProvider =
    NotifierProvider<BusinessesRefreshNotifier, int>(
      BusinessesRefreshNotifier.new,
    );

///
/// 🔹 ELENCO BUSINESS (da API)
/// Se l'utente è superadmin, usa endpoint admin.
///
final businessesProvider = FutureProvider<List<Business>>((ref) async {
  // Watch del refresh provider per forzare il ricaricamento
  ref.watch(businessesRefreshProvider);

  final authState = ref.watch(authProvider);

  // ⚠️ Non fare chiamate API se l'utente non è autenticato
  if (!authState.isAuthenticated) {
    return [];
  }

  final repository = ref.watch(businessRepositoryProvider);

  if (authState.user?.isSuperadmin ?? false) {
    return repository.getAllAdmin();
  }
  return repository.getAll();
});

///
/// 🔹 BUSINESS CORRENTE (ID)
///
class CurrentBusinessId extends Notifier<int> {
  @override
  int build() {
    // ✅ Imposta come default il primo business disponibile
    // Aspetta che businessesProvider carichi i dati
    ref.listen(businessesProvider, (previous, next) {
      next.whenData((businesses) {
        if (businesses.isNotEmpty && state == 0) {
          state = businesses.first.id;
        }
      });
    });
    return 0; // Inizializza a 0 per triggare il listen
  }

  void set(int id) => state = id;
}

final currentBusinessIdProvider = NotifierProvider<CurrentBusinessId, int>(
  CurrentBusinessId.new,
);

///
/// 🔹 BUSINESS CORRENTE (oggetto)
///
final currentBusinessProvider = Provider<Business>((ref) {
  final businessesAsync = ref.watch(businessesProvider);
  final currentId = ref.watch(currentBusinessIdProvider);

  return businessesAsync.when(
    data: (businesses) => businesses.firstWhere(
      (b) => b.id == currentId,
      orElse: () => businesses.first,
    ),
    loading: () =>
        Business(id: currentId, name: 'Loading...', createdAt: DateTime.now()),
    error: (_, __) =>
        Business(id: currentId, name: 'Error', createdAt: DateTime.now()),
  );
});
