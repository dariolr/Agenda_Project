import '../models/staff_planning.dart';

/// Risultato della validazione di uno StaffPlanning.
class StaffPlanningValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const StaffPlanningValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory StaffPlanningValidationResult.valid({
    List<String> warnings = const [],
  }) => StaffPlanningValidationResult(isValid: true, warnings: warnings);

  factory StaffPlanningValidationResult.invalid(
    List<String> errors, {
    List<String> warnings = const [],
  }) => StaffPlanningValidationResult(
    isValid: false,
    errors: errors,
    warnings: warnings,
  );
}

/// Validatore per StaffPlanning.
///
/// Implementa le regole definite in docs/STAFF_PLANNING_MODEL.md:
/// - Obbligatori: valid_from, type, template A (e B se biweekly)
/// - valid_to ≥ valid_from quando presente
/// - Non sovrapposizione intervalli per stesso staff
/// - Template coerenti con type
class StaffPlanningValidator {
  /// Valida un planning per creazione.
  ///
  /// [planning] il nuovo planning da validare.
  /// [existingPlannings] non usato - l'API fa auto-split.
  StaffPlanningValidationResult validateForCreate(
    StaffPlanning planning,
    // ignore: avoid_unused_constructor_parameters
    List<StaffPlanning> existingPlannings,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Validazioni base
    _validateBasicRules(planning, errors, warnings);

    if (errors.isNotEmpty) {
      return StaffPlanningValidationResult.invalid(errors, warnings: warnings);
    }

    // 2. Validazioni template
    _validateTemplates(planning, errors);

    // 3. Non validare overlap lato client: l'API fa auto-split automatico

    return errors.isEmpty
        ? StaffPlanningValidationResult.valid(warnings: warnings)
        : StaffPlanningValidationResult.invalid(errors, warnings: warnings);
  }

  /// Valida un planning per aggiornamento.
  ///
  /// [planning] il planning modificato.
  /// [existingPlannings] non usato - l'API fa auto-split.
  /// [originalPlanning] il planning originale prima delle modifiche.
  StaffPlanningValidationResult validateForUpdate(
    StaffPlanning planning,
    // ignore: avoid_unused_constructor_parameters
    List<StaffPlanning> existingPlannings,
    StaffPlanning originalPlanning,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Validazioni base
    _validateBasicRules(planning, errors, warnings);

    if (errors.isNotEmpty) {
      return StaffPlanningValidationResult.invalid(errors, warnings: warnings);
    }

    // 2. Validazioni template
    _validateTemplates(planning, errors);

    // 3. Non validare overlap lato client: l'API fa auto-split automatico

    // 4. Warning per cambio type senza adeguare template
    if (originalPlanning.type != planning.type) {
      if (planning.type == StaffPlanningType.biweekly &&
          planning.templateB == null) {
        errors.add('Cambio a biweekly richiede template B');
      }
    }

    // 5. Warning per shift validFrom in biweekly (altera parità A/B)
    if (planning.type == StaffPlanningType.biweekly &&
        originalPlanning.validFrom != planning.validFrom) {
      warnings.add(
        'Spostare valid_from in un planning biweekly altera la parità del ciclo A/B '
        'per tutto l\'intervallo',
      );
    }

    return errors.isEmpty
        ? StaffPlanningValidationResult.valid(warnings: warnings)
        : StaffPlanningValidationResult.invalid(errors, warnings: warnings);
  }

  /// Validazioni base comuni.
  void _validateBasicRules(
    StaffPlanning planning,
    List<String> errors,
    List<String> warnings,
  ) {
    if (planning.planningSlotMinutes <= 0) {
      errors.add('planning_slot_minutes deve essere > 0');
    } else if ((24 * 60) % planning.planningSlotMinutes != 0) {
      errors.add(
        'planning_slot_minutes deve dividere 24h senza resto',
      );
    }

    // valid_to ≥ valid_from quando presente
    if (planning.validTo != null) {
      final from = DateUtils.dateOnly(planning.validFrom);
      final to = DateUtils.dateOnly(planning.validTo!);
      if (to.isBefore(from)) {
        errors.add('valid_to non può essere precedente a valid_from');
      }
    }
  }

  /// Validazioni sui template.
  void _validateTemplates(StaffPlanning planning, List<String> errors) {
    // Template A obbligatorio
    if (planning.templateA == null) {
      errors.add('Template A è obbligatorio');
      return;
    }

    // Per biweekly, template B obbligatorio
    if (planning.type == StaffPlanningType.biweekly &&
        planning.templateB == null) {
      errors.add('Template B è obbligatorio per pianificazione biweekly');
    }

    // Validazione formato slot in ogni template
    for (final template in planning.templates) {
      _validateTemplateSlots(
        template,
        planning.planningSlotMinutes,
        errors,
      );
    }
  }

  /// Validazione slot di un template.
  void _validateTemplateSlots(
    StaffPlanningWeekTemplate template,
    int planningSlotMinutes,
    List<String> errors,
  ) {
    final maxSlotIndex = ((24 * 60) ~/ planningSlotMinutes) - 1;

    for (final entry in template.daySlots.entries) {
      final day = entry.key;
      final slots = entry.value;

      // day_of_week deve essere 1-7
      if (day < 1 || day > 7) {
        errors.add('day_of_week invalido: $day (deve essere 1-7)');
      }

      // Slot devono essere indici validi rispetto al planning slot.
      for (final slot in slots) {
        if (slot < 0 || slot > maxSlotIndex) {
          errors.add(
            'Slot index invalido: $slot nel giorno $day '
            '(deve essere 0-$maxSlotIndex per slot da $planningSlotMinutes minuti)',
          );
        }
      }
    }
  }
}
