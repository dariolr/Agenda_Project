import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_staff_eligibility.dart';
import '../../../core/models/service_variant.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../staff/providers/staff_providers.dart';
import '../utils/service_seed_texts.dart';
import 'service_categories_provider.dart';
import 'services_repository_provider.dart';

// Le categorie sono ora gestite in providers/service_categories_provider.dart

///
/// SERVICES PER LOCATION IDS (per staff dialog)
///
/// Carica servizi da multiple location. Usato nel dialog staff per mostrare
/// solo i servizi delle location assegnate allo staff.
///
class ServicesForLocationsResult {
  final List<Service> services;
  final List<ServiceCategory> categories;

  const ServicesForLocationsResult({
    required this.services,
    required this.categories,
  });
}

/// Provider che carica servizi per una lista di location.
/// La chiave è una stringa con gli ID separati da virgola (es. "2,7").
/// Usare `locationIdsToKey` per convertire un `Set<int>` in chiave.
String locationIdsToKey(Set<int> locationIds) {
  final sorted = locationIds.toList()..sort();
  return sorted.join(',');
}

Set<int> keyToLocationIds(String key) {
  if (key.isEmpty) return {};
  return key.split(',').map(int.parse).toSet();
}

/// Trigger per forzare il refresh di servicesForLocationsProvider
/// Incrementato quando i servizi vengono creati/modificati/eliminati
class ServicesForLocationsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

final servicesForLocationsRefreshProvider =
    NotifierProvider<ServicesForLocationsRefreshNotifier, int>(
      ServicesForLocationsRefreshNotifier.new,
    );

final servicesForLocationsProvider =
    FutureProvider.family<ServicesForLocationsResult, String>((
      ref,
      locationIdsKey,
    ) async {
      // Watch del refresh trigger per invalidare la cache
      ref.watch(servicesForLocationsRefreshProvider);
      final locationIds = keyToLocationIds(locationIdsKey);

      if (locationIds.isEmpty) {
        return const ServicesForLocationsResult(services: [], categories: []);
      }

      final repository = ref.watch(servicesRepositoryProvider);
      final allServices = <Service>[];
      final categoryMap = <int, ServiceCategory>{};

      // Carica servizi da tutte le location
      for (final locationId in locationIds) {
        final result = await repository.getServicesWithCategories(
          locationId: locationId,
        );
        allServices.addAll(result.services);
        for (final cat in result.categories) {
          categoryMap[cat.id] = cat;
        }
      }

      // Ordina per nome
      allServices.sort((a, b) => a.name.compareTo(b.name));

      return ServicesForLocationsResult(
        services: allServices,
        categories: categoryMap.values.toList(),
      );
    });

///
/// SERVICES NOTIFIER (CRUD via API)
///
class ServicesNotifier extends AsyncNotifier<List<Service>> {
  @override
  Future<List<Service>> build() async {
    // Verifica autenticazione
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }
    final canManageServices = ref.watch(currentUserCanManageServicesProvider);

