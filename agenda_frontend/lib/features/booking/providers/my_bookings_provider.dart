import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/core/models/booking_item.dart';
import '/core/models/location.dart';
import '/core/models/service_package.dart';
import '/core/network/api_client.dart';
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

      final packagesByLocation = await _loadPackagesByLocation(
        apiClient,
        [...upcomingJson, ...pastJson],
      );

      final upcoming = upcomingJson
          .map(
            (json) => _fromCustomerBooking(
              json as Map<String, dynamic>,
              businessName: businessName,
              locationNames: locationNames,
              packagesByLocation: packagesByLocation,
            ),
          )
          .toList();

      final past = pastJson
          .map(
            (json) => _fromCustomerBooking(
              json as Map<String, dynamic>,
              businessName: businessName,
              locationNames: locationNames,
              packagesByLocation: packagesByLocation,
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

      await loadBookings();
      return state.error == null;
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

      final packagesByLocation = await _loadPackagesByLocation(
        apiClient,
        [updated],
      );
      final updatedBooking = _fromCustomerBooking(
        updated,
        businessName: businessName,
        locationNames: locationNames,
        packagesByLocation: packagesByLocation,
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

  /// Sostituisce una prenotazione (POST /v1/customer/bookings/{id}/replace)
  /// Usa il pattern atomic replace: l'originale diventa 'replaced', viene creata una nuova
  Future<({bool success, int? newBookingId})> replaceBooking({
    required int originalBookingId,
    required int locationId,
    required List<int> serviceIds,
    required String startTime,
    required String idempotencyKey,
    int? staffId,
    String? notes,
    String? reason,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.customerReplaceBooking(
        bookingId: originalBookingId,
        idempotencyKey: idempotencyKey,
        locationId: locationId,
        serviceIds: serviceIds,
        startTime: startTime,
        staffId: staffId,
        notes: notes,
        reason: reason,
      );

      final businessName =
          ref.read(currentBusinessProvider).value?.name ?? '';
      final locationsAsync = ref.read(locationsProvider);
      final locationNames = <int, String>{};
      final locations = locationsAsync.value ?? const <Location>[];
      for (final location in locations) {
        locationNames[location.id] = location.name;
      }

      final packagesByLocation = await _loadPackagesByLocation(
        apiClient,
        [response],
      );
      final newBooking = _fromCustomerBooking(
        response,
        businessName: businessName,
        locationNames: locationNames,
        packagesByLocation: packagesByLocation,
      );

      // Rimuovi la prenotazione originale dalla lista e aggiungi la nuova
      final nextUpcoming = state.upcoming
          .where((b) => b.id != originalBookingId)
          .toList();
      final nextPast = state.past
          .where((b) => b.id != originalBookingId)
          .toList();

      if (newBooking.isUpcoming) {
        nextUpcoming.insert(0, newBooking);
      } else {
        nextPast.insert(0, newBooking);
      }

      state = state.copyWith(
        upcoming: nextUpcoming,
        past: nextPast,
        error: null,
      );

      return (success: true, newBookingId: newBooking.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return (success: false, newBookingId: null);
    }
  }
}

BookingItem _fromCustomerBooking(
  Map<String, dynamic> json, {
  required String businessName,
  required Map<int, String> locationNames,
  required Map<int, List<ServicePackage>> packagesByLocation,
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

  final serviceIds = items
      .map((item) => item['service_id'])
      .whereType<int>()
      .toList();

  final serviceNameById = <int, String>{};
  for (final item in items) {
    final serviceId = item['service_id'];
    if (serviceId is! int || serviceNameById.containsKey(serviceId)) {
      continue;
    }
    final name = item['service_name'] ?? item['service_name_snapshot'];
    if (name is String && name.isNotEmpty) {
      serviceNameById[serviceId] = name;
    }
  }

  final remainingServiceIds = serviceIds.toSet();
  final packageNames = <String>[];
  final packages = packagesByLocation[locationId] ?? const <ServicePackage>[];
  final sortedPackages = [...packages]
    ..sort(
      (a, b) =>
          b.orderedServiceIds.length.compareTo(a.orderedServiceIds.length),
    );
  for (final package in sortedPackages) {
    if (!package.isActive || package.isBroken) continue;
    final packageServiceIds = package.orderedServiceIds;
    if (packageServiceIds.isEmpty) continue;
    if (packageServiceIds.every(remainingServiceIds.contains)) {
      packageNames.add(package.name);
      for (final id in packageServiceIds) {
        remainingServiceIds.remove(id);
      }
    }
  }

  final remainingServiceNames = <String>[];
  for (final item in items) {
    final serviceId = item['service_id'];
    if (serviceId is! int || !remainingServiceIds.contains(serviceId)) {
      continue;
    }
    final name = item['service_name'] ?? item['service_name_snapshot'];
    if (name is String && name.isNotEmpty) {
      remainingServiceNames.add(name);
      remainingServiceIds.remove(serviceId);
    }
  }

  final serviceNames = [...packageNames, ...remainingServiceNames];

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

Future<Map<int, List<ServicePackage>>> _loadPackagesByLocation(
  ApiClient apiClient,
  List<dynamic> bookingsJson,
) async {
  final locationIds = <int>{};
  for (final entry in bookingsJson) {
    if (entry is! Map<String, dynamic>) continue;
    final items = (entry['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final firstItem =
        items.isNotEmpty ? items.first : const <String, dynamic>{};
    final locationId =
        entry['location_id'] as int? ?? firstItem['location_id'] as int? ?? 0;
    if (locationId > 0) {
      locationIds.add(locationId);
    }
  }

  final packagesByLocation = <int, List<ServicePackage>>{};
  for (final locationId in locationIds) {
    final response = await apiClient.getServicePackages(locationId);
    final packagesJson = response['packages'] as List<dynamic>? ?? [];
    final packages = packagesJson
        .map((json) => ServicePackage.fromJson(json as Map<String, dynamic>))
        .toList();
    packagesByLocation[locationId] = packages;
  }

  return packagesByLocation;
}
