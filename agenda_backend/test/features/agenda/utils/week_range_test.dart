import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    initializeDateFormatting('it');
  });

  test(
    'computeWeekRange normalizes to Monday through Sunday in tenant timezone',
    () {
      final range = computeWeekRange(
        DateTime(2026, 3, 4, 15, 30),
        'Europe/Rome',
        localeTag: 'it',
      );

      expect(range.start, DateTime(2026, 3, 2));
      expect(range.end, DateTime(2026, 3, 8, 23, 59, 59, 999));
      expect(range.days, hasLength(7));
      expect(range.days.first, DateTime(2026, 3, 2));
      expect(range.days.last, DateTime(2026, 3, 8));
    },
  );
}
