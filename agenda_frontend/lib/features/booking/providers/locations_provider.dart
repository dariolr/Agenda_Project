import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import 'booking_provider.dart';
import 'business_provider.dart';

/// Provider per le locations del business corrente
final locationsProvider =
    NotifierProvider<LocationsNotifier, AsyncValue<List<Location>>>(
      LocationsNotifier.new,
    );

class LocationsNotifier extends Notifier<AsyncValue<List<Location>>> {
  bool _hasFetched = false;
  int? _lastBusinessId;

  @override
  AsyncValue<List<Location>> build() {
    // Ascolta cambiamenti del business
    ref.listen(currentBusinessProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final businessId = next.value!.id;
        if (businessId != _lastBusinessId) {
          _hasFetched = false;
          _lastBusinessId = businessId;
          _loadLocations(businessId);
        }
      }
    }, fireImmediately: true);

    return const AsyncValue.loading();
  }

  Future<void> _loadLocations(int businessId) async {
    if (_hasFetched) return;
    _hasFetched = true;

    state = const AsyncValue.loading();

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final locations = await repo.getLocations(businessId);
      state = AsyncValue.data(locations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final business = ref.read(currentBusinessProvider).value;
    if (business == null) return;

    _hasFetched = false;
    await _loadLocations(business.id);
  }
}

/// Provider per la location selezionata dall'utente
class SelectedLocationNotifier extends Notifier<Location?> {
  @override
  Location? build() => null;

  void select(Location location) {
    state = location;
  }

  void clear() {
    state = null;
  }
}

final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, Location?>(
      SelectedLocationNotifier.new,
    );

/// Provider derivato: true se ci sono multiple locations
final hasMultipleLocationsProvider = Provider<bool>((ref) {
  final locationsAsync = ref.watch(locationsProvider);
  return locationsAsync.maybeWhen(
    data: (locations) => locations.length > 1,
    orElse: () => false,
  );
});

/// Provider derivato: la location effettiva da usare per il booking
/// Se c'è una sola location, usa quella. Altrimenti usa quella selezionata.
final effectiveLocationProvider = Provider<Location?>((ref) {
  final locationsAsync = ref.watch(locationsProvider);
  final selectedLocation = ref.watch(selectedLocationProvider);

  return locationsAsync.maybeWhen(
    data: (locations) {
      if (locations.isEmpty) return null;
      if (locations.length == 1) return locations.first;
      return selectedLocation;
    },
    orElse: () => null,
  );
});
