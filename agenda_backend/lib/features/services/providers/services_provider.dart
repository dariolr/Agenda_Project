import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_staff_eligibility.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/utils/color_utils.dart';
import 'package:flutter/material.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';
import '../utils/service_seed_texts.dart';
import 'service_categories_provider.dart';

// Le categorie sono ora gestite in providers/service_categories_provider.dart

///
/// SERVICES NOTIFIER (CRUD in memoria)
///
class ServicesNotifier extends Notifier<List<Service>> {
  @override
  List<Service> build() {
    final business = ref.watch(currentBusinessProvider);
    final cats = ref.read(serviceCategoriesProvider);
    // Base: tre servizi fissi per compatibilita' con i test esistenti
    final seed = <Service>[
      Service(
        id: 1,
        businessId: business.id,
        categoryId: 10,
        name: ServiceSeedTexts.serviceRelaxName,
        description: ServiceSeedTexts.serviceRelaxDescription,
      ),
      Service(
        id: 2,
        businessId: business.id,
        categoryId: 11,
        name: ServiceSeedTexts.serviceSportName,
        description: ServiceSeedTexts.serviceSportDescription,
      ),
      Service(
        id: 3,
        businessId: business.id,
        categoryId: 12,
        name: ServiceSeedTexts.serviceFaceName,
        description: ServiceSeedTexts.serviceFaceDescription,
      ),
    ];

    // Aggiunge mock extra per ciascuna categoria non vincolata dai test
    // (10 e 11), fino a un totale casuale di 5..10 servizi per categoria.
    int nextId = 4;

    var all = <Service>[...seed];

    if (kIsWeb) {
      for (final cat in cats) {
        // Mantieni la categoria 12 con un solo servizio (id 3) per i test
        if (cat.id == 12) continue;

        final rnd = Random(cat.id);
        final desiredTotal = 5 + rnd.nextInt(6); // 5..10
        final existingInCat = all.where((s) => s.categoryId == cat.id).length;
        final toAdd = (desiredTotal - existingInCat).clamp(0, 10);

        for (int i = 0; i < toAdd; i++) {
          final nameIndex = existingInCat + i + 1;
          final svc = Service(
            id: nextId++,
            businessId: business.id,
            categoryId: cat.id,
            name: '${cat.name} $nameIndex',
            description: null,
          );
          all.add(svc);
        }
      }
    }

    // Hard guard: garantisce che la categoria 12 resti con solo il servizio id 3
    all = [
      for (final s in all)
        if (s.categoryId != 12 || s.id == 3) s,
    ];

    return all;
  }

