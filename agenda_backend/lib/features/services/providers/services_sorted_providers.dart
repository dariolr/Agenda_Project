import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_package.dart';
import 'service_categories_provider.dart';
import 'service_packages_provider.dart';
import 'services_provider.dart';

class ServiceCategoryEntry {
  final Service? service;
  final ServicePackage? package;

  const ServiceCategoryEntry._({this.service, this.package});

  const ServiceCategoryEntry.service(Service service)
    : this._(service: service);

  const ServiceCategoryEntry.package(ServicePackage package)
    : this._(package: package);

  bool get isService => service != null;

  int get id => service?.id ?? package!.id;

  int get categoryId => service?.categoryId ?? package!.categoryId;

  int get sortOrder => service?.sortOrder ?? package!.sortOrder;

  String get name => service?.name ?? package!.name;

  String get key => isService ? 'service-$id' : 'package-$id';
}

/// Liste ordinate con queste priorità:
/// 1) Categorie con servizi prima, categorie vuote in coda
/// 2) sortOrder crescente
/// 3) nome come tie-breaker
final sortedCategoriesProvider = Provider<List<ServiceCategory>>((ref) {
  final cats = ref.watch(serviceCategoriesProvider);

  // Pre-calcolo: per ogni categoria verifichiamo se ha servizi.
  final hasServicesMap = <int, bool>{
    for (final c in cats)
      c.id: ref.watch(servicesByCategoryProvider(c.id)).isNotEmpty ||
          ref.watch(servicePackagesByCategoryProvider(c.id)).isNotEmpty,
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

final servicePackagesByCategoryProvider =
    Provider.family<List<ServicePackage>, int>((ref, categoryId) {
      final packages = ref.watch(servicePackagesProvider).value ?? [];
      final services = ref.watch(servicesProvider).value ?? const [];
      final serviceById = {for (final s in services) s.id: s};
      return packages
          .map((p) {
            if (p.categoryId != 0) return p;
            final effectiveCategoryId = p.items.isNotEmpty
                ? serviceById[p.items.first.serviceId]?.categoryId
                : null;
            if (effectiveCategoryId == null || effectiveCategoryId == 0) {
              return p;
            }
            return p.copyWith(categoryId: effectiveCategoryId);
          })
          .where((p) => p.categoryId == categoryId)
          .toList();
    });

final sortedServicePackagesByCategoryProvider =
    Provider.family<List<ServicePackage>, int>((ref, categoryId) {
      final packages = ref.watch(servicePackagesByCategoryProvider(categoryId));
      final copy = [...packages];
      copy.sort((a, b) {
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0
            ? so
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return copy;
    });

final sortedCategoryEntriesProvider =
    Provider.family<List<ServiceCategoryEntry>, int>((ref, categoryId) {
      final services = ref.watch(sortedServicesByCategoryProvider(categoryId));
      final packages = ref.watch(
        sortedServicePackagesByCategoryProvider(categoryId),
      );
      final entries = <ServiceCategoryEntry>[
        for (final service in services)
          ServiceCategoryEntry.service(service),
        for (final package in packages)
          ServiceCategoryEntry.package(package),
      ];
      entries.sort((a, b) {
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0
            ? so
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return entries;
    });
