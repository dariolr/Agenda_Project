import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/location_closure.dart';
import '/core/network/network_providers.dart';
import '/features/agenda/providers/business_providers.dart';
import '/features/agenda/providers/location_providers.dart';

/// Provider per gestire le chiusure di un business (multi-location)
final locationClosuresProvider =
    AsyncNotifierProvider<LocationClosuresNotifier, List<LocationClosure>>(
      LocationClosuresNotifier.new,
    );

class LocationClosuresNotifier extends AsyncNotifier<List<LocationClosure>> {
  @override
  Future<List<LocationClosure>> build() async {
    return _loadClosures();
  }

  Future<List<LocationClosure>> _loadClosures() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) {
      return [];
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final closures = await apiClient.getClosures(businessId);
      return closures;
    } catch (e) {
      // Se errore, ritorna lista vuota
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadClosures());
  }

  Future<void> addClosure({
    required List<int> locationIds,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;

    final apiClient = ref.read(apiClientProvider);
    final closure = await apiClient.createClosure(
      businessId: businessId,
      locationIds: locationIds,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    state = state.whenData((closures) {
      final newList = [...closures, closure];
      // Ordina per data inizio
      newList.sort((a, b) => a.startDate.compareTo(b.startDate));
      return newList;
    });
  }

  Future<void> updateClosure({
    required int closureId,
    required List<int> locationIds,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final updated = await apiClient.updateClosure(
      closureId: closureId,
      locationIds: locationIds,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    state = state.whenData((closures) {
      return closures.map((c) => c.id == closureId ? updated : c).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
    });
  }

  Future<void> deleteClosure(int closureId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteClosure(closureId);

    state = state.whenData((closures) {
      return closures.where((c) => c.id != closureId).toList();
    });
  }
}

/// Provider derivato: chiusure future (a partire da oggi)
final futureLocationClosuresProvider =
    Provider<AsyncValue<List<LocationClosure>>>((ref) {
      final closuresAsync = ref.watch(locationClosuresProvider);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      return closuresAsync.whenData((closures) {
        return closures.where((c) {
          // Include se la data fine è >= oggi
          return !c.endDate.isBefore(todayOnly);
        }).toList();
      });
    });

/// Provider derivato: chiusure passate (terminate prima di oggi)
final pastLocationClosuresProvider =
    Provider<AsyncValue<List<LocationClosure>>>((ref) {
      final closuresAsync = ref.watch(locationClosuresProvider);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      return closuresAsync.whenData((closures) {
        return closures.where((c) {
          return c.endDate.isBefore(todayOnly);
        }).toList();
      });
    });

/// Provider per controllare se una data specifica è un giorno di chiusura per una location specifica
final isDateClosedForLocationProvider =
    Provider.family<bool, ({DateTime date, int locationId})>((ref, params) {
      final closuresAsync = ref.watch(locationClosuresProvider);
      final dateOnly = DateTime(
        params.date.year,
        params.date.month,
        params.date.day,
      );

      return closuresAsync.maybeWhen(
        data: (closures) {
          return closures.any(
            (c) =>
                c.containsDate(dateOnly) &&
                c.locationIds.contains(params.locationId),
          );
        },
        orElse: () => false,
      );
    });

/// Provider derivato: chiusure che si applicano a una location specifica
final closuresForLocationProvider =
    Provider.family<AsyncValue<List<LocationClosure>>, int>((ref, locationId) {
      final closuresAsync = ref.watch(locationClosuresProvider);

      return closuresAsync.whenData((closures) {
        return closures
            .where((c) => c.locationIds.contains(locationId))
            .toList();
      });
    });

/// Provider per controllare se una data specifica è un giorno di chiusura
/// per la location corrente (usa currentLocationIdProvider)
final isDateClosedProvider = Provider.family<bool, DateTime>((ref, date) {
  final currentLocationId = ref.watch(currentLocationIdProvider);

  return ref.watch(
    isDateClosedForLocationProvider((
      date: date,
      locationId: currentLocationId,
    )),
  );
});
