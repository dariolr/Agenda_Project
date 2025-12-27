import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../../core/models/resource.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/models/service_variant_resource_requirement.dart';
import '../../services/providers/services_provider.dart';
import 'appointment_providers.dart';
import 'location_providers.dart';

///
/// RISORSE (mock + CRUD in memoria)
///
class ResourcesNotifier extends Notifier<List<Resource>> {
  @override
  List<Resource> build() {
    final locations = ref.read(locationsProvider);
    if (locations.isEmpty) return const [];

    final firstLocationId = locations.first.id;
    final secondLocationId = locations.length > 1
        ? locations[1].id
        : firstLocationId;

    return [
      // Risorse per sede principale
      Resource(
        id: 1,
        locationId: firstLocationId,
        name: 'Cabina Relax 1',
        quantity: 1,
        type: 'room',
        note: null,
      ),
      Resource(
        id: 2,
        locationId: firstLocationId,
        name: 'Cabina Relax 2',
        quantity: 1,
        type: 'room',
        note: null,
      ),
      Resource(
        id: 3,
        locationId: firstLocationId,
        name: 'Postazione Viso 1',
        quantity: 2,
        type: 'station',
        note: null,
      ),
      // Risorse per seconda sede
      Resource(
        id: 4,
        locationId: secondLocationId,
        name: 'Cabina Relax A',
        quantity: 1,
        type: 'room',
        note: null,
      ),
      Resource(
        id: 5,
        locationId: secondLocationId,
        name: 'Cabina Relax B',
        quantity: 1,
        type: 'room',
        note: null,
      ),
      Resource(
        id: 6,
        locationId: secondLocationId,
        name: 'Postazione Viso 2',
        quantity: 2,
        type: 'station',
        note: null,
      ),
    ];
  }

  void add(Resource resource) {
    state = [...state, resource];
  }

  void update(Resource updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
  }

  void delete(int id) {
    state = [
      for (final r in state)
        if (r.id != id) r,
    ];
  }
}

final resourcesProvider = NotifierProvider<ResourcesNotifier, List<Resource>>(
  ResourcesNotifier.new,
);

///
/// RISORSE PER LOCATION
///
final locationResourcesProvider = Provider.family<List<Resource>, int>((
  ref,
  locationId,
) {
  final resources = ref.watch(resourcesProvider);
  return [
    for (final r in resources)
      if (r.locationId == locationId) r,
  ];
});

///
/// REQUISITI RISORSE PER SERVICE VARIANT
///
final serviceVariantResourcesProvider =
    Provider.family<List<ServiceVariantResourceRequirement>, int>((
      ref,
      serviceVariantId,
    ) {
      final variant = ref.watch(serviceVariantByIdProvider(serviceVariantId));
      return variant?.resourceRequirements ?? const [];
    });

typedef ResourceBookingsParams = ({int resourceId, DateTime day});

///
/// APPOINTMENT CHE OCCUPANO UNA RISORSA IN UN GIORNO
///
final resourceBookingsProvider =
    Provider.family<List<Appointment>, ResourceBookingsParams>((ref, params) {
      final resourceId = params.resourceId;
      final day = params.day;

      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final appointments = ref.watch(appointmentsProvider).value ?? [];
      final variants = ref.watch(serviceVariantsProvider).value ?? [];

      final variantById = <int, ServiceVariant>{
        for (final v in variants) v.id: v,
      };

      bool usesResource(Appointment appt) {
        final variant = variantById[appt.serviceVariantId];
        if (variant == null) return false;
        for (final req in variant.resourceRequirements) {
          if (req.resourceId == resourceId) return true;
        }
        return false;
      }

      return [
        for (final appt in appointments)
          if (!appt.endTime.isBefore(dayStart) &&
              appt.startTime.isBefore(dayEnd) &&
              usesResource(appt))
            appt,
      ];
    });

typedef ResourceAvailabilityParams = ({
  int serviceVariantId,
  int staffId,
  DateTime start,
  DateTime end,
});

///
/// DISPONIBILITÀ RISORSE PER UN NUOVO APPUNTAMENTO
///
final resourceAvailabilityProvider =
    Provider.family<bool, ResourceAvailabilityParams>((ref, params) {
      final serviceVariantId = params.serviceVariantId;
      final start = params.start;
      final end = params.end;

      final variants = ref.watch(serviceVariantsProvider).value ?? [];
      ServiceVariant? currentVariant;
      for (final v in variants) {
        if (v.id == serviceVariantId) {
          currentVariant = v;
          break;
        }
      }

      final requirements = currentVariant?.resourceRequirements ?? const [];
      if (requirements.isEmpty) return true;

      final allResources = ref.watch(resourcesProvider);
      final resourceById = <int, Resource>{
        for (final r in allResources) r.id: r,
      };

      final requirementsByVariantId =
          <int, List<ServiceVariantResourceRequirement>>{
            for (final v in variants) v.id: v.resourceRequirements,
          };

      int unitsForAppointment(int resourceId, Appointment appt) {
        final reqs = requirementsByVariantId[appt.serviceVariantId];
        if (reqs == null) return 0;
        for (final req in reqs) {
          if (req.resourceId == resourceId) {
            return req.unitsRequired;
          }
        }
        return 0;
      }

      for (final req in requirements) {
        final resource = resourceById[req.resourceId];
        if (resource == null) {
          continue;
        }

        final bookings = ref.watch(
          resourceBookingsProvider((resourceId: req.resourceId, day: start)),
        );

        var usedUnits = 0;
        for (final appt in bookings) {
          final hasOverlap =
              appt.endTime.isAfter(start) && appt.startTime.isBefore(end);
          if (!hasOverlap) continue;

          usedUnits += unitsForAppointment(req.resourceId, appt);
        }

        if (usedUnits + req.unitsRequired > resource.quantity) {
          return false;
        }
      }

      return true;
    });
