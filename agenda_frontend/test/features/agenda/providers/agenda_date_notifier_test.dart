import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgendaDateNotifier month shifting', () {
    test('Preserves day when target month has that day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2025, 3, 15));
      notifier.nextMonth();
      expect(container.read(agendaDateProvider), DateTime(2025, 4, 15));
    });

    test('Clamps from 31 Jan to 28 Feb non-leap year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2025, 1, 31)); // 2025 not leap year
      notifier.nextMonth();
      expect(container.read(agendaDateProvider), DateTime(2025, 2, 28));
    });

    test('Clamps from 31 Jan to 29 Feb leap year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2024, 1, 31)); // 2024 leap year
      notifier.nextMonth();
      expect(container.read(agendaDateProvider), DateTime(2024, 2, 29));
    });

    test('Clamps from 31 Mar to 30 Apr', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2025, 3, 31));
      notifier.nextMonth();
      expect(container.read(agendaDateProvider), DateTime(2025, 4, 30));
    });

    test('Year boundary forward (Dec -> Jan)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2025, 12, 15));
      notifier.nextMonth();
      expect(container.read(agendaDateProvider), DateTime(2026, 1, 15));
    });

    test('Year boundary backward (Jan -> Dec prev year)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2025, 1, 10));
      notifier.previousMonth();
      expect(container.read(agendaDateProvider), DateTime(2024, 12, 10));
    });

    test('Round trip with clamping (Aug 31 -> Sep 30 -> Aug 30)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(agendaDateProvider.notifier);
      notifier.set(DateTime(2025, 8, 31));
      notifier.nextMonth();
      expect(container.read(agendaDateProvider), DateTime(2025, 9, 30));
      notifier.previousMonth();
      // We expect Aug 30 because original 31 was clamped; reversal preserves feasible day.
      expect(container.read(agendaDateProvider), DateTime(2025, 8, 30));
    });
  });
}
