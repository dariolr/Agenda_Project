import '../../../core/network/api_client.dart';
import '../domain/booking_response.dart';

/// Request item per creazione booking con staff/orario per ogni servizio
/// Include campi opzionali per override dei valori di default del servizio
class BookingItemRequest {
  final int serviceId;
  final int staffId;
  final String startTime;
  // Optional overrides (if null, backend uses service defaults)
  final int? serviceVariantId;
  final int? durationMinutes;
  final int? blockedExtraMinutes;
  final int? processingExtraMinutes;
  final double? price;

  const BookingItemRequest({
    required this.serviceId,
    required this.staffId,
    required this.startTime,
    this.serviceVariantId,
    this.durationMinutes,
    this.blockedExtraMinutes,
    this.processingExtraMinutes,
    this.price,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'service_id': serviceId,
      'staff_id': staffId,
      'start_time': startTime,
    };
    if (serviceVariantId != null) map['service_variant_id'] = serviceVariantId;
    if (durationMinutes != null) map['duration_minutes'] = durationMinutes;
    if (blockedExtraMinutes != null) {
      map['blocked_extra_minutes'] = blockedExtraMinutes;
    }
    if (processingExtraMinutes != null) {
      map['processing_extra_minutes'] = processingExtraMinutes;
    }
    if (price != null) map['price'] = price;
    return map;
  }
}

/// API layer per Bookings - chiamate reali a agenda_core
class BookingsApi {
  final ApiClient _apiClient;

  BookingsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /v1/locations/{location_id}/bookings?date=YYYY-MM-DD[&staff_id=X]
  Future<List<BookingResponse>> fetchBookings({
    required int locationId,
    required String date,
    int? staffId,
  }) async {
    final data = await _apiClient.getBookings(
      locationId: locationId,
      date: date,
      staffId: staffId,
    );
    final List<dynamic> items = data['bookings'] ?? [];
    return items
        .map((json) => BookingResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /v1/locations/{location_id}/bookings/{booking_id}
  Future<BookingResponse> fetchBooking({
    required int locationId,
    required int bookingId,
  }) async {
    final data = await _apiClient.getBooking(
      locationId: locationId,
      bookingId: bookingId,
    );
    return BookingResponse.fromJson(data);
  }

  /// POST /v1/locations/{location_id}/bookings
  Future<BookingResponse> createBooking({
    required int locationId,
    required String idempotencyKey,
    required List<int> serviceIds,
    required String startTime,
    int? staffId,
    int? clientId,
    String? notes,
  }) async {
    final data = await _apiClient.createBooking(
      locationId: locationId,
      idempotencyKey: idempotencyKey,
      serviceIds: serviceIds,
      startTime: startTime,
      staffId: staffId,
      clientId: clientId,
      notes: notes,
    );
    return BookingResponse.fromJson(data);
  }

  /// POST /v1/locations/{location_id}/bookings (new items format)
  Future<BookingResponse> createBookingWithItems({
    required int locationId,
    required String idempotencyKey,
    required List<BookingItemRequest> items,
    int? clientId,
    String? notes,
  }) async {
    final data = await _apiClient.createBookingWithItems(
      locationId: locationId,
      idempotencyKey: idempotencyKey,
      items: items.map((i) => i.toJson()).toList(),
      clientId: clientId,
      notes: notes,
    );
    return BookingResponse.fromJson(data);
  }

  /// PUT /v1/locations/{location_id}/bookings/{booking_id}
  Future<void> updateBooking({
    required int locationId,
    required int bookingId,
    String? status,
    String? notes,
    int? clientId,
    bool clearClient = false,
  }) async {
    await _apiClient.updateBooking(
      locationId: locationId,
      bookingId: bookingId,
      status: status,
      notes: notes,
      clientId: clientId,
      clearClient: clearClient,
    );
  }

  /// DELETE /v1/locations/{location_id}/bookings/{booking_id}
  Future<void> deleteBooking({
    required int locationId,
    required int bookingId,
  }) async {
    await _apiClient.deleteBooking(
      locationId: locationId,
      bookingId: bookingId,
    );
  }

  /// GET /v1/locations/{location_id}/appointments?date=YYYY-MM-DD
  Future<List<Map<String, dynamic>>> fetchAppointments({
    required int locationId,
    required String date,
  }) async {
    final data = await _apiClient.getAppointments(
      locationId: locationId,
      date: date,
    );
    final List<dynamic> items = data['appointments'] ?? [];
    return items.map((json) => json as Map<String, dynamic>).toList();
  }

  /// PATCH /v1/locations/{location_id}/appointments/{id}
  Future<void> updateAppointment({
    required int locationId,
    required int appointmentId,
    String? startTime,
    String? endTime,
    int? staffId,
    int? serviceId,
    int? serviceVariantId,
    String? serviceNameSnapshot,
    int? clientId,
    String? clientName,
    String? clientNameSnapshot,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
    double? price,
    bool priceExplicitlySet = false,
  }) async {
    await _apiClient.updateAppointment(
      locationId: locationId,
      appointmentId: appointmentId,
      startTime: startTime,
      endTime: endTime,
      staffId: staffId,
      serviceId: serviceId,
      serviceVariantId: serviceVariantId,
      serviceNameSnapshot: serviceNameSnapshot,
      clientId: clientId,
      clientName: clientName,
      clientNameSnapshot: clientNameSnapshot,
      extraBlockedMinutes: extraBlockedMinutes,
      extraProcessingMinutes: extraProcessingMinutes,
      price: price,
      priceExplicitlySet: priceExplicitlySet,
    );
  }

  /// POST /v1/locations/{location_id}/appointments/{id}/cancel
  Future<void> cancelAppointment({
    required int locationId,
    required int appointmentId,
  }) async {
    await _apiClient.cancelAppointment(
      locationId: locationId,
      appointmentId: appointmentId,
    );
  }

  /// POST /v1/bookings/{booking_id}/items
  /// Add a new booking item (appointment) to an existing booking
  Future<Map<String, dynamic>> addBookingItem({
    required int bookingId,
    required int locationId,
    required int staffId,
    required int serviceId,
    required int serviceVariantId,
    required String startTime,
    required String endTime,
    String? serviceNameSnapshot,
    String? clientNameSnapshot,
    double? price,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
  }) async {
    return _apiClient.addBookingItem(
      bookingId: bookingId,
      locationId: locationId,
      staffId: staffId,
      serviceId: serviceId,
      serviceVariantId: serviceVariantId,
      startTime: startTime,
      endTime: endTime,
      serviceNameSnapshot: serviceNameSnapshot,
      clientNameSnapshot: clientNameSnapshot,
      price: price,
      extraBlockedMinutes: extraBlockedMinutes,
      extraProcessingMinutes: extraProcessingMinutes,
    );
  }

  /// DELETE /v1/bookings/{booking_id}/items/{item_id}
  /// Delete a single booking item (appointment) from a booking
  Future<void> deleteBookingItem({
    required int bookingId,
    required int itemId,
  }) async {
    await _apiClient.deleteBookingItem(bookingId: bookingId, itemId: itemId);
  }
}