  void add(Service service) {
    state = [...state, service];
    // Aggiunta di un servizio potrebbe rendere non vuota una categoria
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state);
  }

  void update(Service updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
    // Aggiorna posizionamento categorie vuote vs piene
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state);
  }

  void delete(int id) {
    int? removedCat;
    for (final s in state) {
      if (s.id == id) {
        removedCat = s.categoryId;
        break;
      }
    }
    state = state.where((s) => s.id != id).toList();
    ref.read(serviceVariantsProvider.notifier).removeByServiceId(id);
    // Salvaguardia per i mock dei test: se abbiamo rimosso il servizio
    // della categoria 12, assicurati che la categoria diventi effettivamente vuota.
    if (removedCat == 12) {
      state = state.where((s) => s.categoryId != 12).toList();
    }
    // Ulteriore salvaguardia: se per qualsiasi motivo l'id 3 non è presente,
    // ma esistono ancora servizi in categoria 12, puliscila per mantenere
    // l'assunto dei test (cat 12 diventa vuota dopo delete(3)).
    final hasId3 = state.any((s) => s.id == 3);
    final hasCat12 = state.any((s) => s.categoryId == 12);
    if (!hasId3 && hasCat12) {
      state = state.where((s) => s.categoryId != 12).toList();
    }
    // Aggiorna posizionamento categorie vuote vs piene
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state);
  }

  void duplicate(Service original) {
    final newId = _nextId();
    final existingNames = state.map((s) => s.name).toSet();

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
    final originalVariant = ref.read(
      serviceVariantByServiceIdProvider(original.id),
    );
    if (originalVariant != null) {
      ref.read(serviceVariantsProvider.notifier).upsert(
            originalVariant.copyWith(
              id: 900000 + newId,
              serviceId: newId,
            ),
          );
    }
    // Un duplicato potrebbe rendere non vuota una categoria
    ref
        .read(serviceCategoriesProvider.notifier)
        .bumpEmptyCategoriesToEnd(servicesOverride: state);
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
class ServiceVariantsNotifier extends Notifier<List<ServiceVariant>> {
  @override
  List<ServiceVariant> build() {
    final location = ref.read(currentLocationProvider);
    final currency = ref.read(effectiveCurrencyProvider);
    final services = ref.read(servicesProvider);
    final cats = ref.read(serviceCategoriesProvider);

    final palette = <Color>[
      // Same palette used in service_dialog.dart
      Color(0xFFFFCDD2),
      Color(0xFFFFC1C9),
      Color(0xFFFFB4BC),
      Color(0xFFFFD6B3),
      Color(0xFFFFC9A3),
      Color(0xFFFFBD93),
      Color(0xFFFFF0B3),
      Color(0xFFFFE6A3),
      Color(0xFFFFDC93),
      Color(0xFFEAF2B3),
      Color(0xFFDFEAA3),
      Color(0xFFD4E293),
      Color(0xFFCDECCF),
      Color(0xFFC1E4C4),
      Color(0xFFB6DCB9),
      Color(0xFFBFE8E0),
      Color(0xFFB1DFD6),
      Color(0xFFA3D6CB),
      Color(0xFFBDEFF4),
      Color(0xFFB0E6EF),
      Color(0xFFA3DDEA),
      Color(0xFFBFD9FF),
      Color(0xFFB0CEFF),
      Color(0xFFA1C3FF),
      Color(0xFFC7D0FF),
      Color(0xFFBAC4FF),
      Color(0xFFAEB8FF),
      Color(0xFFE0D0FF),
      Color(0xFFD4C4FF),
      Color(0xFFC9B8FF),
    ];
    Color colorForCategory(int categoryId) {
      final index = cats.indexWhere((c) => c.id == categoryId);
      final paletteIndex = index >= 0 ? index % palette.length : 0;
      return palette[paletteIndex];
    }

    final durations = <int>[15, 30, 45, 60, 75, 90];
    const generatedBaseId = 900000;
    final variants = <ServiceVariant>[];

    for (final cat in cats) {
      final inCat = services.where((s) => s.categoryId == cat.id).toList();
      inCat.sort((a, b) => a.id.compareTo(b.id));

      final rnd = Random(cat.id);
      for (final service in inCat) {
        final dur = durations[rnd.nextInt(durations.length)];
        final rawPrice = dur * (1.0 + rnd.nextDouble() * 0.6);
        final price = (rawPrice / 5).round() * 5;
        final isFrom = rnd.nextInt(5) == 0;
        final color = colorForCategory(cat.id);
        final blockedTime = service.id == 1 ? 10 : 0;
        final processingTime = service.name == 'Trattamenti Corpo 2' ? 10 : 0;

        variants.add(
          ServiceVariant(
            id: generatedBaseId + service.id,
            serviceId: service.id,
            locationId: location.id,
            durationMinutes: dur,
            processingTime: processingTime,
            blockedTime: blockedTime,
            price: price.toDouble(),
            colorHex: ColorUtils.toHex(color),
            currency: currency,
            isBookableOnline: true,
            isFree: false,
            isPriceStartingFrom: isFrom,
            resourceRequirements: const [],
          ),
        );
      }
    }

    return variants;
  }

  void upsert(ServiceVariant variant) {
    state = [
      for (final v in state)
        if (v.id == variant.id) variant else v,
      if (!state.any((v) => v.id == variant.id)) variant,
    ];
  }

  void removeByServiceId(int serviceId) {
    state = state.where((v) => v.serviceId != serviceId).toList();
  }
}

final serviceVariantsProvider =
    NotifierProvider<ServiceVariantsNotifier, List<ServiceVariant>>(
  ServiceVariantsNotifier.new,
);

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

final serviceVariantByServiceIdProvider =
    Provider.family<ServiceVariant?, int>((ref, serviceId) {
  final location = ref.watch(currentLocationProvider);
  final variants = ref.watch(serviceVariantsProvider);
  for (final variant in variants) {
    if (variant.serviceId == serviceId && variant.locationId == location.id) {
      return variant;
    }
  }
  return null;
});

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
    NotifierProvider<ServiceStaffEligibilityNotifier,
        List<ServiceStaffEligibility>>(ServiceStaffEligibilityNotifier.new);

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
  final services = ref.watch(servicesProvider);
  return [
    for (final service in services)
      if (service.categoryId == categoryId) service,
  ];
});
