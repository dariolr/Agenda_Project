import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import 'business_providers.dart';
import 'location_providers.dart';

enum CalendarViewMode { day, week }

class CalendarViewModeNotifier extends Notifier<CalendarViewMode> {
  @override
  CalendarViewMode build() {
    final businessId = ref.watch(currentBusinessIdProvider);
    final locationId = ref.watch(currentLocationIdProvider);
    if (businessId <= 0 || locationId <= 0) {
      return CalendarViewMode.day;
    }

    final saved = ref.watch(preferencesServiceProvider).getAgendaViewMode(
      businessId,
      locationId: locationId,
    );
    if (saved == null) {
      return CalendarViewMode.day;
    }

    return CalendarViewMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => CalendarViewMode.day,
    );
  }

  void setMode(CalendarViewMode mode) {
    if (state == mode) return;
    state = mode;
    final businessId = ref.read(currentBusinessIdProvider);
    final locationId = ref.read(currentLocationIdProvider);
    if (businessId <= 0 || locationId <= 0) return;
    ref.read(preferencesServiceProvider).setAgendaViewMode(
      businessId,
      locationId: locationId,
      mode: mode.name,
    );
  }
}

final calendarViewModeProvider =
    NotifierProvider<CalendarViewModeNotifier, CalendarViewMode>(
      CalendarViewModeNotifier.new,
    );
