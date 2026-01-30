import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for Reports screen filters - shared between shell AppBar and ReportsScreen
class ReportsFilterState {
  const ReportsFilterState({
    required this.startDate,
    required this.endDate,
    this.selectedPreset = 'custom',
    this.useFullPeriod = false,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String selectedPreset;
  final bool useFullPeriod;

  ReportsFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? selectedPreset,
    bool? useFullPeriod,
  }) {
    return ReportsFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      useFullPeriod: useFullPeriod ?? this.useFullPeriod,
    );
  }
}

class ReportsFilterNotifier extends Notifier<ReportsFilterState> {
  @override
  ReportsFilterState build() {
    final today = DateUtils.dateOnly(DateTime.now());
    return ReportsFilterState(
      startDate: today,
      endDate: today,
      selectedPreset: 'today',
      useFullPeriod: false,
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

  void setFullPeriod(bool value) {
    state = state.copyWith(useFullPeriod: value);
  }

  void applyPreset(String preset) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final useFullPeriod = state.useFullPeriod;

    DateTime startDate;
    DateTime endDate;

    switch (preset) {
      case 'today':
        startDate = today;
        endDate = today;
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = useFullPeriod ? DateTime(now.year, now.month + 1, 0) : today;
        break;
      case 'quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterStartMonth, 1);
        endDate = useFullPeriod
            ? DateTime(now.year, quarterStartMonth + 3, 0)
            : today;
        break;
      case 'semester':
        final semesterStartMonth = now.month <= 6 ? 1 : 7;
        startDate = DateTime(now.year, semesterStartMonth, 1);
        endDate = useFullPeriod
            ? DateTime(now.year, semesterStartMonth + 6, 0)
            : today;
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = useFullPeriod ? DateTime(now.year, 12, 31) : today;
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
        // custom - keep current dates
        startDate = state.startDate;
        endDate = state.endDate;
    }

    state = ReportsFilterState(
      startDate: startDate,
      endDate: endDate,
      selectedPreset: preset,
      useFullPeriod: useFullPeriod,
    );
  }
}

final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, ReportsFilterState>(
      ReportsFilterNotifier.new,
    );