    final location = ref.watch(currentLocationProvider);
    if (location.id <= 0) {
      return [];
    }

    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId <= 0) {
      return [];
    }

    final repository = ref.watch(servicesRepositoryProvider);

    // Carica servizi E categorie dall'API
    final result = await repository.getServicesWithCategories(
      locationId: location.id,
    );

    // Per ruoli read-only (viewer) usiamo le categorie incluse in GET /services.
    // Per ruoli con manage_services usiamo la fonte gestionale dedicata.
    if (canManageServices) {
      final categories = await repository.getCategories(businessId);
      ref.read(serviceCategoriesProvider.notifier).setCategories(categories);
    } else {
      ref
          .read(serviceCategoriesProvider.notifier)
          .setCategories(result.categories);
    }

    return result.services;
  }

  /// Ricarica servizi e categorie dall'API
  Future<void> refresh() async {
    // Verifica autenticazione
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      return;
    }
    final canManageServices = ref.read(currentUserCanManageServicesProvider);

    final location = ref.read(currentLocationProvider);
    if (location.id <= 0) {
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) {
      return;
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(servicesRepositoryProvider);
      final result = await repository.getServicesWithCategories(
        locationId: location.id,
      );

      // Per ruoli read-only (viewer) usiamo le categorie incluse in GET /services.
      // Per ruoli con manage_services usiamo la fonte gestionale dedicata.
      if (canManageServices) {
        final categories = await repository.getCategories(businessId);
        ref.read(serviceCategoriesProvider.notifier).setCategories(categories);
      } else {
        ref
            .read(serviceCategoriesProvider.notifier)
            .setCategories(result.categories);
      }

      state = AsyncData(result.services);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void setServices(List<Service> services) {
    state = AsyncData(services);
  }

  // ===== API METHODS =====

  /// Creates a new service with variants for multiple locations via API
  Future<Service?> createServiceMultiLocationApi({
    required List<int> locationIds,
    required String name,
    int? categoryId,
    String? description,
    int durationMinutes = 30,
    double price = 0,
    String? colorHex,
    bool isBookableOnline = true,
    bool isPriceStartingFrom = false,
    int? processingTime,
    int? blockedTime,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    final businessId = ref.read(currentBusinessIdProvider);

    if (businessId <= 0 || locationIds.isEmpty) return null;

    try {
      final newService = await repository.createServiceMultiLocation(
        businessId: businessId,
        locationIds: locationIds,
        name: name,
        categoryId: categoryId,
        description: description,
        durationMinutes: durationMinutes,
        price: price,
        colorHex: colorHex,
        isBookableOnline: isBookableOnline,
        isPriceStartingFrom: isPriceStartingFrom,
        processingTime: processingTime,
        blockedTime: blockedTime,
      );

      // Add to local state only if current location is in the list
      final currentLocation = ref.read(currentLocationProvider);
      if (locationIds.contains(currentLocation.id)) {
        final current = state.value ?? [];
        state = AsyncData([...current, newService]);

        ref
            .read(serviceCategoriesProvider.notifier)
            .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
      }

      return newService;
    } catch (e) {
      // Keep old state on error
      return null;
    }
  }

  /// Creates a new service via API and updates local state (legacy, single location)
  Future<Service?> createServiceApi({
    required String name,
    int? categoryId,
    String? description,
    int durationMinutes = 30,
    double price = 0,
    String? colorHex,
    bool isBookableOnline = true,
    bool isPriceStartingFrom = false,
    int? processingTime,
    int? blockedTime,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    final location = ref.read(currentLocationProvider);

    if (location.id <= 0) return null;

    try {
      final newService = await repository.createService(
        locationId: location.id,
        name: name,
        categoryId: categoryId,
        description: description,
        durationMinutes: durationMinutes,
        price: price,
        colorHex: colorHex,
        isBookableOnline: isBookableOnline,
        isPriceStartingFrom: isPriceStartingFrom,
        processingTime: processingTime,
        blockedTime: blockedTime,
      );

      // Add to local state
      final current = state.value ?? [];
      state = AsyncData([...current, newService]);

      // Trigger refresh of servicesForLocationsProvider
      // so staff dialog will see the new service
      ref.read(servicesForLocationsRefreshProvider.notifier).trigger();

      ref
          .read(serviceCategoriesProvider.notifier)
          .bumpEmptyCategoriesToEnd(servicesOverride: state.value);

      return newService;
    } catch (e) {
      // Keep old state on error
      return null;
    }
  }

  /// Updates a service via API and updates local state
  Future<Service?> updateServiceApi({
    required int serviceId,
    String? name,
    int? categoryId,
    bool setCategoryIdNull = false,
    String? description,
    bool setDescriptionNull = false,
    int? durationMinutes,
    double? price,
    String? colorHex,
    bool? isBookableOnline,
    bool? isPriceStartingFrom,
    int? sortOrder,
    int? processingTime,
    int? blockedTime,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    final location = ref.read(currentLocationProvider);

    if (location.id <= 0) return null;

    try {
      final updatedService = await repository.updateService(
        serviceId: serviceId,
        locationId: location.id,
        name: name,
        categoryId: categoryId,
        setCategoryIdNull: setCategoryIdNull,
        description: description,
        setDescriptionNull: setDescriptionNull,
        durationMinutes: durationMinutes,
        price: price,
        colorHex: colorHex,
        isBookableOnline: isBookableOnline,
        isPriceStartingFrom: isPriceStartingFrom,
        sortOrder: sortOrder,
        processingTime: processingTime,
        blockedTime: blockedTime,
      );

      // Update local state
      final current = state.value ?? [];
      state = AsyncData([
        for (final s in current)
          if (s.id == updatedService.id) updatedService else s,
      ]);

      // Trigger refresh of servicesForLocationsProvider
      ref.read(servicesForLocationsRefreshProvider.notifier).trigger();

      ref
          .read(serviceCategoriesProvider.notifier)
          .bumpEmptyCategoriesToEnd(servicesOverride: state.value);

      return updatedService;
    } catch (e) {
      return null;
    }
  }

  /// Deletes a service via API and updates local state
  Future<bool> deleteServiceApi(int serviceId) async {
    final repository = ref.read(servicesRepositoryProvider);

    try {
      await repository.deleteService(serviceId);

      // Remove from local state
      final current = state.value ?? [];
      final newList = current.where((s) => s.id != serviceId).toList();
      state = AsyncData(newList);

      ref.read(serviceVariantsProvider.notifier).removeByServiceId(serviceId);

      // Trigger refresh of servicesForLocationsProvider
      ref.read(servicesForLocationsRefreshProvider.notifier).trigger();

      ref
          .read(serviceCategoriesProvider.notifier)
          .bumpEmptyCategoriesToEnd(servicesOverride: newList);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the location IDs where a service has active variants
  Future<List<int>> getServiceLocationsApi(int serviceId) async {
    final repository = ref.read(servicesRepositoryProvider);
    return repository.getServiceLocations(serviceId);
  }

  /// Updates the locations associated with a service
  /// Returns true on success, false on failure
  Future<bool> updateServiceLocationsApi({
    required int serviceId,
    required List<int> locationIds,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    try {
      await repository.updateServiceLocations(
        serviceId: serviceId,
        locationIds: locationIds,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Duplicates a service via API (creates new with modified name)
  Future<Service?> duplicateServiceApi(Service original) async {
    final current = state.value ?? [];
    final existingNames = current.map((s) => s.name).toSet();
    final duplicateName = _makeDuplicateName(original.name, existingNames);

    return createServiceApi(
      name: duplicateName,
      categoryId: original.categoryId,
      description: original.description,
      durationMinutes: original.durationMinutes ?? 30,
      price: original.price ?? 0,
      colorHex: original.color,
      isPriceStartingFrom: original.isPriceStartingFrom,
    );
  }

  // ===== LOCAL METHODS (legacy, for backward compatibility) =====

  @Deprecated('Use createServiceApi instead for persistence')
  void add(Service service) {
    final current = state.value ?? [];
    state = AsyncData([...current, service]);
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
  }

  @Deprecated('Use updateServiceApi instead for persistence')
  void updateService(Service updated) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final s in current)
        if (s.id == updated.id) updated else s,
    ]);
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
  }

  @Deprecated('Use deleteServiceApi instead for persistence')
  void delete(int id) {
    final current = state.value ?? [];
    final newList = current.where((s) => s.id != id).toList();
    state = AsyncData(newList);
    ref.read(serviceVariantsProvider.notifier).removeByServiceId(id);
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: newList);
  }

  @Deprecated('Use duplicateServiceApi instead for persistence')
  void duplicate(Service original) {
    final current = state.value ?? [];
    final newId = _nextId(current);
    final existingNames = current.map((s) => s.name).toSet();

    final copy = Service(
      id: newId,
      businessId: original.businessId,
      categoryId: original.categoryId,
      name: _makeDuplicateName(original.name, existingNames),
      description: original.description,
    );
    add(copy);

    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state.value);
  }

  // ===== HELPER METHODS =====

  String _makeDuplicateName(String originalName, Set<String> existingNames) {
    final copyWord = ServiceSeedTexts.duplicateCopyWord;
    final copyWordEscaped = RegExp.escape(copyWord);
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

    String candidate = '$base $copyWord';
    if (!existingNames.contains(candidate)) return candidate;

    int i = startFrom ?? 1;
    while (true) {
      candidate = '$base $copyWord $i';
      if (!existingNames.contains(candidate)) return candidate;
      i++;
      if (i > 9999) break;
    }
    return '$base $copyWord';
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
/// VARIANTI SERVIZI (da API, filtrate per location)
///
class ServiceVariantsNotifier extends AsyncNotifier<List<ServiceVariant>> {
  @override
  Future<List<ServiceVariant>> build() async {
    final services = await ref.watch(servicesProvider.future);
    final location = ref.watch(currentLocationProvider);
    final currency = ref.watch(effectiveCurrencyProvider);

    // Map services to variants usando ID reale da API
    return services
        .map(
          (s) => ServiceVariant(
            // Usa serviceVariantId da API se disponibile, altrimenti fallback
            id: s.serviceVariantId ?? s.id,
            serviceId: s.id,
            locationId: location.id,
            durationMinutes: s.durationMinutes ?? 30,
            price: s.price ?? 0.0,
            colorHex: s.color ?? '#CCCCCC',
            currency: currency,
            isBookableOnline: s.isBookableOnline,
            isFree: (s.price ?? 0) == 0,
            isPriceStartingFrom: s.isPriceStartingFrom,
            resourceRequirements: s.resourceRequirements,
            processingTime: s.processingTime ?? 0,
            blockedTime: s.blockedTime ?? 0,
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
/// Questo provider ora legge i service_ids direttamente dal modello Staff
/// che è stato caricato dall'API. Non usa più dati mock.
///
class ServiceStaffEligibilityNotifier
    extends Notifier<List<ServiceStaffEligibility>> {
  @override
  List<ServiceStaffEligibility> build() {
    // Legge da allStaffProvider per costruire l'eligibilità
    final staffAsync = ref.watch(allStaffProvider);
    final staffList = staffAsync.value ?? [];

    final List<ServiceStaffEligibility> eligibilities = [];
    for (final staff in staffList) {
      for (final serviceId in staff.serviceIds) {
        // Per ogni location dello staff, crea un'eligibilità
        if (staff.locationIds.isEmpty) {
          // Staff disponibile in tutte le location
          eligibilities.add(
            ServiceStaffEligibility(serviceId: serviceId, staffId: staff.id),
          );
        } else {
          for (final locationId in staff.locationIds) {
            eligibilities.add(
              ServiceStaffEligibility(
                serviceId: serviceId,
                staffId: staff.id,
                locationId: locationId,
              ),
            );
          }
        }
      }
    }
    return eligibilities;
  }

  /// Metodo per aggiornare lo stato locale (solo UI)
  /// L'effettivo salvataggio avviene tramite StaffNotifier.updateStaffApi
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

  /// Metodo per aggiornare lo stato locale (solo UI)
  /// L'effettivo salvataggio avviene tramite StaffNotifier.updateStaffApi
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
  // Legge direttamente dal modello Staff invece di usare serviceStaffEligibilityProvider
  final staffAsync = ref.watch(allStaffProvider);
  final staffList = staffAsync.value ?? [];
  final staff = staffList.where((s) => s.id == staffId).firstOrNull;
  return staff?.serviceIds ?? [];
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
