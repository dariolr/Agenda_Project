import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import 'services_provider.dart';

/// Notifier per la gestione delle categorie di servizi (CRUD in memoria)
/// Le categorie vengono inizializzate vuote e popolate dal ServicesNotifier
/// quando i dati vengono caricati dall'API.
class ServiceCategoriesNotifier extends Notifier<List<ServiceCategory>> {
  @override
  List<ServiceCategory> build() {
    // Inizia vuoto - le categorie vengono caricate dall'API insieme ai servizi
    return [];
  }

  /// Imposta le categorie caricate dall'API
  void setCategories(List<ServiceCategory> categories) {
    state = _sorted(categories);
  }

  List<ServiceCategory> _sorted(List<ServiceCategory> list) {
    final copy = [...list];
    copy.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  void addCategory(ServiceCategory newCategory) {
    final nextSort = state.isEmpty
        ? 0
        : (state.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
    final withOrder = newCategory.copyWith(sortOrder: nextSort);
    state = _sorted([...state, withOrder]);
    // Se la nuova categoria è vuota, deve andare in coda per sortOrder alto
    bumpEmptyCategoriesToEnd();
  }

  void updateCategory(ServiceCategory updatedCategory) {
    state = _sorted([
      for (final c in state)
        if (c.id == updatedCategory.id) updatedCategory else c,
    ]);
  }

  void deleteCategory(int id) {
    state = _sorted(state.where((c) => c.id != id).toList());
  }

  /// Imposta un sortOrder elevato per le categorie senza servizi,
  /// in modo che siano naturalmente in coda all'ordinamento.
  ///
  /// Per evitare dipendenze circolari quando chiamata da ServicesNotifier,
  /// si può passare la lista servizi già aggiornata tramite [servicesOverride].
  void bumpEmptyCategoriesToEnd({List<Service>? servicesOverride}) {
    final List<Service> services =
        servicesOverride ?? (ref.read(servicesProvider).value ?? []);
    final nonEmptyCatIds = <int>{for (final s in services) s.categoryId};

    int maxNonEmptySort = -1;
    for (final c in state) {
      if (nonEmptyCatIds.contains(c.id)) {
        if (c.sortOrder > maxNonEmptySort) maxNonEmptySort = c.sortOrder;
      }
    }

    // Base alta per evitare collisioni con futuri riordini
    final base = (maxNonEmptySort < 0 ? 0 : maxNonEmptySort + 1) + 1000;
    int offset = 0;

    final updated = [
      for (final c in state)
        if (nonEmptyCatIds.contains(c.id))
          c
        else
          c.copyWith(sortOrder: base + offset++),
    ];

    state = _sorted(updated);
  }
}

final serviceCategoriesProvider =
    NotifierProvider<ServiceCategoriesNotifier, List<ServiceCategory>>(
      ServiceCategoriesNotifier.new,
    );
