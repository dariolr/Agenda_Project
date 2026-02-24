import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/location.dart';
import '../../../core/services/tenant_time_service.dart';
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

/// Flag persistente che indica se il business ha multiple locations.
/// Una volta settato a true, rimane true per tutta la sessione.
/// Viene aggiornato solo quando locationsProvider ha dati.
bool _hasMultipleLocationsFlag = false;

/// Flag che indica se l'utente è arrivato con location pre-selezionata via URL.
/// Viene controllato solo UNA VOLTA all'inizio, prima che le locations vengano caricate.
bool? _initialUrlHadLocation;

/// Provider derivato: true se ci sono multiple locations E nessuna location pre-selezionata via URL iniziale.
/// IMPORTANTE:
/// - Se l'utente arriva con ?location=X nell'URL iniziale, lo step è nascosto
/// - Se l'utente seleziona una location durante il flow (che aggiorna l'URL), lo step rimane visibile
final hasMultipleLocationsProvider = Provider<bool>((ref) {
  // Controlla se c'era una location nell'URL iniziale (solo la prima volta)
  if (_initialUrlHadLocation == null) {
    final urlLocationId = ref.read(urlLocationIdProvider);
    _initialUrlHadLocation = urlLocationId != null;
  }

  // Se l'utente è arrivato con location già nell'URL, nascondi lo step
  if (_initialUrlHadLocation == true) {
    return false;
  }

  // Se già sappiamo che ci sono multiple locations, ritorna true
  if (_hasMultipleLocationsFlag) {
    return true;
  }

  // Altrimenti controlla i dati attuali
  final locationsAsync = ref.watch(locationsProvider);
  locationsAsync.whenData((locations) {
    if (locations.length > 1) {
      _hasMultipleLocationsFlag = true;
    }
  });

  return _hasMultipleLocationsFlag;
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

/// Timezone effettivo del flow booking:
/// 1) timezone della location effettiva
/// 2) fallback timezone del business
/// 3) fallback Europe/Rome
final locationTimezoneProvider = Provider<String>((ref) {
  final location = ref.watch(effectiveLocationProvider);
  if (location != null) {
    return TenantTimeService.normalizeTimezone(location.timezone);
  }

  final businessAsync = ref.watch(currentBusinessProvider);
  return TenantTimeService.normalizeTimezone(businessAsync.value?.timezone);
});

final locationNowProvider = Provider<DateTime>((ref) {
  final timezone = ref.watch(locationTimezoneProvider);
  return TenantTimeService.nowInTimezone(timezone);
});

final locationTodayProvider = Provider<DateTime>((ref) {
  final timezone = ref.watch(locationTimezoneProvider);
  return TenantTimeService.todayInTimezone(timezone);
});
