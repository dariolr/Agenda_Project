import 'package:agenda_backend/features/agenda/providers/temp_drag_time_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TempDragTimeNotifier', () {
    late ProviderContainer container;
    late TempDragTimeNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(tempDragTimeProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('setTimes updates only when the slot boundary changes', () {
      final firstStart = DateTime(2025, 1, 1, 10, 0);
      final firstEnd = firstStart.add(const Duration(minutes: 30));

      notifier.setTimes(firstStart, firstEnd);
      final firstState = container.read(tempDragTimeProvider);

      expect(firstState?.$1, firstStart);
      expect(firstState?.$2, firstEnd);

      // Same minute -> should not notify or replace the record.
      final sameMinuteStart = firstStart.add(const Duration(seconds: 30));
      final sameMinuteEnd = firstEnd.add(const Duration(seconds: 30));
      notifier.setTimes(sameMinuteStart, sameMinuteEnd);

      final afterSameMinute = container.read(tempDragTimeProvider);
      expect(identical(afterSameMinute, firstState), isTrue);

      // Next slot -> should replace the record.
      final secondStart = firstStart.add(const Duration(minutes: 45));
      final secondEnd = secondStart.add(const Duration(minutes: 30));
      notifier.setTimes(secondStart, secondEnd);

      final afterNextSlot = container.read(tempDragTimeProvider);
      expect(identical(afterNextSlot, firstState), isFalse);
      expect(afterNextSlot?.$1, secondStart);
      expect(afterNextSlot?.$2, secondEnd);
    });

    test('clear resets the drag preview state', () {
      final start = DateTime(2025, 1, 1, 9);
      final end = start.add(const Duration(minutes: 30));

      notifier.setTimes(start, end);
      notifier.clear();

      expect(container.read(tempDragTimeProvider), isNull);
    });
  });
}
