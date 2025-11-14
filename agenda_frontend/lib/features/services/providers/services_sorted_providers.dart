import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import 'service_categories_provider.dart';
import 'services_provider.dart';

/// Liste ordinate con queste priorità:
/// 1) Categorie con servizi prima, categorie vuote in coda
/// 2) sortOrder crescente
/// 3) nome come tie-breaker
final sortedCategoriesProvider = Provider<List<ServiceCategory>>((ref) {
  final cats = ref.watch(serviceCategoriesProvider);

  // Pre-calcolo: per ogni categoria verifichiamo se ha servizi.
  final hasServicesMap = <int, bool>{
    for (final c in cats)
      c.id: ref.watch(servicesByCategoryProvider(c.id)).isNotEmpty,
  };

  final copy = [...cats];
  copy.sort((a, b) {
    final aEmpty = !(hasServicesMap[a.id] ?? false);
    final bEmpty = !(hasServicesMap[b.id] ?? false);

    // Vuote in coda: una categoria vuota deve venire dopo una non vuota.
    if (aEmpty != bEmpty) return aEmpty ? 1 : -1;

    final so = a.sortOrder.compareTo(b.sortOrder);
    return so != 0 ? so : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return copy;
});

final sortedServicesByCategoryProvider = Provider.family<List<Service>, int>((
  ref,
  categoryId,
) {
  final services = ref.watch(servicesByCategoryProvider(categoryId));
  final copy = [...services];
  copy.sort((a, b) {
    final so = a.sortOrder.compareTo(b.sortOrder);
    return so != 0 ? so : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return copy;
});
