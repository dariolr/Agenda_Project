import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/booking_notification_item.dart';
import '/core/network/network_providers.dart';

class BookingNotificationsFilters {
  final String? search;
  final List<String>? status;
  final List<String>? channels;
  final String sortBy;
  final String sortOrder;

  const BookingNotificationsFilters({
    this.search,
    this.status,
    this.channels,
    this.sortBy = 'created',
    this.sortOrder = 'desc',
  });

  BookingNotificationsFilters copyWith({
    String? search,
    bool clearSearch = false,
    List<String>? status,
    bool clearStatus = false,
    List<String>? channels,
    bool clearChannels = false,
    String? sortBy,
    String? sortOrder,
  }) {
    return BookingNotificationsFilters(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      channels: clearChannels ? null : (channels ?? this.channels),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

final bookingNotificationsFiltersProvider =
    NotifierProvider<
      BookingNotificationsFiltersNotifier,
      BookingNotificationsFilters
    >(BookingNotificationsFiltersNotifier.new);

class BookingNotificationsFiltersNotifier
    extends Notifier<BookingNotificationsFilters> {
  @override
  BookingNotificationsFilters build() => const BookingNotificationsFilters();

  void setSearch(String? search) {
    state = state.copyWith(
      search: search,
      clearSearch: search == null || search.isEmpty,
    );
  }

  void setStatus(List<String>? status) {
    state = state.copyWith(
      status: status,
      clearStatus: status == null || status.isEmpty,
    );
  }

  void setChannels(List<String>? channels) {
    state = state.copyWith(
      channels: channels,
      clearChannels: channels == null || channels.isEmpty,
    );
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleSortOrder() {
    state = state.copyWith(
      sortOrder: state.sortOrder == 'asc' ? 'desc' : 'asc',
    );
  }

  void reset() {
    state = const BookingNotificationsFilters();
  }
}

class BookingNotificationsState {
  final List<BookingNotificationItem> notifications;
  final int total;
  final int offset;
  final int limit;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const BookingNotificationsState({
    this.notifications = const [],
    this.total = 0,
    this.offset = 0,
    this.limit = 50,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => offset + notifications.length < total;
  bool get isEmpty => notifications.isEmpty && !isLoading;

  BookingNotificationsState copyWith({
    List<BookingNotificationItem>? notifications,
    int? total,
    int? offset,
    int? limit,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return BookingNotificationsState(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final bookingNotificationsProvider =
    NotifierProvider<BookingNotificationsNotifier, BookingNotificationsState>(
      BookingNotificationsNotifier.new,
    );

class BookingNotificationsNotifier extends Notifier<BookingNotificationsState> {
  @override
  BookingNotificationsState build() => const BookingNotificationsState();

  Future<void> loadNotifications(int businessId) async {
    final filters = ref.read(bookingNotificationsFiltersProvider);
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getBookingNotifications(
        businessId: businessId,
        search: filters.search,
        status: filters.status,
        channels: filters.channels,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
        limit: state.limit,
        offset: 0,
      );

      final result = BookingNotificationsResult.fromJson(response);
      state = state.copyWith(
        notifications: result.notifications,
        total: result.total,
        offset: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore(int businessId) async {
    if (state.isLoadingMore || !state.hasMore) return;

    final filters = ref.read(bookingNotificationsFiltersProvider);
    state = state.copyWith(isLoadingMore: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final newOffset = state.offset + state.limit;
      final response = await apiClient.getBookingNotifications(
        businessId: businessId,
        search: filters.search,
        status: filters.status,
        channels: filters.channels,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
        limit: state.limit,
        offset: newOffset,
      );

      final result = BookingNotificationsResult.fromJson(response);
      state = state.copyWith(
        notifications: [...state.notifications, ...result.notifications],
        total: result.total,
        offset: newOffset,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}
