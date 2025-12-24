import 'package:agenda_backend/features/agenda/providers/drag_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragSessionNotifier', () {
    late ProviderContainer container;
    late DragSessionNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(dragSessionProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('start creates a new session with incremental id', () {
      final firstId = notifier.start();
      expect(firstId, 1);
      expect(container.read(dragSessionProvider).dropHandled, isFalse);

      notifier.markHandled();
      expect(container.read(dragSessionProvider).dropHandled, isTrue);

      notifier.clear();
      expect(container.read(dragSessionProvider).id, isNull);

      final secondId = notifier.start();
      expect(secondId, 2);
    });

    test('markHandled is ignored when no session exists', () {
      notifier.markHandled();
      expect(container.read(dragSessionProvider).dropHandled, isFalse);
    });
  });
}
