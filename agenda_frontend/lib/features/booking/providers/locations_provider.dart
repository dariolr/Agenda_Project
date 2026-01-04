import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/location.dart';
import 'booking_provider.dart';
import 'business_provider.dart';

/// Provider per la location ID passata via URL (?location=4)
/// Se valorizzato, lo step location viene saltato
final urlLocationIdProvider = StateProvider<int?>((ref) => null);

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

/// Provider derivato: true se ci sono multiple locations E nessuna location pre-selezionata via URL
/// Se urlLocationIdProvider è valorizzato, consideriamo come "singola location" (step saltato)
final hasMultipleLocationsProvider = Provider<bool>((ref) {
  // Se c'è una location passata via URL, non mostrare lo step location
  final urlLocationId = ref.watch(urlLocationIdProvider);
  if (urlLocationId != null) {
    return false;
  }

  final locationsAsync = ref.watch(locationsProvider);
  return locationsAsync.maybeWhen(
    data: (locations) => locations.length > 1,
    orElse: () => false,
  );
});

/// Provider derivato: la location effettiva da usare per il booking
/// Priorità: 1) URL param, 2) Selezione utente, 3) Location singola/default
final effectiveLocationProvider = Provider<Location?>((ref) {
  final locationsAsync = ref.watch(locationsProvider);
  final urlLocationId = ref.watch(urlLocationIdProvider);
  final selectedLocation = ref.watch(selectedLocationProvider);

  return locationsAsync.maybeWhen(
    data: (locations) {
      if (locations.isEmpty) return null;

      // 1) Se c'è location da URL, cerca quella
      if (urlLocationId != null) {
        final urlLocation = locations
            .where((l) => l.id == urlLocationId)
            .firstOrNull;
        if (urlLocation != null) return urlLocation;
        // Se non trovata, fallback a default
      }

      // 2) Se c'è una sola location, usa quella
      if (locations.length == 1) return locations.first;

      // 3) Usa la selezione dell'utente
      return selectedLocation;
    },
    orElse: () => null,
  );
});
