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
  void _setFromSystem(int id) {
    if (state != id) {
      state = id;
    }
  }

  @override
  int build() {
    // ✅ Imposta come default il business selezionato (superadmin)
    // oppure il primo business disponibile.
    final authState = ref.watch(authProvider);
    final isSuperadmin = authState.user?.isSuperadmin ?? false;

    // Allinea al business selezionato quando cambia
    ref.listen(superadminSelectedBusinessProvider, (previous, next) {
      if (!isSuperadmin) return;
      if (next != null && state != next) {
        _setFromSystem(next);
      }
    });

    // Aspetta che businessesProvider carichi i dati
    ref.listen(businessesProvider, (previous, next) {
      next.whenData((businesses) {
        if (businesses.isEmpty) {
          _setFromSystem(0);
          return;
        }

        final selectedBusiness = ref.read(superadminSelectedBusinessProvider);

        if (isSuperadmin && selectedBusiness != null) {
          final exists = businesses.any((b) => b.id == selectedBusiness);
          if (exists) {
            _setFromSystem(selectedBusiness);
            return;
          }

          // Business non più valido: pulisci preferenze e fallback al primo
          ref
              .read(superadminSelectedBusinessProvider.notifier)
              .clearCompletely();
          _setFromSystem(businesses.first.id);
          return;
        }

        // Utente non superadmin:
        // mantieni sempre un business valido (mai 0) per evitare rimbalzi di routing
        // quando la lista viene ricaricata o cambia dinamicamente.
        if (state == 0) {
          _setFromSystem(businesses.first.id);
          return;
        }

        // Se il business corrente non è più accessibile, fallback al primo disponibile.
        if (!businesses.any((b) => b.id == state)) {
          _setFromSystem(businesses.first.id);
          return;
        }
      });
    });
    return 0; // Inizializza a 0 per triggare il listen
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
