import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agenda/providers/tenant_time_provider.dart';

/// State class for bookings list filter (date range and preset).
class BookingsListFilterState {
  const BookingsListFilterState({
    required this.startDate,
    required this.endDate,
    required this.selectedPreset,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String selectedPreset;

  BookingsListFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? selectedPreset,
  }) {
    return BookingsListFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedPreset: selectedPreset ?? this.selectedPreset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingsListFilterState &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          selectedPreset == other.selectedPreset;

  @override
  int get hashCode =>
      startDate.hashCode ^ endDate.hashCode ^ selectedPreset.hashCode;
}

/// Notifier for managing bookings list filter state.
class BookingsListFilterNotifier extends Notifier<BookingsListFilterState> {
  @override
  BookingsListFilterState build() {
    final today = ref.watch(tenantTodayProvider);
    return BookingsListFilterState(
      startDate: today,
      endDate: today,
      selectedPreset: 'today',
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      selectedPreset: 'custom',
    );
  }

  void setPreset(String preset) {
    state = state.copyWith(selectedPreset: preset);
  }

  void applyPreset(String preset) {
    final now = ref.read(tenantNowProvider);
    final today = ref.read(tenantTodayProvider);

    DateTime startDate;
    DateTime endDate;

    // Per la lista prenotazioni, i preset "correnti" mostrano SEMPRE
    // l'intero periodo (incluso futuro) per vedere cosa c'è in programma
    switch (preset) {
      case 'today':
        startDate = today;
        endDate = today;
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0); // Fine mese
        break;
      case 'quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterStartMonth, 1);
        endDate = DateTime(
          now.year,
          quarterStartMonth + 3,
          0,
        ); // Fine trimestre
        break;
      case 'semester':
        final semesterStartMonth = now.month <= 6 ? 1 : 7;
        startDate = DateTime(now.year, semesterStartMonth, 1);
        endDate = DateTime(
          now.year,
          semesterStartMonth + 6,
          0,
        ); // Fine semestre
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31); // Fine anno
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'last_3_months':
        startDate = DateTime(now.year, now.month - 3, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'last_6_months':
        startDate = DateTime(now.year, now.month - 6, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'last_year':
        startDate = DateTime(now.year - 1, 1, 1);
        endDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        // 'custom' - keep current dates
        return;
    }

    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      selectedPreset: preset,
    );
  }
}

/// Provider for bookings list filter state.
final bookingsListFilterProvider =
    NotifierProvider<BookingsListFilterNotifier, BookingsListFilterState>(
      BookingsListFilterNotifier.new,
    );
