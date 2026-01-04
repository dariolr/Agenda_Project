import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/services/staff_planning_selector.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  /// Helper per creare un planning.
  StaffPlanning createPlanning({
    int id = 1,
    int staffId = 10,
    StaffPlanningType type = StaffPlanningType.weekly,
    required DateTime validFrom,
    DateTime? validTo,
    Map<int, Set<int>>? templateASlots,
    Map<int, Set<int>>? templateBSlots,
  }) {
    final templates = <StaffPlanningWeekTemplate>[];

    templates.add(
      StaffPlanningWeekTemplate(
        id: id * 100,
        staffPlanningId: id,
        weekLabel: WeekLabel.a,
        daySlots:
            templateASlots ??
            {
              1: {36, 37, 38, 39}, // Lun 09:00-10:00
              2: {36, 37, 38, 39}, // Mar
              3: {36, 37, 38, 39}, // Mer
              4: {36, 37, 38, 39}, // Gio
              5: {36, 37, 38, 39}, // Ven
            },
      ),
    );

    if (type == StaffPlanningType.biweekly) {
      templates.add(
        StaffPlanningWeekTemplate(
          id: id * 100 + 1,
          staffPlanningId: id,
          weekLabel: WeekLabel.b,
          daySlots:
              templateBSlots ??
              {
                1: {40, 41, 42, 43}, // Lun 10:00-11:00
                3: {40, 41, 42, 43}, // Mer
                5: {40, 41, 42, 43}, // Ven
              },
        ),
      );
    }

    return StaffPlanning(
      id: id,
      staffId: staffId,
      type: type,
      validFrom: validFrom,
      validTo: validTo,
      templates: templates,
      createdAt: DateTime.now(),
    );
  }

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('StaffPlanningsNotifier', () {
    test('inizializza con stato vuoto', () {
      final plannings = container.read(staffPlanningsProvider);

      expect(plannings, isA<StaffPlanningsState>());
      expect(plannings, isEmpty);
    });

    test('setPlanningsForStaff imposta i planning correttamente', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
      );

      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      final state = container.read(staffPlanningsProvider);
      expect(state[10]?.length, 1);
      expect(state[10]?.first.id, 1);
    });

    test('setPlanningsForStaff con multipli planning', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final plannings = [
        createPlanning(id: 1, staffId: 10, validFrom: DateTime(2026, 1, 1)),
        createPlanning(id: 2, staffId: 10, validFrom: DateTime(2026, 7, 1)),
      ];

      notifier.setPlanningsForStaff(10, plannings);

      final state = container.read(staffPlanningsProvider);
      expect(state[10]?.length, 2);
    });

    test('setPlanningsForStaff con lista vuota rimuove i planning', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      // Verifica aggiunto
      var state = container.read(staffPlanningsProvider);
      expect(state[10]?.length, 1);

      // Rimuovi passando lista vuota
      notifier.setPlanningsForStaff(10, []);

      // Verifica rimosso
      state = container.read(staffPlanningsProvider);
      expect(state[10], isEmpty);
    });
  });

  group('StaffPlanningValidator', () {
    test('valida planning biweekly senza template B', () {
      // Planning biweekly senza template B
      final planning = StaffPlanning(
        id: 1,
        staffId: 10,
        type: StaffPlanningType.biweekly,
        validFrom: DateTime(2026, 1, 1),
        templates: [
          StaffPlanningWeekTemplate(
            id: 100,
            staffPlanningId: 1,
            weekLabel: WeekLabel.a,
            daySlots: {
              1: {36, 37},
            },
          ),
          // Manca template B!
        ],
        createdAt: DateTime.now(),
      );

      final validator = container.read(staffPlanningValidatorProvider);
      final result = validator.validateForCreate(planning, []);

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains('Template B è obbligatorio per pianificazione biweekly'),
      );
    });

    test('rileva overlap tra planning', () {
      // Primo planning
      final planning1 = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
        validTo: DateTime(2026, 6, 30),
      );

      // Secondo planning che si sovrappone
      final planning2 = createPlanning(
        id: 2,
        staffId: 10,
        validFrom: DateTime(2026, 3, 1), // Overlap!
        validTo: DateTime(2026, 12, 31),
      );

      final validator = container.read(staffPlanningValidatorProvider);
      final result = validator.validateForCreate(planning2, [planning1]);

      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Sovrapposizione'));
    });

    test('valida planning weekly valido', () {
      final planning = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
      );

      final validator = container.read(staffPlanningValidatorProvider);
      final result = validator.validateForCreate(planning, []);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });

  group('planningForStaffOnDateProvider', () {
    test('ritorna NoPlanningFound se nessun planning', () {
      final result = container.read(
        planningForStaffOnDateProvider((
          staffId: 10,
          date: DateTime(2026, 1, 15),
        )),
      );

      expect(result, isA<NoPlanningFound>());
    });

    test('ritorna PlanningFound per data valida', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
        validTo: DateTime(2026, 12, 31),
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      final result = container.read(
        planningForStaffOnDateProvider((
          staffId: 10,
          date: DateTime(2026, 6, 15),
        )),
      );

      expect(result, isA<PlanningFound>());
      expect((result as PlanningFound).planning.id, 1);
    });

    test('ritorna week label A per weekly', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        type: StaffPlanningType.weekly,
        validFrom: DateTime(2026, 1, 1),
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      final result = container.read(
        planningForStaffOnDateProvider((
          staffId: 10,
          date: DateTime(2026, 6, 15),
        )),
      );

      expect(result, isA<PlanningFound>());
      expect((result as PlanningFound).weekLabel, WeekLabel.a);
    });

    test('ritorna week label corretta per biweekly', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        type: StaffPlanningType.biweekly,
        validFrom: DateTime(2026, 1, 5), // Lunedì
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      // Settimana 0 (A)
      final resultA = container.read(
        planningForStaffOnDateProvider((
          staffId: 10,
          date: DateTime(2026, 1, 5),
        )),
      );
      expect(resultA, isA<PlanningFound>());
      expect((resultA as PlanningFound).weekLabel, WeekLabel.a);

      // Settimana 1 (B)
      final resultB = container.read(
        planningForStaffOnDateProvider((
          staffId: 10,
          date: DateTime(2026, 1, 12),
        )),
      );
      expect(resultB, isA<PlanningFound>());
      expect((resultB as PlanningFound).weekLabel, WeekLabel.b);
    });
  });

  group('planningSlotsForDateProvider', () {
    test('ritorna slot del template corretto', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
        templateASlots: {
          1: {36, 37, 38, 39}, // Lunedì
          2: {40, 41}, // Martedì
        },
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      // Lunedì 5 gennaio 2026
      var slots = container.read(
        planningSlotsForDateProvider((staffId: 10, date: DateTime(2026, 1, 5))),
      );
      expect(slots, {36, 37, 38, 39});

      // Martedì 6 gennaio 2026
      slots = container.read(
        planningSlotsForDateProvider((staffId: 10, date: DateTime(2026, 1, 6))),
      );
      expect(slots, {40, 41});
    });

    test('ritorna slot del template B in settimana B per biweekly', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        type: StaffPlanningType.biweekly,
        validFrom: DateTime(2026, 1, 5), // Lunedì
        templateASlots: {
          1: {36, 37},
        }, // Lun settimana A
        templateBSlots: {
          1: {50, 51},
        }, // Lun settimana B
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      // Lunedì settimana A (5 gennaio)
      var slots = container.read(
        planningSlotsForDateProvider((staffId: 10, date: DateTime(2026, 1, 5))),
      );
      expect(slots, {36, 37});

      // Lunedì settimana B (12 gennaio)
      slots = container.read(
        planningSlotsForDateProvider((
          staffId: 10,
          date: DateTime(2026, 1, 12),
        )),
      );
      expect(slots, {50, 51});
    });
  });

  group('isStaffAvailableOnDateProvider', () {
    test('ritorna true se ha slot', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        validFrom: DateTime(2026, 1, 1),
        templateASlots: {
          1: {36, 37},
        }, // Solo lunedì
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      // Lunedì → disponibile
      expect(
        container.read(
          isStaffAvailableOnDateProvider((
            staffId: 10,
            date: DateTime(2026, 1, 5), // Lunedì
          )),
        ),
        isTrue,
      );

      // Martedì → non disponibile
      expect(
        container.read(
          isStaffAvailableOnDateProvider((
            staffId: 10,
            date: DateTime(2026, 1, 6), // Martedì
          )),
        ),
        isFalse,
      );
    });
  });

  group('weekLabelForDateProvider', () {
    test('ritorna null per weekly', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        type: StaffPlanningType.weekly,
        validFrom: DateTime(2026, 1, 1),
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      final label = container.read(
        weekLabelForDateProvider((staffId: 10, date: DateTime(2026, 1, 15))),
      );

      expect(label, isNull);
    });

    test('ritorna week label per biweekly', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      final planning = createPlanning(
        id: 1,
        staffId: 10,
        type: StaffPlanningType.biweekly,
        validFrom: DateTime(2026, 1, 5),
      );
      notifier.setPlanningsForStaff(planning.staffId, [planning]);

      // Settimana A
      var label = container.read(
        weekLabelForDateProvider((staffId: 10, date: DateTime(2026, 1, 5))),
      );
      expect(label, WeekLabel.a);

      // Settimana B
      label = container.read(
        weekLabelForDateProvider((staffId: 10, date: DateTime(2026, 1, 12))),
      );
      expect(label, WeekLabel.b);
    });
  });

  group('planningsForStaffProvider', () {
    test('ritorna lista vuota se nessun planning', () {
      final plannings = container.read(planningsForStaffProvider(10));
      expect(plannings, isEmpty);
    });

    test('ritorna planning per lo staff', () {
      final notifier = container.read(staffPlanningsProvider.notifier);

      notifier.setPlanningsForStaff(10, [
        createPlanning(id: 1, staffId: 10, validFrom: DateTime(2026, 1, 1)),
        createPlanning(id: 2, staffId: 10, validFrom: DateTime(2026, 7, 1)),
      ]);

      notifier.setPlanningsForStaff(20, [
        createPlanning(id: 3, staffId: 20, validFrom: DateTime(2026, 1, 1)),
      ]);

      final plannings10 = container.read(planningsForStaffProvider(10));
      expect(plannings10.length, 2);

      final plannings20 = container.read(planningsForStaffProvider(20));
      expect(plannings20.length, 1);
    });
  });
}
