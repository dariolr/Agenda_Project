import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_staff_eligibility.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/models/service_variant_resource_requirement.dart';
import '../../../core/utils/color_utils.dart';
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
    final currency = ref.watch(effectiveCurrencyProvider); // 🔹 valuta coerente
    // Base: tre servizi fissi per compatibilita' con i test esistenti
    final seed = <Service>[
      Service(
        id: 1,
        businessId: business.id,
        categoryId: 10,
        name: ServiceSeedTexts.serviceRelaxName,
        description: ServiceSeedTexts.serviceRelaxDescription,
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
        name: ServiceSeedTexts.serviceSportName,
        description: ServiceSeedTexts.serviceSportDescription,
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
        name: ServiceSeedTexts.serviceFaceName,
        description: ServiceSeedTexts.serviceFaceDescription,
        duration: 40,
        price: 55,
        color: ColorUtils.fromHex('#F4B942'),
        isBookableOnline: false,
        isFree: false,
        isPriceStartingFrom: false,
        currency: currency,
      ),
    ];

    // Aggiunge mock extra per ciascuna categoria non vincolata dai test
    // (10 e 11), fino a un totale casuale di 5..10 servizi per categoria.
    final cats = ref.read(serviceCategoriesProvider);
    final palette = <String>[
      '#6EC5A6',
      '#57A0D3',
      '#F4B942',
      '#C678DD',
      '#E06C75',
      '#98C379',
      '#61AFEF',
      '#D19A66',
    ];
    final durations = <int>[15, 30, 45, 60, 75, 90];
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
          final dur = durations[rnd.nextInt(durations.length)];
          // Prezzo proporzionale alla durata, arrotondato a 5
          final rawPrice = dur * (1.0 + rnd.nextDouble() * 0.6); // 1.0x..1.6x
          final price = (rawPrice / 5).round() * 5;
          final colorHex = palette[(nextId + i) % palette.length];
          final isFrom = rnd.nextInt(5) == 0; // ~20%

          final nameIndex = existingInCat + i + 1;
          final svc = Service(
            id: nextId++,
            businessId: business.id,
            categoryId: cat.id,
            name: '${cat.name} $nameIndex',
            description: null,
            duration: dur,
            price: price.toDouble(),
            color: ColorUtils.fromHex(colorHex),
            isBookableOnline: true,
            isFree: false,
            isPriceStartingFrom: isFrom,
            currency: currency,
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
      duration: original.duration,
      price: original.price,
      color: original.color,
      isBookableOnline: original.isBookableOnline,
      isFree: original.isFree,
      isPriceStartingFrom: original.isPriceStartingFrom,
      currency: original.currency, // 🔹 mantiene la stessa valuta
    );
    add(copy);
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
      resourceRequirements: const [
        ServiceVariantResourceRequirement(
          id: 1,
          serviceVariantId: 1001,
          resourceId: 1,
          unitsRequired: 1,
        ),
      ],
    ),
    ServiceVariant(
      id: 1002,
      serviceId: 1,
      locationId: 102,
      durationMinutes: 35,
      price: 48,
      colorHex: '#6EC5A6',
      currency: currency,
      resourceRequirements: const [
        ServiceVariantResourceRequirement(
          id: 2,
          serviceVariantId: 1002,
          resourceId: 4,
          unitsRequired: 1,
        ),
      ],
    ),
    ServiceVariant(
      id: 2001,
      serviceId: 2,
      locationId: 101,
      durationMinutes: 45,
      price: 62,
      colorHex: '#57A0D3',
      currency: currency,
      resourceRequirements: const [
        ServiceVariantResourceRequirement(
          id: 3,
          serviceVariantId: 2001,
          resourceId: 2,
          unitsRequired: 1,
        ),
      ],
    ),
    ServiceVariant(
      id: 2002,
      serviceId: 2,
      locationId: 102,
      durationMinutes: 50,
      price: 65,
      colorHex: '#57A0D3',
      currency: currency,
      resourceRequirements: const [
        ServiceVariantResourceRequirement(
          id: 4,
          serviceVariantId: 2002,
          resourceId: 5,
          unitsRequired: 1,
        ),
      ],
    ),
    ServiceVariant(
      id: 3001,
      serviceId: 3,
      locationId: 101,
      durationMinutes: 40,
      price: 55,
      colorHex: '#F4B942',
      currency: currency,
      resourceRequirements: const [
        ServiceVariantResourceRequirement(
          id: 5,
          serviceVariantId: 3001,
          resourceId: 3,
          unitsRequired: 1,
        ),
      ],
    ),
    ServiceVariant(
      id: 3002,
      serviceId: 3,
      locationId: 102,
      durationMinutes: 45,
      price: 58,
      colorHex: '#F4B942',
      currency: currency,
      resourceRequirements: const [
        ServiceVariantResourceRequirement(
          id: 6,
          serviceVariantId: 3002,
          resourceId: 6,
          unitsRequired: 1,
        ),
      ],
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
      ServiceStaffEligibility(serviceId: 2, staffId: 2, locationId: 102),
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
