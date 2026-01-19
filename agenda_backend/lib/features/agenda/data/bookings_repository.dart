import '../../../core/models/appointment.dart';
import '../../../core/network/api_client.dart';
import '../domain/booking_response.dart';
import 'bookings_api.dart';

/// Metadata di un booking estratto dalla risposta appointments
class BookingMetadata {
  final int id;
  final int businessId;
  final int locationId;
  final int? clientId;
  final String? clientName;
  final String? notes;
  final String? status;

  const BookingMetadata({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.clientId,
    this.clientName,
    this.notes,
    this.status,
  });
}

/// Risultato contenente appointments e metadata dei booking
class AppointmentsWithMetadata {
  final List<Appointment> appointments;
  final Map<int, BookingMetadata> bookingMetadata;

  const AppointmentsWithMetadata({
    required this.appointments,
    required this.bookingMetadata,
  });
}

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
    final result = await getAppointmentsWithMetadata(
      locationId: locationId,
      businessId: businessId,
      date: date,
      staffId: staffId,
    );
    return result.appointments;
  }

  /// Carica gli appuntamenti con i metadata dei booking (incluse le note)
  Future<AppointmentsWithMetadata> getAppointmentsWithMetadata({
    required int locationId,
    required int businessId,
    required DateTime date,
    int? staffId,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Usa la nuova API appointments che ritorna direttamente gli appointment items
    try {
      final rawAppointments = await _api.fetchAppointments(
        locationId: locationId,
        date: dateStr,
      );

      final appointments = <Appointment>[];
      final bookingMetadata = <int, BookingMetadata>{};

      for (final json in rawAppointments) {
        appointments.add(_appointmentFromJson(json, businessId));

        // Estrai booking metadata (una volta per booking)
        final bookingId = json['booking_id'] as int;
        if (!bookingMetadata.containsKey(bookingId)) {
          bookingMetadata[bookingId] = BookingMetadata(
            id: bookingId,
            businessId: json['business_id'] as int? ?? businessId,
            locationId: json['location_id'] as int,
            clientId: json['client_id'] as int?,
            clientName: json['client_name'] as String?,
            notes: json['booking_notes'] as String?,
            status: json['booking_status'] as String?,
          );
        }
      }

      return AppointmentsWithMetadata(
        appointments: appointments,
        bookingMetadata: bookingMetadata,
      );
    } catch (e) {
      // Fallback: usa bookings API se appointments non disponibile
      final bookings = await _api.fetchBookings(
        locationId: locationId,
        date: dateStr,
        staffId: staffId,
      );

      final appointments = <Appointment>[];
      final bookingMetadata = <int, BookingMetadata>{};

      for (final booking in bookings) {
        // Estrai booking metadata
        bookingMetadata[booking.id] = BookingMetadata(
          id: booking.id,
          businessId: booking.businessId,
          locationId: booking.locationId,
          clientId: booking.clientId,
          clientName: booking.clientName,
          notes: booking.notes,
          status: booking.status,
        );

        for (final item in booking.items) {
          appointments.add(_toAppointment(booking, item, businessId));
        }
      }

      return AppointmentsWithMetadata(
        appointments: appointments,
        bookingMetadata: bookingMetadata,
      );
    }
  }

  /// Crea un nuovo booking (formato legacy con staff singolo per tutti i servizi)
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

  /// Crea un nuovo booking con items (staff e orario separati per ogni servizio)
  Future<BookingResponse> createBookingWithItems({
    required int locationId,
    required String idempotencyKey,
    required List<BookingItemRequest> items,
    int? clientId,
    String? notes,
  }) async {
    return _api.createBookingWithItems(
      locationId: locationId,
      idempotencyKey: idempotencyKey,
      items: items,
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
    int? clientId,
    bool clearClient = false,
  }) {
    return _api.updateBooking(
      locationId: locationId,
      bookingId: bookingId,
      status: status,
      notes: notes,
      clientId: clientId,
      clearClient: clearClient,
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
    return _api.updateAppointment(
      locationId: locationId,
      appointmentId: appointmentId,
      startTime: startTime?.toIso8601String(),
      endTime: endTime?.toIso8601String(),
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

  /// Aggiunge un nuovo booking item (appointment) a un booking esistente
  Future<Appointment> addBookingItem({
    required int bookingId,
    required int businessId,
    required int locationId,
    required int staffId,
    required int serviceId,
    required int serviceVariantId,
    required DateTime startTime,
    required DateTime endTime,
    String? serviceNameSnapshot,
    String? clientNameSnapshot,
    double? price,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
  }) async {
    final json = await _api.addBookingItem(
      bookingId: bookingId,
      locationId: locationId,
      staffId: staffId,
      serviceId: serviceId,
      serviceVariantId: serviceVariantId,
      startTime: startTime.toIso8601String(),
      endTime: endTime.toIso8601String(),
      serviceNameSnapshot: serviceNameSnapshot,
      clientNameSnapshot: clientNameSnapshot,
      price: price,
      extraBlockedMinutes: extraBlockedMinutes,
      extraProcessingMinutes: extraProcessingMinutes,
    );
    return _appointmentFromJson(json, businessId);
  }

  /// Elimina un singolo booking item (appointment) da un booking
  Future<void> deleteBookingItem({
    required int bookingId,
    required int itemId,
  }) async {
    await _api.deleteBookingItem(bookingId: bookingId, itemId: itemId);
  }

  /// Converte JSON appointment API in Appointment interno
  Appointment _appointmentFromJson(Map<String, dynamic> json, int businessId) {
    return Appointment(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      businessId: json['business_id'] as int? ?? businessId,
      locationId: json['location_id'] as int,
      staffId: json['staff_id'] as int,
      serviceId: json['service_id'] as int? ?? 0,
      serviceVariantId: json['service_variant_id'] as int,
      clientId: json['client_id'] as int?,
      clientName: json['client_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? 'Servizio',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      price: null, // Non sempre presente
      bookingSource: json['source'] as String?,
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
      clientName: booking.clientName ?? '',
      serviceName: item.serviceName ?? 'Service ${item.serviceId}',
      startTime: item.startDateTime,
      endTime: item.endDateTime,
      price: item.price,
      bookingSource: booking.source,
    );
  }
}
