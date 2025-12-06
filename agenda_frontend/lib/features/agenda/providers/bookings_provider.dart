import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import 'appointment_providers.dart';
import 'business_providers.dart';
import 'location_providers.dart';

class BookingSummary {
  final int bookingId;
  final int itemsCount;
  final double totalPrice;
  final DateTime? start;
  final DateTime? end;

  const BookingSummary({
    required this.bookingId,
    required this.itemsCount,
    required this.totalPrice,
    required this.start,
    required this.end,
  });
}

/// Gestisce i metadati delle prenotazioni (note, customerName, ecc.) e
/// coordina le operazioni di alto livello (cancellazione prenotazione intera).
class BookingsNotifier extends Notifier<Map<int, Booking>> {
  int _nextId = 1;

  @override
  Map<int, Booking> build() => <int, Booking>{};

  /// Crea una nuova prenotazione e restituisce il suo ID.
  int createBooking({int? clientId, String? customerName, String? notes}) {
    final business = ref.read(currentBusinessProvider);
    final location = ref.read(currentLocationProvider);

    final bookingId = _nextId++;
    state = {
      ...state,
      bookingId: Booking(
        id: bookingId,
        businessId: business.id,
        locationId: location.id,
        clientId: clientId,
        customerName: customerName,
        notes: notes,
      ),
    };
    return bookingId;
  }

  /// Crea la prenotazione se non esiste già (idempotente).
  void ensureBooking({
    required int bookingId,
    required int businessId,
    required int locationId,
    int? clientId,
    required String customerName,
  }) {
    final current = state;
    if (current.containsKey(bookingId)) return;
    state = {
      ...current,
      bookingId: Booking(
        id: bookingId,
        businessId: businessId,
        locationId: locationId,
        clientId: clientId,
        customerName: customerName,
        notes: null,
      ),
    };
  }

  void setNotes(int bookingId, String? notes) {
    final bk = state[bookingId];
    if (bk == null) return;
    state = {
      for (final e in state.entries)
        e.key: e.key == bookingId
            ? Booking(
                id: bk.id,
                businessId: bk.businessId,
                locationId: bk.locationId,
                clientId: bk.clientId,
                customerName: bk.customerName,
                notes: notes,
              )
            : e.value,
    };
  }

  /// Cancella l'intera prenotazione e tutti i suoi appuntamenti.
  void deleteBooking(int bookingId) {
    // Aggiorna appuntamenti in cascata
    ref.read(appointmentsProvider.notifier).deleteByBooking(bookingId);
    // Rimuovi metadati prenotazione
    final copy = Map<int, Booking>.from(state);
    copy.remove(bookingId);
    state = copy;
  }

  /// Rimuove la prenotazione se non ha più appuntamenti.
  void removeIfEmpty(int bookingId) {
    final appts = ref.read(appointmentsProvider);
    if (appts.any((a) => a.bookingId == bookingId)) return;
    final copy = Map<int, Booking>.from(state);
    copy.remove(bookingId);
    state = copy;
  }
}

final bookingsProvider = NotifierProvider<BookingsNotifier, Map<int, Booking>>(
  BookingsNotifier.new,
);

/// Riepilogo calcolato su appointment per un booking.
final bookingSummaryProvider = Provider.family<BookingSummary?, int>((ref, id) {
  final appts = ref
      .watch(appointmentsProvider)
      .where((a) => a.bookingId == id)
      .toList();
  if (appts.isEmpty) return null;

  appts.sort((a, b) => a.startTime.compareTo(b.startTime));
  final totalPrice = appts.fold<double>(0.0, (sum, a) => sum + (a.price ?? 0));
  return BookingSummary(
    bookingId: id,
    itemsCount: appts.length,
    totalPrice: totalPrice,
    start: appts.first.startTime,
    end: appts.map((a) => a.endTime).reduce((a, b) => a.isAfter(b) ? a : b),
  );
});
