import '../../../core/models/appointment.dart';
import '../../../core/network/api_client.dart';
import '../domain/booking_response.dart';
import 'bookings_api.dart';

/// Repository per gestione Bookings
/// Converte BookingResponse API in Appointment per uso interno
class BookingsRepository {
  BookingsRepository({required ApiClient apiClient})
    : _api = BookingsApi(apiClient: apiClient);

  final BookingsApi _api;

  /// Carica gli appuntamenti per una location in una data specifica
  Future<List<Appointment>> getAppointments({
    required int locationId,
    required int businessId,
    required DateTime date,
    int? staffId,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Usa la nuova API appointments che ritorna direttamente gli appointment items
    try {
      final appointments = await _api.fetchAppointments(
        locationId: locationId,
        date: dateStr,
      );

      return appointments
          .map((item) => _appointmentFromJson(item, businessId))
          .toList();
    } catch (e) {
      // Fallback: usa bookings API se appointments non disponibile
      final bookings = await _api.fetchBookings(
        locationId: locationId,
        date: dateStr,
        staffId: staffId,
      );

      final appointments = <Appointment>[];
      for (final booking in bookings) {
        for (final item in booking.items) {
          appointments.add(_toAppointment(booking, item, businessId));
        }
      }
      return appointments;
    }
  }

  /// Crea un nuovo booking
  Future<BookingResponse> createBooking({
    required int locationId,
    required String idempotencyKey,
    required List<int> serviceIds,
    required String startTime,
    int? staffId,
    int? clientId,
    String? notes,
  }) async {
    return _api.createBooking(
      locationId: locationId,
      idempotencyKey: idempotencyKey,
      serviceIds: serviceIds,
      startTime: startTime,
      staffId: staffId,
      clientId: clientId,
      notes: notes,
    );
  }

  /// Aggiorna un booking esistente
  Future<void> updateBooking({
    required int locationId,
    required int bookingId,
    String? status,
    String? notes,
  }) async {
    return _api.updateBooking(
      locationId: locationId,
      bookingId: bookingId,
      status: status,
      notes: notes,
    );
  }

  /// Cancella un booking
  Future<void> deleteBooking({
    required int locationId,
    required int bookingId,
  }) async {
    return _api.deleteBooking(locationId: locationId, bookingId: bookingId);
  }

  /// Aggiorna un appuntamento (reschedule)
  Future<void> updateAppointment({
    required int locationId,
    required int appointmentId,
    DateTime? startTime,
    DateTime? endTime,
    int? staffId,
  }) async {
    return _api.updateAppointment(
      locationId: locationId,
      appointmentId: appointmentId,
      startTime: startTime?.toIso8601String(),
      endTime: endTime?.toIso8601String(),
      staffId: staffId,
    );
  }

  /// Cancella un appuntamento
  Future<void> cancelAppointment({
    required int locationId,
    required int appointmentId,
  }) async {
    return _api.cancelAppointment(
      locationId: locationId,
      appointmentId: appointmentId,
    );
  }

  /// Converte JSON appointment API in Appointment interno
  Appointment _appointmentFromJson(Map<String, dynamic> json, int businessId) {
    return Appointment(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      businessId: businessId,
      locationId: json['location_id'] as int,
      staffId: json['staff_id'] as int,
      serviceId: json['service_id'] as int? ?? 0,
      serviceVariantId: json['service_variant_id'] as int,
      clientId: null, // Non sempre presente nel JSON appointments
      clientName: json['client_name'] as String? ?? 'Cliente',
      serviceName: json['service_name'] as String? ?? 'Servizio',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      price: null, // Non sempre presente
      extraMinutes: json['extra_blocked_minutes'] as int?,
      extraMinutesType:
          (json['extra_blocked_minutes'] as int?) != null &&
              json['extra_blocked_minutes'] > 0
          ? ExtraMinutesType.blocked
          : null,
      extraBlockedMinutes: json['extra_blocked_minutes'] as int? ?? 0,
      extraProcessingMinutes: json['extra_processing_minutes'] as int? ?? 0,
    );
  }

  /// Converte un booking item API in Appointment interno
  Appointment _toAppointment(
    BookingResponse booking,
    BookingItemResponse item,
    int businessId,
  ) {
    return Appointment(
      id: item.id,
      bookingId: booking.id,
      businessId: businessId,
      locationId: booking.locationId,
      staffId: item.staffId,
      serviceId: item.serviceId,
      serviceVariantId: item.serviceVariantId ?? item.serviceId,
      clientId: booking.clientId,
      clientName: booking.customerName ?? 'Cliente',
      serviceName: item.serviceName ?? 'Service ${item.serviceId}',
      startTime: item.startDateTime,
      endTime: item.endDateTime,
      price: item.price,
    );
  }
}
