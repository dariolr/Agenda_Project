import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_staff_eligibility.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/utils/color_utils.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';

final serviceCategoriesProvider = Provider<List<ServiceCategory>>((ref) {
  final business = ref.watch(currentBusinessProvider);
  return [
    ServiceCategory(
      id: 10,
      businessId: business.id,
      name: 'Trattamenti Corpo',
      description: 'Servizi dedicati al benessere del corpo',
    ),
    ServiceCategory(
      id: 11,
      businessId: business.id,
      name: 'Trattamenti Sportivi',
      description: 'Percorsi pensati per atleti e persone attive',
    ),
    ServiceCategory(
      id: 12,
      businessId: business.id,
      name: 'Trattamenti Viso',
      description: 'Cura estetica e rigenerante per il viso',
    ),
  ];
});

final servicesProvider = Provider<List<Service>>((ref) {
  final business = ref.watch(currentBusinessProvider);
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
    ),
  ];
});

final serviceVariantsProvider = Provider<List<ServiceVariant>>((ref) {
  final location = ref.watch(currentLocationProvider);
  // Mock variants customizing durata/prezzo per location
  return [
    ServiceVariant(
      id: 1001,
      serviceId: 1,
      locationId: 101,
      durationMinutes: 30,
      price: 45,
      colorHex: '#6EC5A6',
    ),
    ServiceVariant(
      id: 1002,
      serviceId: 1,
      locationId: 102,
      durationMinutes: 35,
      price: 48,
      colorHex: '#6EC5A6',
    ),
    ServiceVariant(
      id: 2001,
      serviceId: 2,
      locationId: 101,
      durationMinutes: 45,
      price: 62,
      colorHex: '#57A0D3',
    ),
    ServiceVariant(
      id: 2002,
      serviceId: 2,
      locationId: 102,
      durationMinutes: 50,
      price: 65,
      colorHex: '#57A0D3',
    ),
    ServiceVariant(
      id: 3001,
      serviceId: 3,
      locationId: 101,
      durationMinutes: 40,
      price: 55,
      colorHex: '#F4B942',
    ),
    ServiceVariant(
      id: 3002,
      serviceId: 3,
      locationId: 102,
      durationMinutes: 45,
      price: 58,
      colorHex: '#F4B942',
    ),
  ].where((variant) => variant.locationId == location.id).toList();
});

final serviceVariantByIdProvider =
    Provider.family<ServiceVariant?, int>((ref, variantId) {
  final variants = ref.watch(serviceVariantsProvider);
  for (final variant in variants) {
    if (variant.id == variantId) return variant;
  }
  return null;
});

final serviceStaffEligibilityProvider =
    Provider<List<ServiceStaffEligibility>>((ref) {
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
});

final eligibleStaffForServiceProvider =
    Provider.family<List<int>, int>((ref, serviceId) {
  final location = ref.watch(currentLocationProvider);
  final elegibility = ref.watch(serviceStaffEligibilityProvider);

  return [
    for (final entry in elegibility)
      if (entry.serviceId == serviceId &&
          (entry.locationId == null || entry.locationId == location.id))
        entry.staffId,
  ];
});

final servicesByCategoryProvider =
    Provider.family<List<Service>, int>((ref, categoryId) {
  final services = ref.watch(servicesProvider);
  return [
    for (final service in services)
      if (service.categoryId == categoryId) service,
  ];
});
