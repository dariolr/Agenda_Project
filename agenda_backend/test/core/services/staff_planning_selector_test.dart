import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/services/staff_planning_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StaffPlanningSelector selector;

  setUp(() {
    selector = StaffPlanningSelector();
  });

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

  group('StaffPlanningSelector - findPlanningForDate', () {
    test('nessun planning per lo staff → NoPlanningFound', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 99, // Altro staff
          validFrom: DateTime(2026, 1, 1),
        ),
      ];

      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 1, 15),
        allPlannings: plannings,
      );

      expect(result, isA<NoPlanningFound>());
    });

    test('data prima di validFrom → NoPlanningFound', () {
      final plannings = [
        createPlanning(staffId: 10, validFrom: DateTime(2026, 6, 1)),
      ];

      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 5, 15), // Prima di validFrom
        allPlannings: plannings,
      );

      expect(result, isA<NoPlanningFound>());
    });

    test('data dopo validTo → NoPlanningFound', () {
      final plannings = [
        createPlanning(
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 31),
        ),
      ];

      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 2, 15), // Dopo validTo
        allPlannings: plannings,
      );

      expect(result, isA<NoPlanningFound>());
    });

    test('data dentro intervallo → PlanningFound', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 12, 31),
        ),
      ];

      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 6, 15),
        allPlannings: plannings,
      );

      expect(result, isA<PlanningFound>());
      final found = result as PlanningFound;
      expect(found.planning.id, 1);
      expect(found.weekLabel, WeekLabel.a); // weekly → sempre A
    });

    test('data su estremi intervallo (inclusi) → PlanningFound', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 31),
        ),
      ];

      // validFrom (estremo sinistro)
      var result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 1, 1),
        allPlannings: plannings,
      );
      expect(result, isA<PlanningFound>());

      // validTo (estremo destro)
      result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 1, 31),
        allPlannings: plannings,
      );
      expect(result, isA<PlanningFound>());
    });

    test('planning open-ended → PlanningFound per date future', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: null, // Open-ended
        ),
      ];

      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2030, 12, 31), // Molto nel futuro
        allPlannings: plannings,
      );

      expect(result, isA<PlanningFound>());
    });

    test('planning validi multipli (errore dati) → MultiplePlanningsFound', () {
      // Simuliamo un errore nei dati: due planning sovrapposti
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 6, 30),
        ),
        createPlanning(
          id: 2,
          staffId: 10,
          validFrom: DateTime(2026, 3, 1), // Si sovrappone!
          validTo: DateTime(2026, 12, 31),
        ),
      ];

      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 4, 15), // Dentro entrambi
        allPlannings: plannings,
      );

      expect(result, isA<MultiplePlanningsFound>());
      final multi = result as MultiplePlanningsFound;
      expect(multi.plannings.length, 2);
    });

    test(
      'planning contigui (non sovrapposti) → planning corretto per ciascuna data',
      () {
        final plannings = [
          createPlanning(
            id: 1,
            staffId: 10,
            validFrom: DateTime(2026, 1, 1),
            validTo: DateTime(2026, 1, 31),
          ),
          createPlanning(
            id: 2,
            staffId: 10,
            validFrom: DateTime(2026, 2, 1), // Giorno dopo
            validTo: DateTime(2026, 2, 28),
          ),
        ];

        // Data in gennaio → planning 1
        var result = selector.findPlanningForDate(
          staffId: 10,
          date: DateTime(2026, 1, 15),
          allPlannings: plannings,
        );
        expect(result, isA<PlanningFound>());
        expect((result as PlanningFound).planning.id, 1);

        // Data in febbraio → planning 2
        result = selector.findPlanningForDate(
          staffId: 10,
          date: DateTime(2026, 2, 15),
          allPlannings: plannings,
        );
        expect(result, isA<PlanningFound>());
        expect((result as PlanningFound).planning.id, 2);
      },
    );
  });

  group('StaffPlanningSelector - biweekly A/B', () {
    test('biweekly: settimana A', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.biweekly,
          validFrom: DateTime(2026, 1, 5), // Lunedì
          templateASlots: {
            1: {36, 37},
          }, // Lun settimana A
          templateBSlots: {
            1: {40, 41},
          }, // Lun settimana B
        ),
      ];

      // Giorno 0-6 → settimana A
      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 1, 5), // Giorno 0
        allPlannings: plannings,
      );

      expect(result, isA<PlanningFound>());
      final found = result as PlanningFound;
      expect(found.weekLabel, WeekLabel.a);
      expect(found.template.weekLabel, WeekLabel.a);
    });

    test('biweekly: settimana B', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.biweekly,
          validFrom: DateTime(2026, 1, 5), // Lunedì
          templateASlots: {
            1: {36, 37},
          },
          templateBSlots: {
            1: {40, 41},
          },
        ),
      ];

      // Giorno 7+ → settimana B
      final result = selector.findPlanningForDate(
        staffId: 10,
        date: DateTime(2026, 1, 12), // Giorno 7 (lunedì successivo)
        allPlannings: plannings,
      );

      expect(result, isA<PlanningFound>());
      final found = result as PlanningFound;
      expect(found.weekLabel, WeekLabel.b);
      expect(found.template.weekLabel, WeekLabel.b);
    });

    test('biweekly: alternanza A/B corretta', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.biweekly,
          validFrom: DateTime(2026, 1, 5), // Lunedì
        ),
      ];

      // Verifica alternanza su 4 settimane
      final expectations = [
        (DateTime(2026, 1, 5), WeekLabel.a), // Settimana 0
        (DateTime(2026, 1, 12), WeekLabel.b), // Settimana 1
        (DateTime(2026, 1, 19), WeekLabel.a), // Settimana 2
        (DateTime(2026, 1, 26), WeekLabel.b), // Settimana 3
      ];

      for (final (date, expectedLabel) in expectations) {
        final result = selector.findPlanningForDate(
          staffId: 10,
          date: date,
          allPlannings: plannings,
        );
        expect(result, isA<PlanningFound>());
        expect(
          (result as PlanningFound).weekLabel,
          expectedLabel,
          reason: 'Data $date dovrebbe essere settimana ${expectedLabel.name}',
        );
      }
    });
  });

  group('StaffPlanningSelector - getSlotsForDate', () {
    test('ritorna slot del template corretto per il giorno', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          templateASlots: {
            1: {36, 37, 38, 39}, // Lunedì
            2: {40, 41}, // Martedì
          },
        ),
      ];

      // Lunedì 5 gennaio 2026 (weekday = 1)
      var slots = selector.getSlotsForDate(
        staffId: 10,
        date: DateTime(2026, 1, 5),
        allPlannings: plannings,
      );
      expect(slots, {36, 37, 38, 39});

      // Martedì 6 gennaio 2026 (weekday = 2)
      slots = selector.getSlotsForDate(
        staffId: 10,
        date: DateTime(2026, 1, 6),
        allPlannings: plannings,
      );
      expect(slots, {40, 41});

      // Mercoledì 7 gennaio 2026 (weekday = 3, non presente)
      slots = selector.getSlotsForDate(
        staffId: 10,
        date: DateTime(2026, 1, 7),
        allPlannings: plannings,
      );
      expect(slots, isEmpty);
    });

    test('ritorna set vuoto se nessun planning', () {
      final slots = selector.getSlotsForDate(
        staffId: 10,
        date: DateTime(2026, 1, 15),
        allPlannings: [],
      );

      expect(slots, isEmpty);
    });

    test('ritorna null se planning multipli (errore)', () {
      // Dati errati: planning sovrapposti
      final plannings = [
        createPlanning(id: 1, staffId: 10, validFrom: DateTime(2026, 1, 1)),
        createPlanning(id: 2, staffId: 10, validFrom: DateTime(2026, 1, 1)),
      ];

      final slots = selector.getSlotsForDate(
        staffId: 10,
        date: DateTime(2026, 1, 15),
        allPlannings: plannings,
      );

      expect(slots, isNull);
    });
  });

  group('StaffPlanningSelector - isStaffAvailable', () {
    test('ritorna true se ha slot', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          templateASlots: {
            1: {36, 37},
          }, // Solo lunedì
        ),
      ];

      // Lunedì → ha slot
      expect(
        selector.isStaffAvailable(
          staffId: 10,
          date: DateTime(2026, 1, 5), // Lunedì
          allPlannings: plannings,
        ),
        isTrue,
      );

      // Martedì → nessuno slot
      expect(
        selector.isStaffAvailable(
          staffId: 10,
          date: DateTime(2026, 1, 6), // Martedì
          allPlannings: plannings,
        ),
        isFalse,
      );
    });

    test('ritorna false se nessun planning', () {
      expect(
        selector.isStaffAvailable(
          staffId: 10,
          date: DateTime(2026, 1, 15),
          allPlannings: [],
        ),
        isFalse,
      );
    });
  });

  group('StaffPlanningSelector - findPlanningsForRange', () {
    test('ritorna risultato per ogni giorno nel range', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 5),
          validTo: DateTime(2026, 1, 10),
        ),
      ];

      final results = selector.findPlanningsForRange(
        staffId: 10,
        startDate: DateTime(2026, 1, 3),
        endDate: DateTime(2026, 1, 12),
        allPlannings: plannings,
      );

      // 10 giorni
      expect(results.length, 10);

      // 3-4 gennaio → NoPlanningFound
      expect(results[DateTime(2026, 1, 3)], isA<NoPlanningFound>());
      expect(results[DateTime(2026, 1, 4)], isA<NoPlanningFound>());

      // 5-10 gennaio → PlanningFound
      expect(results[DateTime(2026, 1, 5)], isA<PlanningFound>());
      expect(results[DateTime(2026, 1, 10)], isA<PlanningFound>());

      // 11-12 gennaio → NoPlanningFound
      expect(results[DateTime(2026, 1, 11)], isA<NoPlanningFound>());
      expect(results[DateTime(2026, 1, 12)], isA<NoPlanningFound>());
    });
  });

  group('StaffPlanningSelector - findNextPlanning', () {
    test('trova il prossimo planning futuro', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 31),
        ),
        createPlanning(
          id: 2,
          staffId: 10,
          validFrom: DateTime(2026, 3, 1),
          validTo: DateTime(2026, 3, 31),
        ),
        createPlanning(
          id: 3,
          staffId: 10,
          validFrom: DateTime(2026, 6, 1),
          validTo: DateTime(2026, 6, 30),
        ),
      ];

      // Dopo gennaio → planning marzo
      var next = selector.findNextPlanning(
        staffId: 10,
        afterDate: DateTime(2026, 2, 1),
        allPlannings: plannings,
      );
      expect(next, isNotNull);
      expect(next!.id, 2);

      // Dopo marzo → planning giugno
      next = selector.findNextPlanning(
        staffId: 10,
        afterDate: DateTime(2026, 4, 1),
        allPlannings: plannings,
      );
      expect(next, isNotNull);
      expect(next!.id, 3);

      // Dopo giugno → nessun planning
      next = selector.findNextPlanning(
        staffId: 10,
        afterDate: DateTime(2026, 7, 1),
        allPlannings: plannings,
      );
      expect(next, isNull);
    });

    test('ritorna null se non ci sono planning futuri', () {
      final plannings = [
        createPlanning(
          id: 1,
          staffId: 10,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 31),
        ),
      ];

      final next = selector.findNextPlanning(
        staffId: 10,
        afterDate: DateTime(2026, 2, 1),
        allPlannings: plannings,
      );

      expect(next, isNull);
    });
  });
}
