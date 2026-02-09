import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/business.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/business_providers.dart';
import '../../business/providers/superadmin_selected_business_provider.dart';

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
    // ✅ Imposta come default il business selezionato (superadmin)
    // oppure il primo business disponibile.
    final authState = ref.watch(authProvider);
    final isSuperadmin = authState.user?.isSuperadmin ?? false;

    // Allinea al business selezionato quando cambia
    // NOTE: non usare fireImmediately qui per evitare letture di `state`
    // prima dell'inizializzazione del provider.
    ref.listen(superadminSelectedBusinessProvider, (previous, next) {
      if (!isSuperadmin) return;
      if (next != null && state != next) {
        state = next;
      }
    });

    // Aspetta che businessesProvider carichi i dati
    ref.listen(businessesProvider, (previous, next) {
      next.whenData((businesses) {
        if (businesses.isEmpty) {
          if (state != 0) {
            state = 0;
          }
          return;
        }

        final selectedBusiness = ref.read(superadminSelectedBusinessProvider);

        if (isSuperadmin && selectedBusiness != null) {
          final exists = businesses.any((b) => b.id == selectedBusiness);
          if (exists) {
            if (state != selectedBusiness) {
              state = selectedBusiness;
            }
            return;
          }

          // Business non più valido: pulisci preferenze e fallback al primo
          ref
              .read(superadminSelectedBusinessProvider.notifier)
              .clearCompletely();
          if (state != businesses.first.id) {
            state = businesses.first.id;
          }
          return;
        }

        // Utente non superadmin:
        // mantieni sempre un business valido (mai 0) per evitare rimbalzi di routing
        // quando la lista viene ricaricata o cambia dinamicamente.
        if (state == 0) {
          state = businesses.first.id;
          return;
        }

        // Se il business corrente non è più accessibile, fallback al primo disponibile.
        if (!businesses.any((b) => b.id == state)) {
          state = businesses.first.id;
          return;
        }
      });
    });

    // Inizializzazione deterministica senza leggere `state` in listener immediati.
    final businessesAsync = ref.watch(businessesProvider);
    return businessesAsync.when(
      data: (businesses) {
        if (businesses.isEmpty) return 0;
        final selectedBusiness = ref.watch(superadminSelectedBusinessProvider);
        if (isSuperadmin && selectedBusiness != null) {
          if (businesses.any((b) => b.id == selectedBusiness)) {
            return selectedBusiness;
          }
        }
        return businesses.first.id;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  /// Selezione esplicita effettuata dall'utente (switch business).
  void selectByUser(int id) {
    if (state != id) {
      state = id;
    }
  }
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
    data: (businesses) {
      if (businesses.isEmpty) {
        return Business(id: 0, name: 'Loading...', createdAt: DateTime.now());
      }

      if (currentId <= 0) {
        return businesses.first;
      }

      final match = businesses.where((b) => b.id == currentId);
      if (match.isNotEmpty) {
        return match.first;
      }

      // Evita fallback silenzioso al primo business quando l'ID corrente
      // è stale/non valido: i provider dipendenti attendono un ID valido.
      return Business(id: 0, name: 'Loading...', createdAt: DateTime.now());
    },
    loading: () =>
        Business(id: currentId, name: 'Loading...', createdAt: DateTime.now()),
    error: (_, __) =>
        Business(id: currentId, name: 'Error', createdAt: DateTime.now()),
  );
});
