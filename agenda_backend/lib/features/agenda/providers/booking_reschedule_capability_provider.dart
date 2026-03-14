import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_view_mode_provider.dart';
import 'staff_filter_providers.dart';

/// La riprogrammazione è consentita sempre in vista giorno.
/// In vista settimana è consentita solo quando è visibile un singolo operatore.
final canUseBookingRescheduleProvider = Provider<bool>((ref) {
  final viewMode = ref.watch(calendarViewModeProvider);
  if (viewMode == CalendarViewMode.day) {
    return true;
  }

  final visibleStaff = ref.watch(filteredStaffProvider);
  return visibleStaff.length == 1;
});
