import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_staff_eligibility.dart';
import '../../../core/models/service_variant.dart';
import '../../agenda/providers/location_providers.dart';
import '../utils/service_seed_texts.dart';
import 'service_categories_provider.dart';
import 'services_repository_provider.dart';

// Le categorie sono ora gestite in providers/service_categories_provider.dart

///
/// SERVICES NOTIFIER (CRUD in memoria)
///
class ServicesNotifier extends AsyncNotifier<List<Service>> {
  @override
  Future<List<Service>> build() async {
    final repository = ref.watch(servicesRepositoryProvider);
    final location = ref.watch(currentLocationProvider);

    // Carica servizi E categorie dall'API
    final result = await repository.getServicesWithCategories(locationId: location.id);
    
    // Popola le categorie nel provider dedicato
    ref.read(serviceCategoriesProvider.notifier).setCategories(result.categories);
    
    return result.services;
  }

  void setServices(List<Service> services) {
    state = AsyncData(services);
  }

  void add(Service service) {
    final current = state.value ?? [];
    state = AsyncData([...current, service]);
    // Aggiunta di un servizio potrebbe rendere non vuota una categoria
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
  }

  void updateService(Service updated) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final s in current)
        if (s.id == updated.id) updated else s,
    ]);
    // Aggiorna posizionamento categorie vuote vs piene
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
  }

  void delete(int id) {
    final current = state.value ?? [];
    // int? removedCat;
    // for (final s in current) {
    //   if (s.id == id) {
    //     removedCat = s.categoryId;
    //     break;
    //   }
    // }
    final newList = current.where((s) => s.id != id).toList();
    state = AsyncData(newList);

    ref.read(serviceVariantsProvider.notifier).removeByServiceId(id);

    // Aggiorna posizionamento categorie vuote vs piene
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: newList);
  }

  void duplicate(Service original) {
    final current = state.value ?? [];
    final newId = _nextId(current);
    final existingNames = current.map((s) => s.name).toSet();

    String makeDuplicateName(String originalName) {
      final copyWord = ServiceSeedTexts.duplicateCopyWord;
      final copyWordEscaped = RegExp.escape(copyWord);
      // Supporta varianti precedenti come " (copyWord)" e la nuova " copyWord"/" copyWord N"
      String base = originalName;
      int? startFrom;

      final reNew = RegExp(
        '^(.*?)(?:\\s$copyWordEscaped(?:\\s(\\d+))?)\$',
        caseSensitive: false,
      );
      final reOld = RegExp(
        '^(.*?)(?:\\s\\((?:$copyWordEscaped)(?:\\s(\\d+))?\\))\$',
        caseSensitive: false,
      );

      RegExpMatch? m =
          reNew.firstMatch(originalName) ?? reOld.firstMatch(originalName);
      if (m != null) {
        base = (m.group(1) ?? '').trim();
        final n = m.group(2);
        if (n != null) {
          final parsed = int.tryParse(n);
          if (parsed != null) startFrom = parsed + 1;
        } else {
          startFrom = 1;
        }
      }

      // Primo tentativo: "<base> <copyWord>"
      String candidate = '$base $copyWord';
      if (!existingNames.contains(candidate)) return candidate;

      // Altrimenti prova con numeri incrementali
      int i = startFrom ?? 1;
      while (true) {
        candidate = '$base $copyWord $i';
        if (!existingNames.contains(candidate)) return candidate;
        i++;
        if (i > 9999) break; // guardia
      }
      // Fallback improbabile
      return '$base $copyWord';
    }

    final copy = Service(
      id: newId,
      businessId: original.businessId,
      categoryId: original.categoryId,
      name: makeDuplicateName(original.name),
      description: original.description,
    );
    add(copy);

    // Note: serviceVariantByServiceIdProvider needs to handle async now
    // But here we are inside notifier, we can't easily read async provider synchronously
    // So we skip variant duplication for now or handle it differently
    // Or we can read serviceVariantsProvider.future

    // final originalVariant = ref.read(
    //   serviceVariantByServiceIdProvider(original.id),
    // );
    // if (originalVariant != null) {
    //   ref.read(serviceVariantsProvider.notifier).upsert(
    //         originalVariant.copyWith(
    //           id: 900000 + newId,
    //           serviceId: newId,
    //         ),
    //       );
    // }

    // Un duplicato potrebbe rendere non vuota una categoria
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
  }

  int _nextId(List<Service> current) {
    if (current.isEmpty) return 1;
    final maxId = current.map((s) => s.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}

final servicesProvider = AsyncNotifierProvider<ServicesNotifier, List<Service>>(
  ServicesNotifier.new,
);

///
/// VARIANTI SERVIZI (mock, filtrate per location)
///
class ServiceVariantsNotifier extends AsyncNotifier<List<ServiceVariant>> {
  @override
  Future<List<ServiceVariant>> build() async {
    final services = await ref.watch(servicesProvider.future);
    final location = ref.watch(currentLocationProvider);
    final currency = ref.watch(effectiveCurrencyProvider);

    // Map services to variants
    return services
        .map(
          (s) => ServiceVariant(
            id: 900000 + s.id, // Mock ID generation for variant
            serviceId: s.id,
            locationId: location.id,
            durationMinutes: s.durationMinutes ?? 30,
            price: s.price ?? 0.0,
            colorHex: s.color ?? '#CCCCCC',
            currency: currency,
            isBookableOnline: true,
            isFree: (s.price ?? 0) == 0,
            isPriceStartingFrom: false,
            resourceRequirements: const [],
            processingTime: 0,
            blockedTime: 0,
          ),
        )
        .toList();
  }

  void upsert(ServiceVariant variant) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final v in current)
        if (v.id == variant.id) variant else v,
      if (!current.any((v) => v.id == variant.id)) variant,
    ]);
  }

  void removeByServiceId(int serviceId) {
    final current = state.value ?? [];
    state = AsyncData(current.where((v) => v.serviceId != serviceId).toList());
  }
}

