import 'dart:ui';

import 'package:agenda_backend/features/agenda/providers/staff_columns_geometry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffColumnsGeometryNotifier', () {
    late ProviderContainer container;
    late StaffColumnsGeometryNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(staffColumnsGeometryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('setRect stores geometry per staff id', () {
      final rect = Rect.fromLTWH(10, 20, 100, 200);
      notifier.setRect(1, rect);

      final state = container.read(staffColumnsGeometryProvider);
      expect(state[1], rect);
    });

    test('clearFor removes the specified staff geometry', () {
      notifier.setRect(1, Rect.zero);
      notifier.setRect(2, Rect.fromLTWH(0, 0, 50, 50));

      notifier.clearFor(1);
      final state = container.read(staffColumnsGeometryProvider);

      expect(state.containsKey(1), isFalse);
      expect(state.containsKey(2), isTrue);
    });

    test('clearAll resets the geometry cache', () {
      notifier.setRect(1, Rect.zero);
      notifier.setRect(2, Rect.zero);

      notifier.clearAll();
      expect(container.read(staffColumnsGeometryProvider), isEmpty);
    });
  });
}
