import 'package:agenda_backend/features/agenda/providers/resizing_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResizingNotifier', () {
    late ProviderContainer container;
    late ResizingNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(resizingProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('startResize initializes entry and marks resizing', () {
      final start = DateTime(2025, 1, 1, 9, 0);
      final end = start.add(const Duration(minutes: 30));

      notifier.startResize(
        appointmentId: 42,
        currentHeightPx: 60,
        startTime: start,
        endTime: end,
      );

      final state = container.read(resizingProvider);

      expect(state.isResizing, isTrue);
      expect(notifier.previewHeightFor(42), 60);
      expect(notifier.previewEndTimeFor(42), end);
    });

    test('updateDuringResize clamps height and snaps duration', () {
      final start = DateTime(2025, 1, 1, 9, 0);
      final end = start.add(const Duration(minutes: 45));

      notifier.startResize(
        appointmentId: 1,
        currentHeightPx: 90, // 45 minutes at 2 px/min
        startTime: start,
        endTime: end,
      );

      notifier.updateDuringResize(
        appointmentId: 1,
        deltaDy: -100,
        pixelsPerMinute: 2,
        dayEnd: start.add(const Duration(hours: 8)),
        minDurationMinutes: 30,
        snapMinutes: 15,
      );

      expect(notifier.previewHeightFor(1), 60); // min 30 minutes
      expect(
        notifier.previewEndTimeFor(1),
        start.add(const Duration(minutes: 30)),
      );

      notifier.updateDuringResize(
        appointmentId: 1,
        deltaDy: 100,
        pixelsPerMinute: 2,
        dayEnd: start.add(const Duration(hours: 2)),
        minDurationMinutes: 30,
        snapMinutes: 15,
      );

      expect(notifier.previewHeightFor(1), 160);
      expect(
        notifier.previewEndTimeFor(1),
        start.add(const Duration(minutes: 75)),
      );
    });

    test('commitResizeAndEnd returns final end time and clears entry', () {
      final start = DateTime(2025, 1, 1, 9, 0);
      final end = start.add(const Duration(minutes: 30));

      notifier.startResize(
        appointmentId: 7,
        currentHeightPx: 60,
        startTime: start,
        endTime: end,
      );

      notifier.updateDuringResize(
        appointmentId: 7,
        deltaDy: 90,
        pixelsPerMinute: 2,
        dayEnd: start.add(const Duration(hours: 3)),
        minDurationMinutes: 15,
        snapMinutes: 15,
      );

      final finalEnd = notifier.commitResizeAndEnd(appointmentId: 7);

      expect(finalEnd, start.add(const Duration(minutes: 75)));
      expect(container.read(resizingProvider).entries.containsKey(7), isFalse);
      expect(container.read(resizingProvider).isResizing, isFalse);
    });
  });
}
