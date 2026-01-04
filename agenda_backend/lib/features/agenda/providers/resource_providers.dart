import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../../core/models/resource.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/models/service_variant_resource_requirement.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../services/providers/services_provider.dart';
import 'appointment_providers.dart';
import 'business_providers.dart';

///
/// RISORSE (caricamento da API)
///
class ResourcesNotifier extends AsyncNotifier<List<Resource>> {
  @override
  Future<List<Resource>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }

    final apiClient = ref.watch(apiClientProvider);
    final business = ref.watch(currentBusinessProvider);

    // Non caricare se business non è ancora valido
    if (business.id <= 0) {
      return [];
    }

    try {
      final data = await apiClient.getResourcesByBusiness(business.id);
      return data.map(_parseResource).toList();
    } catch (_) {
      return [];
    }
  }

  Resource _parseResource(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as int,
      locationId: json['location_id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      type: json['type'] as String?,
      note: json['note'] as String?,
    );
  }

  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = const AsyncData([]);
      return;
    }

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) {
      return;
    }

    state = const AsyncLoading();

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getResourcesByBusiness(business.id);
      state = AsyncData(data.map(_parseResource).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<Resource> addResource({
    required int locationId,
    required String name,
    String? type,
    int quantity = 1,
    String? note,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final data = await apiClient.createResource(
      locationId: locationId,
      name: name,
      type: type,
      quantity: quantity,
      note: note,
    );
    final resource = _parseResource(data);
    final current = state.value ?? [];
    state = AsyncData([...current, resource]);
    return resource;
  }

  Future<Resource> updateResource({
    required int resourceId,
    String? name,
    String? type,
    int? quantity,
    String? note,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final data = await apiClient.updateResource(
      resourceId: resourceId,
      name: name,
      type: type,
      quantity: quantity,
      note: note,
    );
    final updated = _parseResource(data);
    final current = state.value ?? [];
    state = AsyncData([
      for (final r in current)
        if (r.id == updated.id) updated else r,
    ]);
    return updated;
  }

  Future<void> deleteResource(int id) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteResource(id);
    final current = state.value ?? [];
    state = AsyncData([
      for (final r in current)
        if (r.id != id) r,
    ]);
  }
}

final resourcesProvider =
    AsyncNotifierProvider<ResourcesNotifier, List<Resource>>(
      ResourcesNotifier.new,
    );

///
/// RISORSE PER LOCATION
///
final locationResourcesProvider = Provider.family<List<Resource>, int>((
  ref,
  locationId,
) {
  final resourcesAsync = ref.watch(resourcesProvider);
  final resources = resourcesAsync.value ?? [];
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

      final allResourcesAsync = ref.watch(resourcesProvider);
      final allResources = allResourcesAsync.value ?? [];
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
