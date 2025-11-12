import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_staff_eligibility.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/utils/color_utils.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';

// Le categorie sono ora gestite in providers/service_categories_provider.dart

///
/// SERVICES NOTIFIER (CRUD in memoria)
///
class ServicesNotifier extends Notifier<List<Service>> {
  @override
  List<Service> build() {
    final business = ref.watch(currentBusinessProvider);
    final currency = ref.watch(effectiveCurrencyProvider); // 🔹 valuta coerente

    return [
      Service(
        id: 1,
        businessId: business.id,
        categoryId: 10,
        name: 'Massaggio Relax',
        description: 'Trattamento rilassante da 30 minuti',
        duration: 30,
        price: 45,
        color: ColorUtils.fromHex('#6EC5A6'),
        isBookableOnline: true,
        isFree: false,
        isPriceStartingFrom: false,
        currency: currency,
      ),
      Service(
        id: 2,
        businessId: business.id,
        categoryId: 11,
        name: 'Massaggio Sportivo',
        description: 'Trattamento decontratturante intensivo',
        duration: 45,
        price: 60,
        color: ColorUtils.fromHex('#57A0D3'),
        isBookableOnline: true,
        isFree: false,
        isPriceStartingFrom: true,
        currency: currency,
      ),
      Service(
        id: 3,
        businessId: business.id,
        categoryId: 12,
        name: 'Trattamento Viso',
        description: 'Pulizia e trattamento illuminante',
        duration: 40,
        price: 55,
        color: ColorUtils.fromHex('#F4B942'),
        isBookableOnline: false,
        isFree: false,
        isPriceStartingFrom: false,
        currency: currency,
      ),
    ];
  }

  void add(Service service) => state = [...state, service];

  void update(Service updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
  }

  void delete(int id) {
    state = state.where((s) => s.id != id).toList();
  }

  void duplicate(Service original) {
    final newId = _nextId();
    final copy = Service(
      id: newId,
      businessId: original.businessId,
      categoryId: original.categoryId,
      name: '${original.name} (copia)',
      description: original.description,
      duration: original.duration,
      price: original.price,
      color: original.color,
      isBookableOnline: original.isBookableOnline,
      isFree: original.isFree,
      isPriceStartingFrom: original.isPriceStartingFrom,
      currency: original.currency, // 🔹 mantiene la stessa valuta
    );
    add(copy);
  }

  int _nextId() {
    if (state.isEmpty) return 1;
    final maxId = state.map((s) => s.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}

final servicesProvider = NotifierProvider<ServicesNotifier, List<Service>>(
  ServicesNotifier.new,
);

///
/// VARIANTI SERVIZI (mock, filtrate per location)
///
final serviceVariantsProvider = Provider<List<ServiceVariant>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final currency = ref.watch(effectiveCurrencyProvider); // 🔹 valuta effettiva

  // Mock variants personalizzate per sede e valuta
  return [
    ServiceVariant(
      id: 1001,
      serviceId: 1,
      locationId: 101,
      durationMinutes: 30,
      price: 45,
      colorHex: '#6EC5A6',
      currency: currency,
    ),
    ServiceVariant(
      id: 1002,
      serviceId: 1,
      locationId: 102,
      durationMinutes: 35,
      price: 48,
      colorHex: '#6EC5A6',
      currency: currency,
    ),
    ServiceVariant(
      id: 2001,
      serviceId: 2,
      locationId: 101,
      durationMinutes: 45,
      price: 62,
      colorHex: '#57A0D3',
      currency: currency,
    ),
    ServiceVariant(
      id: 2002,
      serviceId: 2,
      locationId: 102,
      durationMinutes: 50,
      price: 65,
      colorHex: '#57A0D3',
      currency: currency,
    ),
    ServiceVariant(
      id: 3001,
      serviceId: 3,
      locationId: 101,
      durationMinutes: 40,
      price: 55,
      colorHex: '#F4B942',
      currency: currency,
    ),
    ServiceVariant(
      id: 3002,
      serviceId: 3,
      locationId: 102,
      durationMinutes: 45,
      price: 58,
      colorHex: '#F4B942',
      currency: currency,
    ),
  ].where((variant) => variant.locationId == location.id).toList();
});

///
/// SERVICE VARIANT BY ID
///
final serviceVariantByIdProvider = Provider.family<ServiceVariant?, int>((
  ref,
  variantId,
) {
  final variants = ref.watch(serviceVariantsProvider);
  for (final variant in variants) {
    if (variant.id == variantId) return variant;
  }
  return null;
});

///
/// ELIGIBILITY STAFF
///
final serviceStaffEligibilityProvider = Provider<List<ServiceStaffEligibility>>(
  (ref) {
    return const [
      ServiceStaffEligibility(serviceId: 1, staffId: 1, locationId: 101),
      ServiceStaffEligibility(serviceId: 1, staffId: 3, locationId: 101),
      ServiceStaffEligibility(serviceId: 1, staffId: 2, locationId: 102),
      ServiceStaffEligibility(serviceId: 1, staffId: 3, locationId: 102),
      ServiceStaffEligibility(serviceId: 2, staffId: 3),
      ServiceStaffEligibility(serviceId: 2, staffId: 4, locationId: 101),
      ServiceStaffEligibility(serviceId: 2, staffId: 5, locationId: 102),
      ServiceStaffEligibility(serviceId: 3, staffId: 1, locationId: 101),
      ServiceStaffEligibility(serviceId: 3, staffId: 2, locationId: 102),
      ServiceStaffEligibility(serviceId: 3, staffId: 3, locationId: 102),
    ];
  },
);

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

///
/// SERVICES PER CATEGORIA
///
final servicesByCategoryProvider = Provider.family<List<Service>, int>((
  ref,
  categoryId,
) {
  final services = ref.watch(servicesProvider);
  return [
    for (final service in services)
      if (service.categoryId == categoryId) service,
  ];
});
