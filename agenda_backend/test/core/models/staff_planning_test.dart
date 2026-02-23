import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_backend/core/models/staff_planning.dart';

void main() {
  group('StaffPlanning', () {
    group('isValidForDate', () {
      test(
        'ritorna true se la data è dentro l\'intervallo [validFrom, validTo]',
        () {
          final planning = StaffPlanning(
            id: 1,
            staffId: 10,
            type: StaffPlanningType.weekly,
            validFrom: DateTime(2026, 1, 1),
            validTo: DateTime(2026, 1, 31),
            templates: const [],
            createdAt: DateTime.now(),
          );

          // Estremi inclusi
          expect(planning.isValidForDate(DateTime(2026, 1, 1)), isTrue);
          expect(planning.isValidForDate(DateTime(2026, 1, 31)), isTrue);
          // Interno
          expect(planning.isValidForDate(DateTime(2026, 1, 15)), isTrue);
          // Esterno
          expect(planning.isValidForDate(DateTime(2025, 12, 31)), isFalse);
          expect(planning.isValidForDate(DateTime(2026, 2, 1)), isFalse);
        },
      );

      test('ritorna true per date future se validTo è null', () {
        final planning = StaffPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.weekly,
          validFrom: DateTime(2026, 1, 1),
          validTo: null, // Open-ended
          templates: const [],
          createdAt: DateTime.now(),
        );

        expect(planning.isValidForDate(DateTime(2026, 1, 1)), isTrue);
        expect(planning.isValidForDate(DateTime(2030, 12, 31)), isTrue);
        expect(planning.isValidForDate(DateTime(2025, 12, 31)), isFalse);
      });
    });

    group('computeWeekLabel (biweekly A/B)', () {
      test('per weekly ritorna sempre A', () {
        final planning = StaffPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.weekly,
          validFrom: DateTime(2026, 1, 1),
          templates: const [],
          createdAt: DateTime.now(),
        );

        expect(planning.computeWeekLabel(DateTime(2026, 1, 1)), WeekLabel.a);
        expect(planning.computeWeekLabel(DateTime(2026, 1, 8)), WeekLabel.a);
        expect(planning.computeWeekLabel(DateTime(2026, 2, 15)), WeekLabel.a);
      });

      test('per biweekly alterna A/B ogni 7 giorni', () {
        final planning = StaffPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.biweekly,
          validFrom: DateTime(2026, 1, 6), // Lunedì 6 gennaio 2026
          templates: const [],
          createdAt: DateTime.now(),
        );

        // Settimana 0 (giorni 0-6) → week_index 0 → pari → A
        expect(planning.computeWeekLabel(DateTime(2026, 1, 6)), WeekLabel.a);
        expect(planning.computeWeekLabel(DateTime(2026, 1, 12)), WeekLabel.a);

        // Settimana 1 (giorni 7-13) → week_index 1 → dispari → B
        expect(planning.computeWeekLabel(DateTime(2026, 1, 13)), WeekLabel.b);
        expect(planning.computeWeekLabel(DateTime(2026, 1, 19)), WeekLabel.b);

        // Settimana 2 (giorni 14-20) → week_index 2 → pari → A
        expect(planning.computeWeekLabel(DateTime(2026, 1, 20)), WeekLabel.a);
        expect(planning.computeWeekLabel(DateTime(2026, 1, 26)), WeekLabel.a);

        // Settimana 3 (giorni 21-27) → week_index 3 → dispari → B
        expect(planning.computeWeekLabel(DateTime(2026, 1, 27)), WeekLabel.b);
      });
    });

    group('fromJson / toJson', () {
      test('deserializza e serializza correttamente', () {
        final json = {
          'id': 1,
          'staff_id': 10,
          'type': 'weekly',
          'valid_from': '2026-01-01',
          'valid_to': '2026-12-31',
          'templates': [
            {
              'id': 100,
              'staff_planning_id': 1,
              'week_label': 'A',
              'day_slots': [
                {
                  'day_of_week': 1,
                  'slots': [36, 37, 38, 39],
                },
                {
                  'day_of_week': 2,
                  'slots': [36, 37, 38, 39],
                },
              ],
            },
          ],
          'created_at': '2026-01-01T00:00:00.000',
        };

        final planning = StaffPlanning.fromJson(json);

        expect(planning.id, 1);
        expect(planning.staffId, 10);
        expect(planning.type, StaffPlanningType.weekly);
        expect(planning.validFrom, DateTime(2026, 1, 1));
        expect(planning.validTo, DateTime(2026, 12, 31));
        expect(planning.templates.length, 1);

        final template = planning.templateA;
        expect(template, isNotNull);
        expect(template!.weekLabel, WeekLabel.a);
        expect(template.getSlotsForDay(1), {36, 37, 38, 39});
        expect(template.getSlotsForDay(2), {36, 37, 38, 39});
        expect(template.getSlotsForDay(3), isEmpty);

        // Round-trip
        final jsonBack = planning.toJson();
        expect(jsonBack['id'], 1);
        expect(jsonBack['staff_id'], 10);
        expect(jsonBack['type'], 'weekly');
        expect(jsonBack['valid_from'], '2026-01-01');
        expect(jsonBack['valid_to'], '2026-12-31');
      });

      test('gestisce validTo null', () {
        final json = {
          'id': 2,
          'staff_id': 20,
          'type': 'biweekly',
          'valid_from': '2026-06-01',
          'valid_to': null,
          'templates': [],
          'created_at': '2026-06-01T00:00:00.000',
        };

        final planning = StaffPlanning.fromJson(json);
        expect(planning.isOpenEnded, isTrue);
        expect(planning.validTo, isNull);

        final jsonBack = planning.toJson();
        expect(jsonBack['valid_to'], isNull);
      });
    });
  });

  group('StaffPlanningWeekTemplate', () {
    test('getSlotsForDay ritorna set vuoto per giorni non configurati', () {
      final template = StaffPlanningWeekTemplate(
        id: 1,
        staffPlanningId: 1,
        weekLabel: WeekLabel.a,
        daySlots: {
          1: {36, 37, 38}, // Lunedì
        },
      );

      expect(template.getSlotsForDay(1), {36, 37, 38});
      expect(template.getSlotsForDay(2), isEmpty);
      expect(template.getSlotsForDay(7), isEmpty);
    });

    test('hasSlots identifica correttamente giorni con/senza slot', () {
      final template = StaffPlanningWeekTemplate(
        id: 1,
        staffPlanningId: 1,
        weekLabel: WeekLabel.a,
        daySlots: {
          1: {36, 37}, // Lunedì: lavora
          2: {}, // Martedì: set vuoto
          // Mercoledì: non presente
        },
      );

      expect(template.hasSlots(1), isTrue);
      expect(template.hasSlots(2), isFalse);
      expect(template.hasSlots(3), isFalse);
    });

    test('totalWeeklyHours calcola correttamente', () {
      final template = StaffPlanningWeekTemplate(
        id: 1,
        staffPlanningId: 1,
        weekLabel: WeekLabel.a,
        daySlots: {
          1: {0, 1, 2, 3, 4, 5, 6, 7}, // 8 slot = 2 ore
          2: {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, // 12 slot = 3 ore
        },
      );

      // 20 slot * 5 min / 60 = 1h40m
      expect(template.totalWeeklyHours, closeTo(1.6667, 0.0001));
    });

    group('fromJson formati diversi', () {
      test('formato lista day_slots', () {
        final json = {
          'id': 1,
          'staff_planning_id': 1,
          'week_label': 'B',
          'day_slots': [
            {
              'day_of_week': 5,
              'slots': [40, 41, 42],
            },
          ],
        };

        final template = StaffPlanningWeekTemplate.fromJson(json);
        expect(template.weekLabel, WeekLabel.b);
        expect(template.getSlotsForDay(5), {40, 41, 42});
      });

      test('formato mappa slots', () {
        final json = {
          'id': 2,
          'staff_planning_id': 1,
          'week_label': 'A',
          'slots': {
            '1': [10, 11, 12],
            '2': [20, 21],
          },
        };

        final template = StaffPlanningWeekTemplate.fromJson(json);
        expect(template.getSlotsForDay(1), {10, 11, 12});
        expect(template.getSlotsForDay(2), {20, 21});
      });
    });
  });
}
