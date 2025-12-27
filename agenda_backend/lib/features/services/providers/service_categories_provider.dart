import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../agenda/providers/business_providers.dart';
import '../utils/service_seed_texts.dart';
import 'services_provider.dart';

/// Notifier per la gestione delle categorie di servizi (CRUD in memoria)
class ServiceCategoriesNotifier extends Notifier<List<ServiceCategory>> {
  @override
  List<ServiceCategory> build() {
    final business = ref.watch(currentBusinessProvider);
    // Seed iniziale (spostato qui dal vecchio services_provider)
    final seed = <ServiceCategory>[
      ServiceCategory(
        id: 10,
        businessId: business.id,
        name: ServiceSeedTexts.categoryBodyName,
        description: ServiceSeedTexts.categoryBodyDescription,
        sortOrder: 0,
      ),
      ServiceCategory(
        id: 11,
        businessId: business.id,
        name: ServiceSeedTexts.categorySportsName,
        description: ServiceSeedTexts.categorySportsDescription,
        sortOrder: 1,
      ),
      ServiceCategory(
        id: 12,
        businessId: business.id,
        name: ServiceSeedTexts.categoryFaceName,
        description: ServiceSeedTexts.categoryFaceDescription,
        sortOrder: 2,
      ),
    ];
    return _sorted(seed);
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