final serviceVariantsProvider =
    AsyncNotifierProvider<ServiceVariantsNotifier, List<ServiceVariant>>(
      ServiceVariantsNotifier.new,
    );

///
/// SERVICE VARIANT BY ID
///
final serviceVariantByIdProvider = Provider.family<ServiceVariant?, int>((
  ref,
  variantId,
) {
  final variantsAsync = ref.watch(serviceVariantsProvider);
  final variants = variantsAsync.value ?? [];
  for (final variant in variants) {
    if (variant.id == variantId) return variant;
  }
  return null;
});

final serviceVariantByServiceIdProvider = Provider.family<ServiceVariant?, int>(
  (ref, serviceId) {
    final location = ref.watch(currentLocationProvider);
    final variantsAsync = ref.watch(serviceVariantsProvider);
    final variants = variantsAsync.value ?? [];
    for (final variant in variants) {
      if (variant.serviceId == serviceId && variant.locationId == location.id) {
        return variant;
      }
    }
    return null;
  },
);

///
/// ELIGIBILITY STAFF
///
class ServiceStaffEligibilityNotifier
    extends Notifier<List<ServiceStaffEligibility>> {
  @override
  List<ServiceStaffEligibility> build() {
    return const [
      ServiceStaffEligibility(serviceId: 1, staffId: 1, locationId: 101),
      ServiceStaffEligibility(serviceId: 1, staffId: 3, locationId: 101),
      ServiceStaffEligibility(serviceId: 1, staffId: 2, locationId: 102),
      ServiceStaffEligibility(serviceId: 1, staffId: 3, locationId: 102),
      ServiceStaffEligibility(serviceId: 2, staffId: 3),
      ServiceStaffEligibility(serviceId: 2, staffId: 4, locationId: 101),
      ServiceStaffEligibility(serviceId: 2, staffId: 2, locationId: 102),
      ServiceStaffEligibility(serviceId: 3, staffId: 1, locationId: 101),
      ServiceStaffEligibility(serviceId: 3, staffId: 2, locationId: 102),
      ServiceStaffEligibility(serviceId: 3, staffId: 3, locationId: 102),
    ];
  }

  void setEligibleStaffForService({
    required int serviceId,
    required int locationId,
    required Iterable<int> staffIds,
  }) {
    final retained = [
      for (final entry in state)
        if (!(entry.serviceId == serviceId &&
            (entry.locationId == null || entry.locationId == locationId)))
          entry,
    ];
    final updated = [
      for (final staffId in staffIds)
        ServiceStaffEligibility(
          serviceId: serviceId,
          staffId: staffId,
          locationId: locationId,
        ),
    ];
    state = [...retained, ...updated];
  }

  void setEligibleServicesForStaff({
    required int staffId,
    required int locationId,
    required Iterable<int> serviceIds,
  }) {
    final retained = [
      for (final entry in state)
        if (!(entry.staffId == staffId &&
            (entry.locationId == null || entry.locationId == locationId)))
          entry,
    ];
    final updated = [
      for (final serviceId in serviceIds)
        ServiceStaffEligibility(
          serviceId: serviceId,
          staffId: staffId,
          locationId: locationId,
        ),
    ];
    state = [...retained, ...updated];
  }
}

final serviceStaffEligibilityProvider =
    NotifierProvider<
      ServiceStaffEligibilityNotifier,
      List<ServiceStaffEligibility>
    >(ServiceStaffEligibilityNotifier.new);

final eligibleStaffForServiceProvider = Provider.family<List<int>, int>((
  ref,
  serviceId,
) {
  final location = ref.watch(currentLocationProvider);
  final elegibility = ref.watch(serviceStaffEligibilityProvider);

  return [
    for (final entry in elegibility)
      if (entry.serviceId == serviceId &&
          (entry.locationId == null || entry.locationId == location.id))
        entry.staffId,
  ];
});

final eligibleServicesForStaffProvider = Provider.family<List<int>, int>((
  ref,
  staffId,
) {
  final location = ref.watch(currentLocationProvider);
  final eligibilities = ref.watch(serviceStaffEligibilityProvider);
  return [
    for (final entry in eligibilities)
      if (entry.staffId == staffId &&
          (entry.locationId == null || entry.locationId == location.id))
        entry.serviceId,
  ];
});

///
/// SERVICES PER CATEGORIA
///
final servicesByCategoryProvider = Provider.family<List<Service>, int>((
  ref,
  categoryId,
) {
  final servicesAsync = ref.watch(servicesProvider);
  final services = servicesAsync.value ?? [];
  return [
    for (final service in services)
      if (service.categoryId == categoryId) service,
  ];
});
