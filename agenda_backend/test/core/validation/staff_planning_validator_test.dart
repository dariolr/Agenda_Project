import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/validation/staff_planning_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StaffPlanningValidator validator;

  setUp(() {
    validator = StaffPlanningValidator();
  });

  /// Helper per creare un planning con template validi.
  StaffPlanning createPlanning({
    int id = 1,
    int staffId = 10,
    StaffPlanningType type = StaffPlanningType.weekly,
    required DateTime validFrom,
    DateTime? validTo,
    bool withTemplateA = true,
    bool withTemplateB = false,
  }) {
    final templates = <StaffPlanningWeekTemplate>[];

    if (withTemplateA) {
      templates.add(
        StaffPlanningWeekTemplate(
          id: id * 100,
          staffPlanningId: id,
          weekLabel: WeekLabel.a,
          daySlots: {
            1: {36, 37, 38, 39}, // Lun 09:00-10:00
            2: {36, 37, 38, 39}, // Mar
            3: {36, 37, 38, 39}, // Mer
          },
        ),
      );
    }

    if (withTemplateB) {
      templates.add(
        StaffPlanningWeekTemplate(
          id: id * 100 + 1,
          staffPlanningId: id,
          weekLabel: WeekLabel.b,
          daySlots: {
            1: {40, 41, 42, 43}, // Lun 10:00-11:00
            4: {40, 41, 42, 43}, // Gio
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

  group('StaffPlanningValidator - validateForCreate', () {
    group('Regole base', () {
      test('valid_to < valid_from → errore', () {
        final planning = createPlanning(
          validFrom: DateTime(2026, 6, 1),
          validTo: DateTime(2026, 5, 1), // Prima di validFrom!
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isFalse);
        expect(
          result.errors,
          contains('valid_to non può essere precedente a valid_from'),
        );
      });

      test('valid_to = valid_from → valido (un solo giorno)', () {
        final planning = createPlanning(
          validFrom: DateTime(2026, 6, 1),
          validTo: DateTime(2026, 6, 1),
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isTrue);
      });

      test('valid_to null (open-ended) → valido', () {
        final planning = createPlanning(
          validFrom: DateTime(2026, 6, 1),
          validTo: null,
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isTrue);
      });
    });

    group('Validazione template', () {
      test('weekly senza template A → errore', () {
        final planning = createPlanning(
          validFrom: DateTime(2026, 1, 1),
          withTemplateA: false,
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Template A è obbligatorio'));
      });

      test('biweekly senza template B → errore', () {
        final planning = createPlanning(
          type: StaffPlanningType.biweekly,
          validFrom: DateTime(2026, 1, 1),
          withTemplateA: true,
          withTemplateB: false,
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isFalse);
        expect(
          result.errors,
          contains('Template B è obbligatorio per pianificazione biweekly'),
        );
      });

      test('biweekly con template A e B → valido', () {
        final planning = createPlanning(
          type: StaffPlanningType.biweekly,
          validFrom: DateTime(2026, 1, 1),
          withTemplateA: true,
          withTemplateB: true,
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isTrue);
      });

      test('weekly con solo template A → valido', () {
        final planning = createPlanning(
          type: StaffPlanningType.weekly,
          validFrom: DateTime(2026, 1, 1),
          withTemplateA: true,
          withTemplateB: false,
        );

        final result = validator.validateForCreate(planning, []);

        expect(result.isValid, isTrue);
      });
    });

    group('Non sovrapposizione intervalli', () {
      test('intervalli completamente separati → valido', () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 31),
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 3, 1),
          validTo: DateTime(2026, 3, 31),
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isTrue);
      });

      test(
        'intervalli contigui (new.validFrom = existing.validTo + 1) → valido',
        () {
          final existing = createPlanning(
            id: 1,
            validFrom: DateTime(2026, 1, 1),
            validTo: DateTime(2026, 1, 31),
          );
          final newPlanning = createPlanning(
            id: 2,
            validFrom: DateTime(2026, 2, 1), // Giorno dopo validTo
            validTo: DateTime(2026, 2, 28),
          );

          final result = validator.validateForCreate(newPlanning, [existing]);

          expect(result.isValid, isTrue);
        },
      );

      test('stesso giorno (new.validFrom = existing.validTo) → OVERLAP', () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 31),
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 1, 31), // Stesso giorno di validTo!
          validTo: DateTime(2026, 2, 28),
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('Sovrapposizione'));
      });

      test('nuovo dentro esistente → OVERLAP', () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 12, 31),
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 3, 1),
          validTo: DateTime(2026, 3, 31),
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('Sovrapposizione'));
      });

      test('nuovo con existing open-ended che inizia prima → OVERLAP', () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 1, 1),
          validTo: null, // Open-ended
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 6, 1),
          validTo: DateTime(2026, 6, 30),
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('Sovrapposizione'));
      });

      test('nuovo open-ended con existing che inizia dopo → OVERLAP', () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 6, 1),
          validTo: DateTime(2026, 6, 30),
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 1, 1),
          validTo: null, // Open-ended, copre tutto il futuro
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('Sovrapposizione'));
      });

      test('due open-ended → OVERLAP', () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 1, 1),
          validTo: null,
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 6, 1),
          validTo: null,
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isFalse);
      });

      test('planning di staff diversi → non sovrapposti', () {
        final existingOtherStaff = createPlanning(
          id: 1,
          staffId: 99, // Staff diverso!
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 12, 31),
        );
        final newPlanning = createPlanning(
          id: 2,
          staffId: 10,
          validFrom: DateTime(2026, 6, 1),
          validTo: DateTime(2026, 6, 30),
        );

        final result = validator.validateForCreate(newPlanning, [
          existingOtherStaff,
        ]);

        expect(result.isValid, isTrue);
      });
    });
  });

  group('StaffPlanningValidator - validateForUpdate', () {
    test('modifica che non crea overlap → valido', () {
      final original = createPlanning(
        id: 1,
        validFrom: DateTime(2026, 1, 1),
        validTo: DateTime(2026, 1, 31),
      );
      final modified = createPlanning(
        id: 1,
        validFrom: DateTime(2026, 1, 1),
        validTo: DateTime(2026, 2, 15), // Esteso
      );
      final other = createPlanning(
        id: 2,
        validFrom: DateTime(2026, 3, 1),
        validTo: DateTime(2026, 3, 31),
      );

      final result = validator.validateForUpdate(modified, [
        original,
        other,
      ], original);

      expect(result.isValid, isTrue);
    });

    test('modifica esclude sé stesso dal check overlap', () {
      final original = createPlanning(
        id: 1,
        validFrom: DateTime(2026, 1, 1),
        validTo: DateTime(2026, 1, 31),
      );
      // Stesso intervallo (non dovrebbe dare overlap perché è sé stesso)
      final modified = original.copyWith(validTo: () => DateTime(2026, 2, 15));

      final result = validator.validateForUpdate(modified, [
        original,
      ], original);

      expect(result.isValid, isTrue);
    });

    test('cambio weekly → biweekly senza template B → errore', () {
      final original = createPlanning(
        type: StaffPlanningType.weekly,
        validFrom: DateTime(2026, 1, 1),
        withTemplateA: true,
      );
      final modified = createPlanning(
        type: StaffPlanningType.biweekly, // Cambiato!
        validFrom: DateTime(2026, 1, 1),
        withTemplateA: true,
        withTemplateB: false, // Manca B!
      );

      final result = validator.validateForUpdate(modified, [
        original,
      ], original);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Cambio a biweekly richiede template B'));
    });

    test('shift validFrom in biweekly → warning parità A/B', () {
      final original = createPlanning(
        type: StaffPlanningType.biweekly,
        validFrom: DateTime(2026, 1, 6), // Lunedì
        withTemplateA: true,
        withTemplateB: true,
      );
      final modified = createPlanning(
        type: StaffPlanningType.biweekly,
        validFrom: DateTime(2026, 1, 13), // Lunedì successivo - cambiato!
        withTemplateA: true,
        withTemplateB: true,
      );

      final result = validator.validateForUpdate(modified, [
        original,
      ], original);

      expect(result.isValid, isTrue); // È un warning, non un errore
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('parità del ciclo A/B'));
    });

    test('shift validFrom in weekly → nessun warning', () {
      final original = createPlanning(
        type: StaffPlanningType.weekly,
        validFrom: DateTime(2026, 1, 6),
      );
      final modified = createPlanning(
        type: StaffPlanningType.weekly,
        validFrom: DateTime(2026, 1, 13),
      );

      final result = validator.validateForUpdate(modified, [
        original,
      ], original);

      expect(result.isValid, isTrue);
      expect(result.warnings, isEmpty);
    });
  });

  group('Edge cases critici (da STAFF_PLANNING_MODEL.md)', () {
    test('valid_to < valid_from → rifiutare', () {
      final planning = createPlanning(
        validFrom: DateTime(2026, 6, 15),
        validTo: DateTime(2026, 6, 1),
      );

      final result = validator.validateForCreate(planning, []);

      expect(result.isValid, isFalse);
    });

    test(
      'valid_to = X e new.valid_from = X → sovrapposti (giorno X doppio)',
      () {
        final existing = createPlanning(
          id: 1,
          validFrom: DateTime(2026, 1, 1),
          validTo: DateTime(2026, 1, 15), // X = 15 gennaio
        );
        final newPlanning = createPlanning(
          id: 2,
          validFrom: DateTime(2026, 1, 15), // Inizia lo stesso giorno X
          validTo: DateTime(2026, 1, 31),
        );

        final result = validator.validateForCreate(newPlanning, [existing]);

        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('Sovrapposizione'));
      },
    );

    test('new.valid_from = X + 1 → consentito (contiguità)', () {
      final existing = createPlanning(
        id: 1,
        validFrom: DateTime(2026, 1, 1),
        validTo: DateTime(2026, 1, 15), // X = 15 gennaio
      );
      final newPlanning = createPlanning(
        id: 2,
        validFrom: DateTime(2026, 1, 16), // X + 1 = 16 gennaio
        validTo: DateTime(2026, 1, 31),
      );

      final result = validator.validateForCreate(newPlanning, [existing]);

      expect(result.isValid, isTrue);
    });

    test('overlap con planning illimitato (valid_to null) → rifiutare', () {
      final existing = createPlanning(
        id: 1,
        validFrom: DateTime(2026, 1, 1),
        validTo: null, // Illimitato
      );
      final newPlanning = createPlanning(
        id: 2,
        validFrom: DateTime(2027, 1, 1),
        validTo: DateTime(2027, 12, 31),
      );

      final result = validator.validateForCreate(newPlanning, [existing]);

      expect(result.isValid, isFalse);
    });

    test(
      'template giorno senza slot → giorno non disponibile (non errore)',
      () {
        final planning = StaffPlanning(
          id: 1,
          staffId: 10,
          type: StaffPlanningType.weekly,
          validFrom: DateTime(2026, 1, 1),
          templates: [
            StaffPlanningWeekTemplate(
              id: 100,
              staffPlanningId: 1,
              weekLabel: WeekLabel.a,
              daySlots: {
                1: {36, 37}, // Lunedì: lavora
                2: {}, // Martedì: set vuoto → non lavora
                // Altri giorni non presenti → non lavora
              },
            ),
          ],
          createdAt: DateTime.now(),
        );

        final result = validator.validateForCreate(planning, []);

        // È valido: giorni senza slot = staff non disponibile (non è un errore)
        expect(result.isValid, isTrue);
      },
    );
  });
}
