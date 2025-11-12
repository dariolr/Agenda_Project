import 'package:agenda_frontend/features/staff/presentation/staff_availability_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsFlag;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a cell toggles its selected state (semantics)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: StaffAvailabilityScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final semanticsHandle = tester.ensureSemantics();

    // Find the first visible cell for Monday (day 1) at the first slot of the visible range
    final cellFinder = find.byKey(const Key('availability_cell_day_1_slot_32'));

    // If the computed key isn't found due to minutesPerSlot differences,
    // fallback to the first AvailabilityCell on screen.
    final target = cellFinder.evaluate().isNotEmpty
        ? cellFinder
        : find.byType(AvailabilityCell).first;

    // Read semantics before
    final beforeSemantics = tester.getSemantics(target);
    final wasSelected = beforeSemantics.hasFlag(SemanticsFlag.isSelected);

    // Tap to toggle
    await tester.tap(target);
    await tester.pumpAndSettle();

    final afterSemantics = tester.getSemantics(target);
    final isSelectedAfter = afterSemantics.hasFlag(SemanticsFlag.isSelected);

    expect(isSelectedAfter, isNot(wasSelected));

    semanticsHandle.dispose();
  });
}
