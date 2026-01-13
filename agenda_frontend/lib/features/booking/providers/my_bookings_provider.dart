import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/core/models/location.dart';
import '/core/models/booking_item.dart';
import '/core/network/network_providers.dart';
import '/features/booking/providers/business_provider.dart';
import '/features/booking/providers/locations_provider.dart';

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
      final response = await apiClient.getCustomerBookings();

      final businessName =
          ref.read(currentBusinessProvider).value?.name ?? '';
      final locationsAsync = ref.read(locationsProvider);
      final locationNames = <int, String>{};
      final locations = locationsAsync.value ?? const <Location>[];
      for (final location in locations) {
        locationNames[location.id] = location.name;
      }

      final upcomingJson = response['upcoming'] as List<dynamic>? ?? [];
      final pastJson = response['past'] as List<dynamic>? ?? [];

      final upcoming = upcomingJson
          .map(
            (json) => _fromCustomerBooking(
              json as Map<String, dynamic>,
              businessName: businessName,
              locationNames: locationNames,
            ),
          )
          .toList();

      final past = pastJson
          .map(
            (json) => _fromCustomerBooking(
              json as Map<String, dynamic>,
              businessName: businessName,
              locationNames: locationNames,
            ),
          )
          .toList();

      state = MyBookingsState(upcoming: upcoming, past: past, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cancella una prenotazione (DELETE /v1/customer/bookings/{id})
  Future<bool> cancelBooking(int locationId, int bookingId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.customerDeleteBooking(bookingId);

      state = state.copyWith(
        upcoming: state.upcoming.where((b) => b.id != bookingId).toList(),
        past: state.past.where((b) => b.id != bookingId).toList(),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Modifica una prenotazione (PUT /v1/customer/bookings/{id})
  Future<bool> rescheduleBooking({
    required int locationId,
    required int bookingId,
    required String newStartTime,
    String? notes,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final updated = await apiClient.customerUpdateBooking(
        bookingId: bookingId,
        startTime: newStartTime,
        notes: notes,
      );

      final businessName =
          ref.read(currentBusinessProvider).value?.name ?? '';
      final locationsAsync = ref.read(locationsProvider);
      final locationNames = <int, String>{};
      final locations = locationsAsync.value ?? const <Location>[];
      for (final location in locations) {
        locationNames[location.id] = location.name;
      }

      final updatedBooking = _fromCustomerBooking(
        updated,
        businessName: businessName,
        locationNames: locationNames,
      );

      final nextUpcoming =
          state.upcoming.where((b) => b.id != bookingId).toList();
      final nextPast = state.past.where((b) => b.id != bookingId).toList();

      if (updatedBooking.isUpcoming) {
        nextUpcoming.insert(0, updatedBooking);
      } else {
        nextPast.insert(0, updatedBooking);
      }

      state = state.copyWith(
        upcoming: nextUpcoming,
        past: nextPast,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

BookingItem _fromCustomerBooking(
  Map<String, dynamic> json, {
  required String businessName,
  required Map<int, String> locationNames,
}) {
  final items = (json['items'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  final firstItem = items.isNotEmpty ? items.first : const <String, dynamic>{};
  final lastItem = items.isNotEmpty ? items.last : const <String, dynamic>{};

  final locationId =
      json['location_id'] as int? ?? firstItem['location_id'] as int? ?? 0;
  final locationName =
      locationNames[locationId] ?? (json['location_name'] as String? ?? '');

  final startTimeValue = firstItem['start_time'] ?? json['start_time'];
  final endTimeValue =
      lastItem['end_time'] ?? firstItem['end_time'] ?? json['end_time'];
  final startTime = startTimeValue is String
      ? DateTime.parse(startTimeValue)
      : DateTime.now();
  final endTime = endTimeValue is String
      ? DateTime.parse(endTimeValue)
      : startTime;

  final serviceNames = items
      .map(
        (item) =>
            item['service_name'] ??
            item['service_name_snapshot'] ??
            '',
      )
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toList();

  final serviceIds = items
      .map((item) => item['service_id'])
      .whereType<int>()
      .toList();

  return BookingItem(
    id: json['id'] as int? ?? json['booking_id'] as int,
    businessId: json['business_id'] as int,
    businessName: businessName,
    locationId: locationId,
    locationName: locationName,
    locationAddress: json['location_address'] as String?,
    locationCity: json['location_city'] as String?,
    serviceNames: serviceNames,
    serviceIds: serviceIds,
    staffName: items.isNotEmpty
        ? items.first['staff_display_name'] as String?
        : null,
    startTime: startTime,
    endTime: endTime,
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String?,
    canModify: json['can_modify'] as bool? ?? false,
    canModifyUntil: json['can_modify_until'] != null
        ? DateTime.parse(json['can_modify_until'] as String)
        : null,
    status: json['status'] as String? ?? 'confirmed',
  );
}
