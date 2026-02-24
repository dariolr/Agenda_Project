import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/booking_list_item.dart';
import '/core/network/network_providers.dart';
import '../../agenda/providers/tenant_time_provider.dart';

/// Stato per i filtri della lista prenotazioni
class BookingsListFilters {
  final int? locationId;
  final List<int>? locationIds;
  final int? staffId;
  final List<int>? staffIds;
  final List<int>? serviceIds;
  final String? clientSearch;
  final List<String>? status;
  final String? source;
  final String? startDate;
  final String? endDate;
  final bool includePast;
  final String sortBy; // 'appointment' or 'created'
  final String sortOrder; // 'asc' or 'desc'

  const BookingsListFilters({
    this.locationId,
    this.locationIds,
    this.staffId,
    this.staffIds,
    this.serviceIds,
    this.clientSearch,
    this.status,
    this.source,
    this.startDate,
    this.endDate,
    this.includePast = false,
    this.sortBy = 'appointment',
    this.sortOrder = 'desc',
  });

  BookingsListFilters copyWith({
    int? locationId,
    bool clearLocationId = false,
    List<int>? locationIds,
    bool clearLocationIds = false,
    int? staffId,
    bool clearStaffId = false,
    List<int>? staffIds,
    bool clearStaffIds = false,
    List<int>? serviceIds,
    bool clearServiceIds = false,
    String? clientSearch,
    bool clearClientSearch = false,
    List<String>? status,
    bool clearStatus = false,
    String? source,
    bool clearSource = false,
    String? startDate,
    bool clearStartDate = false,
    String? endDate,
    bool clearEndDate = false,
    bool? includePast,
    String? sortBy,
    String? sortOrder,
  }) {
    return BookingsListFilters(
      locationId: clearLocationId ? null : (locationId ?? this.locationId),
      locationIds: clearLocationIds ? null : (locationIds ?? this.locationIds),
      staffId: clearStaffId ? null : (staffId ?? this.staffId),
      staffIds: clearStaffIds ? null : (staffIds ?? this.staffIds),
      serviceIds: clearServiceIds ? null : (serviceIds ?? this.serviceIds),
      clientSearch: clearClientSearch
          ? null
          : (clientSearch ?? this.clientSearch),
      status: clearStatus ? null : (status ?? this.status),
      source: clearSource ? null : (source ?? this.source),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      includePast: includePast ?? this.includePast,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Resetta tutti i filtri ai valori default
  factory BookingsListFilters.defaultFilters({required DateTime today}) {
    // Default: ultimi 3 giorni fino a domani
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final tomorrow = today.add(const Duration(days: 1));

    return BookingsListFilters(
      startDate: _formatDate(threeDaysAgo),
      endDate: _formatDate(tomorrow),
      includePast: true, // Per vedere anche gli appuntamenti passati nel range
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Indica se ci sono filtri attivi (oltre ai default)
  bool get hasActiveFilters {
    return locationId != null ||
        (locationIds != null && locationIds!.isNotEmpty) ||
        staffId != null ||
        (staffIds != null && staffIds!.isNotEmpty) ||
        (serviceIds != null && serviceIds!.isNotEmpty) ||
        (clientSearch != null && clientSearch!.isNotEmpty) ||
        (status != null && status!.isNotEmpty) ||
        (source != null && source!.isNotEmpty);
  }

  @override
  String toString() {
    return 'BookingsListFilters(locationId: $locationId, locationIds: $locationIds, staffId: $staffId, staffIds: $staffIds, serviceIds: $serviceIds, clientSearch: $clientSearch, status: $status, source: $source, startDate: $startDate, endDate: $endDate, includePast: $includePast, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}

/// Provider per i filtri correnti
final bookingsListFiltersProvider =
    NotifierProvider<BookingsListFiltersNotifier, BookingsListFilters>(
      BookingsListFiltersNotifier.new,
    );

class BookingsListFiltersNotifier extends Notifier<BookingsListFilters> {
  @override
  BookingsListFilters build() {
    final today = ref.watch(tenantTodayProvider);
    return BookingsListFilters.defaultFilters(today: today);
  }

  void updateFilters(BookingsListFilters filters) {
    state = filters;
  }

  void setLocationId(int? locationId) {
    state = state.copyWith(
      locationId: locationId,
      clearLocationId: locationId == null,
      clearLocationIds: true,
    );
  }

  void setLocationIds(List<int>? locationIds) {
    state = state.copyWith(
      locationIds: locationIds,
      clearLocationIds: locationIds == null || locationIds.isEmpty,
      clearLocationId: true,
    );
  }

  void setStaffId(int? staffId) {
    state = state.copyWith(
      staffId: staffId,
      clearStaffId: staffId == null,
      clearStaffIds: true,
    );
  }

  void setStaffIds(List<int>? staffIds) {
    state = state.copyWith(
      staffIds: staffIds,
      clearStaffIds: staffIds == null || staffIds.isEmpty,
      clearStaffId: true,
    );
  }

  void setServiceIds(List<int>? serviceIds) {
    state = state.copyWith(
      serviceIds: serviceIds,
      clearServiceIds: serviceIds == null || serviceIds.isEmpty,
    );
  }

  void setClientSearch(String? search) {
    state = state.copyWith(
      clientSearch: search,
      clearClientSearch: search == null || search.isEmpty,
    );
  }

  void setStatus(List<String>? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setSource(String? source) {
    state = state.copyWith(
      source: source,
      clearSource: source == null || source.isEmpty,
    );
  }

  void setDateRange(String? startDate, String? endDate) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      clearStartDate: startDate == null,
      clearEndDate: endDate == null,
    );
  }

  void setIncludePast(bool includePast) {
    state = state.copyWith(includePast: includePast);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setSortOrder(String sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  void toggleSortOrder() {
    state = state.copyWith(
      sortOrder: state.sortOrder == 'asc' ? 'desc' : 'asc',
    );
  }

  void reset() {
    final today = ref.read(tenantTodayProvider);
    state = BookingsListFilters.defaultFilters(today: today);
  }
}

/// Stato per la lista prenotazioni (include paginazione)
class BookingsListState {
  final List<BookingListItem> bookings;
  final int total;
  final int offset;
  final int limit;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const BookingsListState({
    this.bookings = const [],
    this.total = 0,
    this.offset = 0,
    this.limit = 50,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => offset + bookings.length < total;
  bool get isEmpty => bookings.isEmpty && !isLoading;

  BookingsListState copyWith({
    List<BookingListItem>? bookings,
    int? total,
    int? offset,
    int? limit,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return BookingsListState(
      bookings: bookings ?? this.bookings,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider per la lista prenotazioni con stato
final bookingsListProvider =
    NotifierProvider<BookingsListNotifier, BookingsListState>(
      BookingsListNotifier.new,
    );

class BookingsListNotifier extends Notifier<BookingsListState> {
  @override
  BookingsListState build() => const BookingsListState();

  /// Carica la prima pagina (reset)
  Future<void> loadBookings(int businessId) async {
    final filters = ref.read(bookingsListFiltersProvider);
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getBookingsList(
        businessId: businessId,
        locationId: filters.locationId,
        locationIds: filters.locationIds,
        staffId: filters.staffId,
        staffIds: filters.staffIds,
        serviceIds: filters.serviceIds,
        clientSearch: filters.clientSearch,
        status: filters.status,
        source: filters.source,
        startDate: filters.startDate,
        endDate: filters.endDate,
        includePast: filters.includePast,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
        limit: state.limit,
        offset: 0,
      );

      final result = BookingListResult.fromJson(response);
      state = state.copyWith(
        bookings: result.bookings,
        total: result.total,
        offset: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Carica la pagina successiva (append)
  Future<void> loadMore(int businessId) async {
    if (state.isLoadingMore || !state.hasMore) return;

    final filters = ref.read(bookingsListFiltersProvider);
    state = state.copyWith(isLoadingMore: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final newOffset = state.offset + state.limit;

      final response = await apiClient.getBookingsList(
        businessId: businessId,
        locationId: filters.locationId,
        locationIds: filters.locationIds,
        staffId: filters.staffId,
        staffIds: filters.staffIds,
        serviceIds: filters.serviceIds,
        clientSearch: filters.clientSearch,
        status: filters.status,
        source: filters.source,
        startDate: filters.startDate,
        endDate: filters.endDate,
        includePast: filters.includePast,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
        limit: state.limit,
        offset: newOffset,
      );

      final result = BookingListResult.fromJson(response);
      state = state.copyWith(
        bookings: [...state.bookings, ...result.bookings],
        total: result.total,
        offset: newOffset,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Ricarica dopo cancellazione
  Future<void> refresh(int businessId) async {
    await loadBookings(businessId);
  }

  /// Rimuovi un booking dalla lista (ottimistic update dopo cancellazione)
  void removeBooking(int bookingId) {
    final newList = state.bookings.where((b) => b.id != bookingId).toList();
    state = state.copyWith(
      bookings: newList,
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }
}
