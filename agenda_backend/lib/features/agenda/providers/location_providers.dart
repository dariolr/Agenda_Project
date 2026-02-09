import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../business/providers/locations_providers.dart';
import '../../business/providers/superadmin_selected_business_provider.dart';

///
/// 🔹 Provider per ottenere il business ID da usare per caricare le locations
/// Restituisce null se non c'è un business valido da caricare
///
final businessIdForLocationsProvider = Provider<int?>((ref) {
  final authState = ref.watch(authProvider);

  // Non caricare se non autenticato
  if (!authState.isAuthenticated) {
    return null;
  }

  // Per superadmin: carica solo se ha selezionato un business
  if (authState.user?.isSuperadmin ?? false) {
    final selectedBusiness = ref.watch(superadminSelectedBusinessProvider);
    return selectedBusiness; // null se non selezionato
  }

  // Per utente normale: usa il business da businessesProvider
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  return currentBusinessId > 0 ? currentBusinessId : null;
});

///
/// 🔹 ELENCO LOCATIONS (da API) - FutureProvider per caricamento asincrono
/// Filtra in base ai permessi dell'utente (scopeType: business o locations)
///
final locationsAsyncProvider = FutureProvider<List<Location>>((ref) async {
  final businessId = ref.watch(businessIdForLocationsProvider);

  // Se non c'è un business valido, ritorna lista vuota
  if (businessId == null || businessId <= 0) {
    return [];
  }

  final repository = ref.watch(locationsRepositoryProvider);
  final allLocations = await repository.getByBusinessId(businessId);

  // Filtra solo le location attive
  var locations = allLocations.where((l) => l.isActive).toList();

  // Filtra in base ai permessi utente (scopeType)
  final allowedIds = ref.watch(allowedLocationIdsProvider);
  if (allowedIds != null) {
    // L'utente ha accesso limitato a specifiche location
    locations = locations.where((l) => allowedIds.contains(l.id)).toList();
  }

  return locations;
});

///
/// 🔹 Provider per verificare se le locations sono caricate
///
final locationsLoadedProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(locationsAsyncProvider);
  return asyncValue.hasValue || asyncValue.hasError;
});

///
/// 🔹 ELENCO LOCATIONS (sincrono per compatibilità)
///
class LocationsNotifier extends Notifier<List<Location>> {
  @override
  List<Location> build() {
    // Ascolta il FutureProvider
    final asyncValue = ref.watch(locationsAsyncProvider);
    return asyncValue.when(
      data: (locations) => locations,
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Ricarica le locations dall'API
  Future<void> refresh() async {
    ref.invalidate(locationsAsyncProvider);
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
    int? slotIntervalMinutes,
    String? slotDisplayMode,
    int? minGapMinutes,
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
      slotIntervalMinutes: slotIntervalMinutes,
      slotDisplayMode: slotDisplayMode,
      minGapMinutes: minGapMinutes,
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

///
/// 🔹 LOCATION CORRENTE
///
class CurrentLocationId extends Notifier<int> {
  @override
  int build() {
    final businessId = ref.watch(businessIdForLocationsProvider);
    final locations = ref.watch(locationsProvider);

    // Se non abbiamo locations valide, ritorna 0
    if (locations.isEmpty || businessId == null || businessId <= 0) {
      return 0;
    }

    // Primo caricamento: prova a caricare da preferenze
    final prefs = ref.read(preferencesServiceProvider);
    final savedId = prefs.getCurrentLocationId(businessId);

    // Se c'è una preferenza salvata e la location esiste ancora, usala
    if (savedId != null && locations.any((l) => l.id == savedId)) {
      return savedId;
    }

    // Altrimenti usa la location di default
    final defaultLocation = locations.firstWhere(
      (l) => l.isDefault,
      orElse: () => locations.first,
    );
    return defaultLocation.id;
  }

  void set(int id) {
    state = id;
    // Salva in preferenze
    final businessId = ref.read(businessIdForLocationsProvider);
    if (businessId != null && businessId > 0) {
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
