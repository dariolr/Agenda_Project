import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/core/models/booking_item.dart';
import '/core/network/network_providers.dart';

part 'my_bookings_provider.g.dart';

/// Stato delle prenotazioni utente (upcoming + past)
class MyBookingsState {
  final List<BookingItem> upcoming;
  final List<BookingItem> past;
  final bool isLoading;
  final String? error;

  const MyBookingsState({
    this.upcoming = const [],
    this.past = const [],
    this.isLoading = false,
    this.error,
  });

  MyBookingsState copyWith({
    List<BookingItem>? upcoming,
    List<BookingItem>? past,
    bool? isLoading,
    String? error,
  }) {
    return MyBookingsState(
      upcoming: upcoming ?? this.upcoming,
      past: past ?? this.past,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@riverpod
class MyBookings extends _$MyBookings {
  @override
  MyBookingsState build() {
    return const MyBookingsState();
  }

  /// Carica le prenotazioni utente da API
  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getMyBookings();

      final upcomingJson = response['upcoming'] as List<dynamic>? ?? [];
      final pastJson = response['past'] as List<dynamic>? ?? [];

      final upcoming = upcomingJson
          .map((json) => BookingItem.fromJson(json as Map<String, dynamic>))
          .toList();

      final past = pastJson
          .map((json) => BookingItem.fromJson(json as Map<String, dynamic>))
          .toList();

      state = MyBookingsState(upcoming: upcoming, past: past, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cancella una prenotazione (DELETE /v1/locations/{location_id}/bookings/{id})
  Future<bool> cancelBooking(int locationId, int bookingId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteBooking(locationId, bookingId);

      // Rimuovi localmente
      state = state.copyWith(
        upcoming: state.upcoming.where((b) => b.id != bookingId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Modifica una prenotazione (PUT /v1/locations/{location_id}/bookings/{id})
  Future<bool> rescheduleBooking({
    required int locationId,
    required int bookingId,
    required String newStartTime,
    String? notes,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final updated = await apiClient.updateBooking(
        locationId: locationId,
        bookingId: bookingId,
        startTime: newStartTime,
        notes: notes,
      );

      // Aggiorna localmente
      final updatedBooking = BookingItem.fromJson(updated);
      state = state.copyWith(
        upcoming: state.upcoming
            .map((b) => b.id == bookingId ? updatedBooking : b)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
