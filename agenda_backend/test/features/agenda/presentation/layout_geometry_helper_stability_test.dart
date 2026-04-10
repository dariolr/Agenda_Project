import 'package:agenda_backend/features/agenda/presentation/screens/helper/layout_geometry_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'computeLayoutGeometry keeps stable columns for overlapping cards with same start during resize',
    () {
      final start = DateTime(2026, 4, 10, 9, 0);

      final before = computeLayoutGeometry([
        LayoutEntry(id: 10, start: start, end: DateTime(2026, 4, 10, 10, 0)),
        LayoutEntry(id: 20, start: start, end: DateTime(2026, 4, 10, 11, 0)),
      ]);

      final after = computeLayoutGeometry([
        LayoutEntry(id: 10, start: start, end: DateTime(2026, 4, 10, 11, 30)),
        LayoutEntry(id: 20, start: start, end: DateTime(2026, 4, 10, 11, 0)),
      ]);

      expect(before[10]?.leftFraction, 0);
      expect(before[20]?.leftFraction, 0.5);
      expect(after[10]?.leftFraction, 0);
      expect(after[20]?.leftFraction, 0.5);
    },
  );
}
