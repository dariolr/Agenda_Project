import '../models/staff_planning.dart';

/// Risultato della ricerca di un planning valido per una data.
sealed class PlanningLookupResult {
  const PlanningLookupResult();
}

/// Nessun planning trovato per la data.
/// Staff non disponibile in quella data.
class NoPlanningFound extends PlanningLookupResult {
  const NoPlanningFound();

  @override
  String toString() => 'NoPlanningFound()';
}

/// Planning valido trovato.
class PlanningFound extends PlanningLookupResult {
  final StaffPlanning planning;
  final WeekLabel weekLabel;
  final StaffPlanningWeekTemplate template;

  const PlanningFound({
    required this.planning,
    required this.weekLabel,
    required this.template,
  });

  @override
  String toString() =>
      'PlanningFound(planning: ${planning.id}, weekLabel: ${weekLabel.name})';
}

/// Errore: trovati più planning validi (inconsistenza dati).
class MultiplePlanningsFound extends PlanningLookupResult {
  final List<StaffPlanning> plannings;
  final String message;

  const MultiplePlanningsFound({
    required this.plannings,
    required this.message,
  });

  @override
  String toString() => 'MultiplePlanningsFound(count: ${plannings.length})';
}

/// Servizio per la selezione del planning valido per una data.
///
/// Implementa le regole di STAFF_PLANNING_MODEL.md:
/// - Filtra planning con valid_from ≤ D ≤ valid_to (o valid_to null)
/// - Nessun planning → staff non disponibile
/// - Più di uno → errore di consistenza
class StaffPlanningSelector {
  /// Trova il planning valido per uno staff in una data specifica.
  ///
  /// [staffId] ID dello staff.
  /// [date] Data per cui cercare il planning.
  /// [allPlannings] Tutti i planning disponibili (già filtrati per staff se desiderato).
  ///
  /// Ritorna:
  /// - [NoPlanningFound] se non esiste planning valido per la data
  /// - [PlanningFound] se esiste esattamente un planning valido
  /// - [MultiplePlanningsFound] se esistono più planning validi (errore dati)
  PlanningLookupResult findPlanningForDate({
    required int staffId,
    required DateTime date,
    required List<StaffPlanning> allPlannings,
  }) {
    // Filtra i planning per questo staff
    final staffPlannings = allPlannings
        .where((p) => p.staffId == staffId)
        .toList();

    // Filtra i planning validi per la data
    final validPlannings = staffPlannings
        .where((p) => p.isValidForDate(date))
        .toList();

    // Caso 1: nessun planning → staff non disponibile
    if (validPlannings.isEmpty) {
      return const NoPlanningFound();
    }

    // Caso 2: più di uno → errore di consistenza
    if (validPlannings.length > 1) {
      return MultiplePlanningsFound(
        plannings: validPlannings,
        message:
            'Trovati ${validPlannings.length} planning validi per staff $staffId '
            'alla data ${_formatDate(date)}. '
            'Questo indica un errore nei dati (intervalli sovrapposti).',
      );
    }

    // Caso 3: esattamente un planning
    final planning = validPlannings.first;
    final weekLabel = planning.computeWeekLabel(date);
    final template = planning.getTemplateForDate(date);

    // Verifica che il template esista
    if (template == null) {
      // Questo non dovrebbe accadere se la validazione è corretta,
      // ma gestiamo il caso per robustezza
      return const NoPlanningFound();
    }

    return PlanningFound(
      planning: planning,
      weekLabel: weekLabel,
      template: template,
    );
  }

  /// Ottiene gli slot disponibili per uno staff in una data specifica.
  ///
  /// Ritorna un Set vuoto se:
  /// - Non esiste planning valido per la data
  /// - Il giorno non ha slot configurati nel template
  ///
  /// Ritorna null se c'è un errore di consistenza (più planning).
  Set<int>? getSlotsForDate({
    required int staffId,
    required DateTime date,
    required List<StaffPlanning> allPlannings,
  }) {
    final result = findPlanningForDate(
      staffId: staffId,
      date: date,
      allPlannings: allPlannings,
    );

    return switch (result) {
      NoPlanningFound() => {},
      PlanningFound(template: final t) => t.getSlotsForDay(date.weekday),
      MultiplePlanningsFound() => null, // Errore, caller deve gestire
    };
  }

  /// Verifica se uno staff è disponibile in una data.
  ///
  /// Ritorna true se:
  /// - Esiste un planning valido per la data
  /// - Il giorno ha almeno uno slot configurato
  bool isStaffAvailable({
    required int staffId,
    required DateTime date,
    required List<StaffPlanning> allPlannings,
  }) {
    final slots = getSlotsForDate(
      staffId: staffId,
      date: date,
      allPlannings: allPlannings,
    );

    return slots != null && slots.isNotEmpty;
  }

  /// Trova tutti i planning validi in un range di date per uno staff.
  ///
  /// Utile per visualizzare la pianificazione in un calendario.
  /// Ritorna una mappa: data → PlanningLookupResult
  Map<DateTime, PlanningLookupResult> findPlanningsForRange({
    required int staffId,
    required DateTime startDate,
    required DateTime endDate,
    required List<StaffPlanning> allPlannings,
  }) {
    final results = <DateTime, PlanningLookupResult>{};

    var current = DateUtils.dateOnly(startDate);
    final end = DateUtils.dateOnly(endDate);

    while (!current.isAfter(end)) {
      results[current] = findPlanningForDate(
        staffId: staffId,
        date: current,
        allPlannings: allPlannings,
      );
      current = current.add(const Duration(days: 1));
    }

    return results;
  }

  /// Trova il prossimo planning valido dopo una data.
  ///
  /// Utile per mostrare quando uno staff diventerà disponibile.
  /// Ritorna null se non esiste un planning futuro.
  StaffPlanning? findNextPlanning({
    required int staffId,
    required DateTime afterDate,
    required List<StaffPlanning> allPlannings,
  }) {
    final date = DateUtils.dateOnly(afterDate);

    // Filtra i planning per questo staff che iniziano dopo la data
    final futurePlannings = allPlannings
        .where((p) => p.staffId == staffId)
        .where((p) => DateUtils.dateOnly(p.validFrom).isAfter(date))
        .toList();

    if (futurePlannings.isEmpty) return null;

    // Ordina per validFrom e prendi il primo
    futurePlannings.sort((a, b) => a.validFrom.compareTo(b.validFrom));
    return futurePlannings.first;
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
