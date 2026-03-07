import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CalendarViewMode { day, week }

class CalendarViewModeNotifier extends Notifier<CalendarViewMode> {
  @override
  CalendarViewMode build() => CalendarViewMode.day;

  void setMode(CalendarViewMode mode) {
    if (state == mode) return;
    state = mode;
  }
}

final calendarViewModeProvider =
    NotifierProvider<CalendarViewModeNotifier, CalendarViewMode>(
      CalendarViewModeNotifier.new,
    );
