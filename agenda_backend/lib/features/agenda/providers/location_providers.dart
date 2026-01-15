import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/locations_providers.dart';
import '../../business/providers/superadmin_selected_business_provider.dart';

///
/// 🔹 ELENCO LOCATIONS (da API)
///
class LocationsNotifier extends Notifier<List<Location>> {
  @override
  List<Location> build() {
    // Ascolta i cambiamenti dell'auth state
    final authState = ref.watch(authProvider);

    // Non caricare se non autenticato
    if (!authState.isAuthenticated) {
      ref.read(locationsLoadedProvider.notifier).setLoaded(false);
      return [];
    }

    // Per superadmin: carica solo se ha selezionato un business
    if (authState.user?.isSuperadmin ?? false) {
      final selectedBusiness = ref.watch(superadminSelectedBusinessProvider);
      if (selectedBusiness == null) {
        // Superadmin nella lista business, non caricare locations
        ref.read(locationsLoadedProvider.notifier).setLoaded(false);
        return [];
      }
    }

    // Verifica che ci sia un business ID valido (> 0) prima di caricare
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId <= 0) {
      // Business non ancora caricato, aspetta
      ref.read(locationsLoadedProvider.notifier).setLoaded(false);
      return [];
    }

    // Carica locations per utente normale o superadmin con business selezionato
    _loadLocations();
    return []; // Stato iniziale vuoto
  }

  Future<void> _loadLocations() async {
    // Verifica autenticazione prima di chiamare API
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      ref.read(locationsLoadedProvider.notifier).setLoaded(false);
      return;
    }

    try {
      // NOTA: Non resettiamo locationsLoaded qui perché viene già gestito
      // nel build() o nel chiamante. Questo evita flash di "nessuna sede".
      final business = ref.read(currentBusinessProvider);
      final repository = ref.read(locationsRepositoryProvider);
      final locations = await repository.getByBusinessId(business.id);
      // Filtra solo le location attive
      final activeLocations = locations.where((l) => l.isActive).toList();
      state = activeLocations;
    } catch (_) {
      // In caso di errore, mantieni lo stato vuoto
      state = [];
    } finally {
      ref.read(locationsLoadedProvider.notifier).setLoaded(true);
    }
  }

  /// Ricarica le locations dall'API
  Future<void> refresh() async {
    await _loadLocations();
  }

  /// Crea una nuova location tramite API
  Future<Location> create({
    required String name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    bool? isActive,
  }) async {
    final business = ref.read(currentBusinessProvider);
    final repository = ref.read(locationsRepositoryProvider);
    final location = await repository.create(
      businessId: business.id,
      name: name,
      address: address,
      phone: phone,
      email: email,
      timezone: timezone,
      minBookingNoticeHours: minBookingNoticeHours,
      maxBookingAdvanceDays: maxBookingAdvanceDays,
      allowCustomerChooseStaff: allowCustomerChooseStaff,
      isActive: isActive,
    );
    state = [...state, location];
    return location;
  }

  /// Aggiorna una location esistente tramite API
  Future<Location> updateLocation({
    required int locationId,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    bool? isActive,
  }) async {
    final repository = ref.read(locationsRepositoryProvider);
    final updated = await repository.update(
      locationId: locationId,
      name: name,
      address: address,
      phone: phone,
      email: email,
      timezone: timezone,
      minBookingNoticeHours: minBookingNoticeHours,
      maxBookingAdvanceDays: maxBookingAdvanceDays,
      allowCustomerChooseStaff: allowCustomerChooseStaff,
      isActive: isActive,
    );
    state = [
      for (final l in state)
        if (l.id == updated.id) updated else l,
    ];
    return updated;
  }

  /// Elimina una location tramite API
  /// [currentLocationId] deve essere passato dal chiamante per evitare dipendenza circolare
  Future<void> deleteLocation(int id, {required int currentLocationId}) async {
    final repository = ref.read(locationsRepositoryProvider);

    await repository.delete(id);

    final filtered = state.where((l) => l.id != id).toList();
    state = filtered;

    // Se era la location corrente, passa alla prima disponibile
    if (filtered.isNotEmpty && currentLocationId == id) {
      ref.read(currentLocationIdProvider.notifier).set(filtered.first.id);
    }
  }

  // === Metodi locali per UI (senza API) ===

  void add(Location location) {
    state = [...state, location];
  }

  void updateItem(Location updated) {
    state = [
      for (final l in state)
        if (l.id == updated.id) updated else l,
    ];
  }

  void delete(int id, {int? currentLocationId}) {
    final filtered = state.where((l) => l.id != id).toList();
    state = filtered;
    if (filtered.isEmpty) return;
    // Se era la location corrente, passa alla prima disponibile
    if (currentLocationId != null && currentLocationId == id) {
      ref.read(currentLocationIdProvider.notifier).set(filtered.first.id);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Aggiorna sortOrder locale
    final reordered = <Location>[];
    for (int i = 0; i < list.length; i++) {
      reordered.add(list[i].copyWith(sortOrder: i));
    }
    state = reordered;

    // Persist to API
    await _persistLocationsOrder(reordered);
  }

  /// Persiste l'ordine delle locations via API
  Future<void> _persistLocationsOrder(List<Location> locations) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.reorderLocations(
        locations: locations
            .map((l) => {'id': l.id, 'sort_order': l.sortOrder})
            .toList(),
      );
    } catch (_) {
      // Ignora errore - utente può riprovare
    }
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

class LocationsLoadedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoaded(bool value) {
    if (state == value) return;
    state = value;
  }
}

final locationsLoadedProvider = NotifierProvider<LocationsLoadedNotifier, bool>(
  LocationsLoadedNotifier.new,
);

///
/// 🔹 LOCATION CORRENTE
///
class CurrentLocationId extends Notifier<int> {
  @override
  int build() {
    final businessId = ref.watch(currentBusinessIdProvider);

    // Aspetta che locationsProvider carichi i dati
    ref.listen(locationsProvider, (previous, next) {
      if (next.isNotEmpty && state == 0) {
        // Carica da preferenze salvate (solo quando abbiamo businessId valido)
        int? savedId;
        if (businessId > 0) {
          final prefs = ref.read(preferencesServiceProvider);
          savedId = prefs.getCurrentLocationId(businessId);
        }

        // Se c'è una preferenza salvata e la location esiste ancora, usala
        if (savedId != null && next.any((l) => l.id == savedId)) {
          state = savedId;
        } else {
          // Altrimenti usa la location di default
          final defaultLocation = next.firstWhere(
            (l) => l.isDefault,
            orElse: () => next.first,
          );
          state = defaultLocation.id;

          // Se c'era un savedId non valido, aggiorna le preferenze
          if (savedId != null && businessId > 0) {
            ref
                .read(preferencesServiceProvider)
                .setCurrentLocationId(businessId, state);
          }
        }
      }
    });
    return 0; // Inizializza a 0 per triggare il listen
  }

  void set(int id) {
    state = id;
    // Salva in preferenze
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId > 0) {
      ref.read(preferencesServiceProvider).setCurrentLocationId(businessId, id);
    }
  }
}

final currentLocationIdProvider = NotifierProvider<CurrentLocationId, int>(
  CurrentLocationId.new,
);

final currentLocationProvider = Provider<Location>((ref) {
  final locations = ref.watch(locationsProvider);
  final currentId = ref.watch(currentLocationIdProvider);

  if (locations.isEmpty || currentId == 0) {
    // Ritorna location placeholder mentre carica
    return Location(
      id: 0,
      businessId: 0,
      name: 'Loading...',
      isDefault: false,
      isActive: true,
    );
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
