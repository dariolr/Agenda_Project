import 'package:uuid/uuid.dart';

import '../../../core/models/location.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/time_slot.dart';
import '../../../core/network/api_client.dart';

/// Repository per le prenotazioni - API reale
class BookingRepository {
  final ApiClient _apiClient;
  final Uuid _uuid = const Uuid();

  BookingRepository(this._apiClient);

  /// GET /v1/businesses/{business_id}/locations/public
  /// Recupera le locations attive di un business
  Future<List<Location>> getLocations(int businessId) async {
    final data = await _apiClient.getBusinessLocations(businessId);
    final locationsJson = data['data'] as List<dynamic>? ?? [];

    return locationsJson
        .map((json) => Location.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /v1/services?location_id=X
  /// Recupera categorie e servizi in un'unica chiamata
  Future<({List<ServiceCategory> categories, List<Service> services})>
  getCategoriesWithServices(int locationId) async {
    final data = await _apiClient.getServices(locationId);
    final categoriesJson = data['categories'] as List<dynamic>? ?? [];

    final categories = <ServiceCategory>[];
    final services = <Service>[];

    for (final json in categoriesJson) {
      final catJson = json as Map<String, dynamic>;

      // Skip categorie senza ID (non categorizzate)
      final catId = catJson['id'] as int?;
      if (catId == null) continue;

      categories.add(ServiceCategory.fromJson(catJson));

      final servicesJson = catJson['services'] as List<dynamic>? ?? [];

      for (final svcJson in servicesJson) {
        final svc = svcJson as Map<String, dynamic>;
        if (!_isTruthy(svc['is_bookable_online'])) {
          continue;
        }
        if (!_isTruthy(svc['is_active'])) {
          continue;
        }
        if (!svc.containsKey('category_id')) {
          svc['category_id'] = catId;
        }
        services.add(Service.fromJson(svc));
      }
    }

    return (categories: categories, services: services);
  }

  /// GET /v1/services?location_id=X
  /// Recupera categorie con servizi annidati (legacy)
  Future<List<ServiceCategory>> getCategories(int locationId) async {
    final result = await getCategoriesWithServices(locationId);
    return result.categories;
  }

  /// GET /v1/services?location_id=X
  /// Recupera tutti i servizi (flat list) (legacy)
  Future<List<Service>> getServices(int locationId) async {
    final result = await getCategoriesWithServices(locationId);
    return result.services;
  }

  /// GET /v1/staff?location_id=X
  /// Recupera staff prenotabili online
  Future<List<Staff>> getStaff(int locationId) async {
    final data = await _apiClient.getStaff(locationId);

    // Formato atteso: { "staff": [...] }
    final staffJson = data['staff'] as List<dynamic>? ?? [];

    return staffJson.map((json) {
      final staffData = json as Map<String, dynamic>;
      // Mappa display_name se presente
      if (staffData.containsKey('display_name') &&
          !staffData.containsKey('name')) {
        final displayName = staffData['display_name'] as String;
        final parts = displayName.split(' ');
        staffData['name'] = parts.isNotEmpty ? parts.first : displayName;
        staffData['surname'] = parts.length > 1
            ? parts.sublist(1).join(' ')
            : '';
      }
      // Default business_id se non presente
      if (!staffData.containsKey('business_id')) {
        staffData['business_id'] = 1;
      }
      return Staff.fromJson(staffData);
    }).toList();
  }

  /// GET /v1/availability?location_id=X&date=YYYY-MM-DD&service_ids=1,2&staff_id=N
  /// Recupera slot disponibili
  Future<List<TimeSlot>> getAvailableSlots({
    required int locationId,
    required DateTime date,
    required List<int> serviceIds,
    int? staffId,
  }) async {
    if (serviceIds.isEmpty) return [];

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final data = await _apiClient.getAvailability(
      locationId: locationId,
      date: dateStr,
      serviceIds: serviceIds,
      staffId: staffId,
    );

    final slotsJson = data['slots'] as List<dynamic>? ?? [];

    return slotsJson.map((json) {
      return TimeSlot.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  /// GET /v1/staff/{id}/planning?date=YYYY-MM-DD
  /// Ritorna il planning valido per data (data può essere null se non esiste)
  Future<Map<String, dynamic>?> getStaffPlanningForDate({
    required int staffId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _apiClient.getStaffPlanningForDate(
      staffId: staffId,
      date: dateStr,
    );
    return data['data'] as Map<String, dynamic>?;
  }

  /// GET /v1/staff/{id}/planning-availability?date=YYYY-MM-DD
  /// Ritorna se lo staff ha disponibilità (planning) per la data
  Future<bool> isStaffAvailableByPlanning({
    required int staffId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _apiClient.getStaffPlanningAvailability(
      staffId: staffId,
      date: dateStr,
    );
    final payload = data['data'] as Map<String, dynamic>? ?? {};
    return payload['is_available'] == true;
  }

  /// Verifica se lo staff è prenotabile per servizi + data (planning + slots)
  Future<bool> isStaffBookableForDate({
    required int staffId,
    required int locationId,
    required DateTime date,
    required List<int> serviceIds,
  }) async {
    final planning = await getStaffPlanningForDate(
      staffId: staffId,
      date: date,
    );
    if (planning == null) return false;

    final planningAvailable = await isStaffAvailableByPlanning(
      staffId: staffId,
      date: date,
    );
    if (!planningAvailable) return false;

    final slots = await getAvailableSlots(
      locationId: locationId,
      date: date,
      serviceIds: serviceIds,
      staffId: staffId,
    );
    return slots.isNotEmpty;
  }

  /// Recupera le date del mese con almeno uno slot disponibile
  Future<Set<DateTime>> getAvailableDatesForMonth({
    required int locationId,
    required DateTime month,
    required List<int> serviceIds,
    int? staffId,
  }) async {
    if (serviceIds.isEmpty) return {};

    final year = month.year;
    final monthNumber = month.month;
    final daysInMonth = DateTime(year, monthNumber + 1, 0).day;
    final availableDates = <DateTime>{};

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, monthNumber, day);
      try {
        final slots = await getAvailableSlots(
          locationId: locationId,
          date: date,
          serviceIds: serviceIds,
          staffId: staffId,
        );
        if (slots.isNotEmpty) {
          availableDates.add(DateTime(year, monthNumber, day));
        }
      } catch (_) {
        // Ignora errori e continua con il giorno successivo
      }
    }

    return availableDates;
  }

  /// Trova la prima data con disponibilità
  /// Cerca nei prossimi 30 giorni
  Future<DateTime> getFirstAvailableDate({
    required int locationId,
    required List<int> serviceIds,
    int? staffId,
  }) async {
    if (serviceIds.isEmpty) {
      return DateTime.now().add(const Duration(days: 1));
    }

    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    // Se oggi è già tardi, inizia da domani
    if (now.hour >= 18) {
      checkDate = checkDate.add(const Duration(days: 1));
    }

    // Cerca nei prossimi 30 giorni
    for (var i = 0; i < 30; i++) {
      try {
        final slots = await getAvailableSlots(
          locationId: locationId,
          date: checkDate,
          serviceIds: serviceIds,
          staffId: staffId,
        );

        if (slots.isNotEmpty) {
          return checkDate;
        }
      } catch (_) {
        // Ignora errori e prova il giorno successivo
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    // Fallback: domani
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// POST /v1/locations/{location_id}/bookings
  /// Conferma prenotazione
  ///
  /// Ritorna i dati del booking creato
  /// Throws ApiException con code='slot_conflict' se slot occupato
  Future<Map<String, dynamic>> confirmBooking({
    required int businessId,
    required int locationId,
    required List<int> serviceIds,
    required DateTime startTime,
    int? staffId,
    String? notes,
    String? idempotencyKey,
  }) async {
    // Genera idempotency key se non fornita
    final key = idempotencyKey ?? _uuid.v4();

    return _apiClient.createCustomerBooking(
      businessId: businessId,
      locationId: locationId,
      idempotencyKey: key,
      serviceIds: serviceIds,
      startTime: startTime.toUtc().toIso8601String(),
      staffId: staffId,
      notes: notes,
    );
  }

  /// Genera un nuovo idempotency key (UUID v4)
  String generateIdempotencyKey() => _uuid.v4();

  bool _isTruthy(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return true;
  }
}
