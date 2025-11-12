import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_category.dart';
import '../../agenda/providers/business_providers.dart';

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
        name: 'Trattamenti Corpo',
        description: 'Servizi dedicati al benessere del corpo',
        sortOrder: 0,
      ),
      ServiceCategory(
        id: 11,
        businessId: business.id,
        name: 'Trattamenti Sportivi',
        description: 'Percorsi pensati per atleti e persone attive',
        sortOrder: 1,
      ),
      ServiceCategory(
        id: 12,
        businessId: business.id,
        name: 'Trattamenti Viso',
        description: 'Cura estetica e rigenerante per il viso',
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
}

final serviceCategoriesProvider =
    NotifierProvider<ServiceCategoriesNotifier, List<ServiceCategory>>(
      ServiceCategoriesNotifier.new,
    );
