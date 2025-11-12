import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import 'service_categories_provider.dart';
import 'services_provider.dart';

/// Liste ordinate per sortOrder (e poi per nome come tie-breaker)
final sortedCategoriesProvider = Provider<List<ServiceCategory>>((ref) {
  final cats = ref.watch(serviceCategoriesProvider);
  final copy = [...cats];
  copy.sort((a, b) {
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
