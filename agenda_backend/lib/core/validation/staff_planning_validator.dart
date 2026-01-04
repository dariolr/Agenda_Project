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
/// Implementa le regole definite in STAFF_PLANNING_MODEL.md:
/// - Obbligatori: valid_from, type, template A (e B se biweekly)
/// - valid_to ≥ valid_from quando presente
/// - Non sovrapposizione intervalli per stesso staff
/// - Template coerenti con type
class StaffPlanningValidator {
  /// Valida un planning per creazione.
  ///
  /// [planning] il nuovo planning da validare.
  /// [existingPlannings] tutti i planning esistenti per lo stesso staff.
  StaffPlanningValidationResult validateForCreate(
    StaffPlanning planning,
    List<StaffPlanning> existingPlannings,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Validazioni base
    _validateBasicRules(planning, errors, warnings);

    // 2. Validazioni template
    _validateTemplates(planning, errors);

    // 3. Validazione non sovrapposizione con planning esistenti
    _validateNoOverlap(planning, existingPlannings, null, errors);

    return errors.isEmpty
        ? StaffPlanningValidationResult.valid(warnings: warnings)
        : StaffPlanningValidationResult.invalid(errors, warnings: warnings);
  }

  /// Valida un planning per aggiornamento.
  ///
  /// [planning] il planning modificato.
  /// [existingPlannings] tutti i planning esistenti per lo stesso staff.
  /// [originalPlanning] il planning originale prima delle modifiche.
  StaffPlanningValidationResult validateForUpdate(
    StaffPlanning planning,
    List<StaffPlanning> existingPlannings,
    StaffPlanning originalPlanning,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Validazioni base
    _validateBasicRules(planning, errors, warnings);

    // 2. Validazioni template
    _validateTemplates(planning, errors);

    // 3. Validazione non sovrapposizione (escludendo sé stesso)
    _validateNoOverlap(
      planning,
      existingPlannings,
      originalPlanning.id,
      errors,
    );

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
      _validateTemplateSlots(template, errors);
    }
  }

  /// Validazione slot di un template.
  void _validateTemplateSlots(
    StaffPlanningWeekTemplate template,
    List<String> errors,
  ) {
    for (final entry in template.daySlots.entries) {
      final day = entry.key;
      final slots = entry.value;

      // day_of_week deve essere 1-7
      if (day < 1 || day > 7) {
        errors.add('day_of_week invalido: $day (deve essere 1-7)');
      }

      // Slot devono essere indici validi (0-95 per slot da 15 min in 24h)
      for (final slot in slots) {
        if (slot < 0 || slot > 95) {
          errors.add(
            'Slot index invalido: $slot nel giorno $day '
            '(deve essere 0-95 per slot da 15 minuti)',
          );
        }
      }
    }
  }

  /// Validazione non sovrapposizione intervalli.
  ///
  /// [planning] planning da validare.
  /// [existingPlannings] planning esistenti per lo stesso staff.
  /// [excludeId] ID da escludere (per update).
  void _validateNoOverlap(
    StaffPlanning planning,
    List<StaffPlanning> existingPlannings,
    int? excludeId,
    List<String> errors,
  ) {
    for (final existing in existingPlannings) {
      // Salta sé stesso in caso di update
      if (excludeId != null && existing.id == excludeId) continue;

      // Salta planning di altri staff
      if (existing.staffId != planning.staffId) continue;

      if (_intervalsOverlap(planning, existing)) {
        final existingRange = _formatDateRange(existing);
        errors.add('Sovrapposizione con planning esistente: $existingRange');
      }
    }
  }

  /// Verifica se due intervalli si sovrappongono.
  ///
  /// Usa intervalli chiusi-chiusi: [validFrom, validTo].
  /// Due planning con valid_to = X e valid_from = X sono sovrapposti.
  /// Contiguità ammessa solo se new.valid_from = existing.valid_to + 1.
  bool _intervalsOverlap(StaffPlanning a, StaffPlanning b) {
    final aFrom = DateUtils.dateOnly(a.validFrom);
    final aTo = a.validTo != null ? DateUtils.dateOnly(a.validTo!) : null;

    final bFrom = DateUtils.dateOnly(b.validFrom);
    final bTo = b.validTo != null ? DateUtils.dateOnly(b.validTo!) : null;

    // Caso 1: entrambi hanno valid_to
    if (aTo != null && bTo != null) {
      // Non sovrapposti se uno finisce prima che l'altro inizi
      // MA: dato che sono chiusi-chiusi, aTo deve essere PRIMA di bFrom (non uguale)
      // Contiguità: aTo + 1 giorno = bFrom → OK, non overlap
      return !_isBefore(aTo, bFrom) && !_isBefore(bTo, aFrom);
    }

    // Caso 2: a è open-ended (aTo = null)
    if (aTo == null && bTo != null) {
      // a parte da aFrom e va all'infinito
      // overlap se bTo >= aFrom
      return !bTo.isBefore(aFrom);
    }

    // Caso 3: b è open-ended (bTo = null)
    if (aTo != null && bTo == null) {
      // b parte da bFrom e va all'infinito
      // overlap se aTo >= bFrom
      return !aTo.isBefore(bFrom);
    }

    // Caso 4: entrambi open-ended → sempre overlap (se stesso staff)
    return true;
  }

  /// Verifica se a è strettamente prima di b (non contiguità).
  ///
  /// Per intervalli chiusi-chiusi:
  /// - a finisce il giorno X, b inizia il giorno X → OVERLAP
  /// - a finisce il giorno X, b inizia il giorno X+1 → NO OVERLAP (contigui)
  bool _isBefore(DateTime aEnd, DateTime bStart) {
    // aEnd deve essere almeno 1 giorno prima di bStart per non overlap
    final nextDay = aEnd.add(const Duration(days: 1));
    return !nextDay.isAfter(bStart);
  }

  String _formatDateRange(StaffPlanning planning) {
    final from = _formatDate(planning.validFrom);
    final to = planning.validTo != null ? _formatDate(planning.validTo!) : '∞';
    return '[$from, $to]';
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
