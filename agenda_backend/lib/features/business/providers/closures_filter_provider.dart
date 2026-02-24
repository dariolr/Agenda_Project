import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agenda/providers/tenant_time_provider.dart';

/// State for Closures screen filters
class ClosuresFilterState {
  const ClosuresFilterState({
    required this.startDate,
    required this.endDate,
    this.selectedPreset = 'from_today',
  });

  final DateTime startDate;
  final DateTime endDate;
  final String selectedPreset;

  ClosuresFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? selectedPreset,
  }) {
    return ClosuresFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedPreset: selectedPreset ?? this.selectedPreset,
    );
  }
}

class ClosuresFilterNotifier extends Notifier<ClosuresFilterState> {
  @override
  ClosuresFilterState build() {
    final today = ref.watch(tenantTodayProvider);
    // Default: "A partire da oggi" - from today to far future
    return ClosuresFilterState(
      startDate: today,
      endDate: DateTime(today.year + 10, 12, 31),
      selectedPreset: 'from_today',
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      selectedPreset: 'custom',
    );
  }

  void applyPreset(String preset) {
    final now = ref.read(tenantNowProvider);
    final today = ref.read(tenantTodayProvider);

    DateTime startDate;
    DateTime endDate;

    switch (preset) {
      case 'from_today':
        startDate = today;
        endDate = DateTime(today.year + 10, 12, 31); // Far future
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      case 'last_year':
        startDate = DateTime(now.year - 1, 1, 1);
        endDate = DateTime(now.year - 1, 12, 31);
        break;
      case 'all':
        startDate = DateTime(2000, 1, 1); // Far past
        endDate = DateTime(today.year + 10, 12, 31); // Far future
        break;
      case 'custom':
      default:
        // Keep current dates for custom
        return;
    }

    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      selectedPreset: preset,
    );
  }
}

final closuresFilterProvider =
    NotifierProvider<ClosuresFilterNotifier, ClosuresFilterState>(
      ClosuresFilterNotifier.new,
    );
