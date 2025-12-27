import '../../../core/network/api_client.dart';
import '../domain/booking_response.dart';

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

  /// PUT /v1/locations/{location_id}/bookings/{booking_id}
  Future<void> updateBooking({
    required int locationId,
    required int bookingId,
    String? status,
    String? notes,
  }) async {
    await _apiClient.updateBooking(
      locationId: locationId,
      bookingId: bookingId,
      status: status,
      notes: notes,
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
  }) async {
    await _apiClient.updateAppointment(
      locationId: locationId,
      appointmentId: appointmentId,
      startTime: startTime,
      endTime: endTime,
      staffId: staffId,
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
}
