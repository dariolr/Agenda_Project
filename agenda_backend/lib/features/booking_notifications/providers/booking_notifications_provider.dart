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
    this.sortBy = 'last_attempt',
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

  void setSortOrder(String sortOrder) {
    state = state.copyWith(sortOrder: sortOrder == 'asc' ? 'asc' : 'desc');
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
    await loadNotificationsForBusinesses([businessId]);
  }

  Future<void> loadNotificationsForBusinesses(List<int> businessIds) async {
    final filters = ref.read(bookingNotificationsFiltersProvider);
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _fetchCombinedResult(
        businessIds: businessIds,
        filters: filters,
        offset: 0,
        pageSize: state.limit,
      );
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
    await loadMoreForBusinesses([businessId]);
  }

  Future<void> loadMoreForBusinesses(List<int> businessIds) async {
    if (state.isLoadingMore || !state.hasMore) return;

    final filters = ref.read(bookingNotificationsFiltersProvider);
    state = state.copyWith(isLoadingMore: true);

    try {
      final newOffset = state.offset + state.limit;
      final result = await _fetchCombinedResult(
        businessIds: businessIds,
        filters: filters,
        offset: newOffset,
        pageSize: state.limit,
      );
      state = state.copyWith(
        notifications: result.notifications,
        total: result.total,
        offset: newOffset,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<BookingNotificationsResult> _fetchCombinedResult({
    required List<int> businessIds,
    required BookingNotificationsFilters filters,
    required int offset,
    required int pageSize,
  }) async {
    final ids = businessIds.toSet().where((id) => id > 0).toList();
    if (ids.isEmpty) {
      return const BookingNotificationsResult(
        notifications: [],
        total: 0,
        limit: 50,
        offset: 0,
      );
    }

    final apiClient = ref.read(apiClientProvider);

    if (ids.length == 1) {
      final response = await apiClient.getBookingNotifications(
        businessId: ids.first,
        search: filters.search,
        status: filters.status,
        channels: filters.channels,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
        limit: pageSize,
        offset: offset,
      );
      return BookingNotificationsResult.fromJson(response);
    }

    final perBusinessLimit = offset + pageSize;
    final responses = await Future.wait(
      ids.map(
        (id) => apiClient.getBookingNotifications(
          businessId: id,
          search: filters.search,
          status: filters.status,
          channels: filters.channels,
          sortBy: filters.sortBy,
          sortOrder: filters.sortOrder,
          limit: perBusinessLimit,
          offset: 0,
        ),
      ),
    );

    var total = 0;
    final merged = <BookingNotificationItem>[];
    for (final response in responses) {
      final result = BookingNotificationsResult.fromJson(response);
      total += result.total;
      merged.addAll(result.notifications);
    }

    merged.sort((a, b) => _compareBySort(a, b, filters.sortBy, filters.sortOrder));
    final visibleCount = perBusinessLimit < merged.length
        ? perBusinessLimit
        : merged.length;
    final visible = merged.take(visibleCount).toList(growable: false);

    return BookingNotificationsResult(
      notifications: visible,
      total: total,
      limit: pageSize,
      offset: offset,
    );
  }

  int _compareBySort(
    BookingNotificationItem a,
    BookingNotificationItem b,
    String sortBy,
    String sortOrder,
  ) {
    DateTime aDate;
    DateTime bDate;
    switch (sortBy) {
      case 'sent':
        aDate = a.sentAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        bDate = b.sentAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        break;
      case 'scheduled':
        aDate = a.scheduledAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        bDate = b.scheduledAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        break;
      case 'last_attempt':
        aDate = a.lastAttemptAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        bDate = b.lastAttemptAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        break;
      case 'appointment':
        aDate = a.firstStartTime ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        bDate = b.firstStartTime ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        break;
      default:
        aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        break;
    }
    final cmp = aDate.compareTo(bDate);
    if (cmp == 0) {
      return a.id.compareTo(b.id);
    }
    return sortOrder == 'asc' ? cmp : -cmp;
  }
}
