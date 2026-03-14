import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/features/agenda/providers/booking_reschedule_capability_provider.dart';
import 'package:agenda_backend/features/agenda/providers/calendar_view_mode_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Staff _staff(int id) => Staff(
  id: id,
  businessId: 1,
  name: 'Staff $id',
  surname: '',
  color: Colors.blue,
  locationIds: const [1],
);

class _FixedCalendarViewModeNotifier extends CalendarViewModeNotifier {
  _FixedCalendarViewModeNotifier(this._mode);

  final CalendarViewMode _mode;

  @override
  CalendarViewMode build() => _mode;
}

void main() {
  group('canUseBookingRescheduleProvider', () {
    test('in day view it is always enabled', () {
      final container = ProviderContainer(
        overrides: [
          calendarViewModeProvider.overrideWith(
            () => _FixedCalendarViewModeNotifier(CalendarViewMode.day),
          ),
          filteredStaffProvider.overrideWith((_) => [_staff(1), _staff(2)]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(canUseBookingRescheduleProvider), isTrue);
    });

    test('in week view it is enabled with single visible staff', () {
      final container = ProviderContainer(
        overrides: [
          calendarViewModeProvider.overrideWith(
            () => _FixedCalendarViewModeNotifier(CalendarViewMode.week),
          ),
          filteredStaffProvider.overrideWith((_) => [_staff(1)]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(canUseBookingRescheduleProvider), isTrue);
    });

    test('in week view it is disabled with multiple visible staff', () {
      final container = ProviderContainer(
        overrides: [
          calendarViewModeProvider.overrideWith(
            () => _FixedCalendarViewModeNotifier(CalendarViewMode.week),
          ),
          filteredStaffProvider.overrideWith((_) => [_staff(1), _staff(2)]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(canUseBookingRescheduleProvider), isFalse);
    });
  });
}
