import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../agenda/providers/business_providers.dart';
import '../../business/providers/locations_providers.dart';

///
/// 🔹 ELENCO LOCATIONS (da API)
///
class LocationsNotifier extends Notifier<List<Location>> {
  @override
  List<Location> build() {
    _loadLocations();
    return []; // Stato iniziale vuoto
  }

  Future<void> _loadLocations() async {
    try {
      final business = ref.read(currentBusinessProvider);
      final repository = ref.read(locationsRepositoryProvider);
      final locations = await repository.getByBusinessId(business.id);
      state = locations;
    } catch (e) {
      // In caso di errore, mantieni lo stato vuoto
      state = [];
    }
  }

  void add(Location location) {
    state = [...state, location];
  }

  void updateItem(Location updated) {
    state = [
      for (final l in state)
        if (l.id == updated.id) updated else l,
    ];
  }

  void delete(int id) {
    final currentId = ref.read(currentLocationIdProvider);
    final filtered = state.where((l) => l.id != id).toList();
    state = filtered;
    if (filtered.isEmpty) return;
    if (currentId == id) {
      ref.read(currentLocationIdProvider.notifier).set(filtered.first.id);
    }
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  int nextId() {
    if (state.isEmpty) return 1;
    final maxId = state.map((l) => l.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}

final locationsProvider = NotifierProvider<LocationsNotifier, List<Location>>(
  LocationsNotifier.new,
);

///
/// 🔹 LOCATION CORRENTE
///
class CurrentLocationId extends Notifier<int> {
  @override
  int build() {
    // Aspetta che locationsProvider carichi i dati
    ref.listen(locationsProvider, (previous, next) {
      if (next.isNotEmpty && state == 0) {
        final defaultLocation = next.firstWhere(
          (l) => l.isDefault,
          orElse: () => next.first,
        );
        state = defaultLocation.id;
      }
    });
    return 1; // Default temporaneo
  }

  void set(int id) => state = id;
}

final currentLocationIdProvider = NotifierProvider<CurrentLocationId, int>(
  CurrentLocationId.new,
);

final currentLocationProvider = Provider<Location>((ref) {
  final locations = ref.watch(locationsProvider);
  final currentId = ref.watch(currentLocationIdProvider);

  if (locations.isEmpty) {
    return Location(id: currentId, businessId: 1, name: 'Loading...');
  }

  return locations.firstWhere(
    (l) => l.id == currentId,
    orElse: () => locations.first,
  );
});

///
/// 🔹 VALUTA EFFETTIVA DELLA LOCATION CORRENTE
///
/// Se la location ha una valuta specifica, viene usata.
/// Altrimenti eredita quella del business.
///
final effectiveCurrencyProvider = Provider<String>((ref) {
  final location = ref.watch(currentLocationProvider);
  final business = ref.watch(currentBusinessProvider);
  return location.currency ?? business.currency;
});
