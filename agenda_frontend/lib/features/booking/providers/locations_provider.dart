import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/location.dart';
import '../../../core/services/tenant_time_service.dart';
import 'booking_direct_link_provider.dart';
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

final bookableLocationsForCurrentFlowProvider = Provider<List<Location>>((ref) {
  final locations = ref.watch(locationsProvider).value ?? const <Location>[];
  final directLink = ref.watch(bookingDirectLinkProvider).value;
  if (directLink == null ||
      !directLink.isBusinessScoped ||
      directLink.compatibleLocationIds.isEmpty) {
    return locations;
  }

  final compatibleIds = directLink.compatibleLocationIds.toSet();
  return locations.where((location) => compatibleIds.contains(location.id)).toList();
});

/// Provider derivato: true se il business ha più location E nessuna è vincolata
/// da Direct link o dal query param ?location=.
/// Completamente reattivo: si ricalcola ogni volta che cambia locationsProvider,
/// urlLocationIdProvider o bookingDirectLinkProvider.
final hasMultipleLocationsProvider = Provider<bool>((ref) {
  final locationsAsync = ref.watch(locationsProvider);
  final urlLocationId = ref.watch(urlLocationIdProvider);
  final linkSlug = ref.watch(bookingDirectLinkSlugProvider);
  final directLinkAsync =
      (linkSlug != null) ? ref.watch(bookingDirectLinkProvider) : null;

  // Finché il direct link non è risolto non dichiariamo multiple locations:
  // evita il flash dello step sede che verrebbe saltato un frame dopo.
  if (directLinkAsync != null && directLinkAsync.isLoading) return false;

  final directLink = directLinkAsync?.value;

  return locationsAsync.maybeWhen(
    data: (locations) {
      final flowLocations = ref.watch(bookableLocationsForCurrentFlowProvider);
      if (flowLocations.length <= 1) return false;

      final directLocationId = directLink?.locationId ?? 0;
      if (directLocationId > 0 &&
          flowLocations.any((l) => l.id == directLocationId)) {
        return false;
      }

      if (directLink?.isBusinessScoped == true) {
        return flowLocations.length > 1;
      }

      if (urlLocationId != null &&
          flowLocations.any((l) => l.id == urlLocationId)) {
        return false;
      }

      return true;
    },
    orElse: () => false,
  );
});

/// Provider derivato: la location effettiva da usare per il booking
/// Priorità: 1) target direct link, 2) URL param, 3) location singola/default,
/// 4) selezione utente.
final effectiveLocationProvider = Provider<Location?>((ref) {
  final locationsAsync = ref.watch(locationsProvider);
  final isDirectLinkBlocked = ref.watch(bookingDirectLinkBlockingErrorProvider);
  final directLink = isDirectLinkBlocked
      ? null
      : ref.watch(bookingDirectLinkProvider).value;
  final urlLocationId = ref.watch(urlLocationIdProvider);
  final selectedLocation = ref.watch(selectedLocationProvider);

  return locationsAsync.maybeWhen(
    data: (locations) {
      final flowLocations = ref.watch(bookableLocationsForCurrentFlowProvider);
      if (flowLocations.isEmpty) return null;

      if (!isDirectLinkBlocked) {
        final directLocationId = directLink?.locationId ?? 0;
        if (directLocationId > 0) {
          final directLocation = flowLocations
              .where((l) => l.id == directLocationId)
              .firstOrNull;
          if (directLocation != null) return directLocation;
        }

        if (directLink?.isBusinessScoped == true &&
            flowLocations.length == 1) {
          return flowLocations.first;
        }
      }

      // 1) Se c'è location da URL, cerca quella
      if (urlLocationId != null) {
        final urlLocation = flowLocations
            .where((l) => l.id == urlLocationId)
            .firstOrNull;
        if (urlLocation != null) return urlLocation;
        // Se non trovata, fallback a default
      }

      // 2) Se c'è una sola location, usa quella
      if (flowLocations.length == 1) return flowLocations.first;

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
