import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff_planning.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/services/staff_planning_selector.dart';
import '../../../core/validation/staff_planning_validator.dart';
import '../../agenda/providers/date_range_provider.dart';

/// Risultato di una operazione di add/update planning con planning incluso.
class StaffPlanningResult {
  final bool isValid;
  final List<String> errors;
  final StaffPlanning? planning;

  const StaffPlanningResult({
    required this.isValid,
    this.errors = const [],
    this.planning,
  });

  factory StaffPlanningResult.success(StaffPlanning planning) =>
      StaffPlanningResult(isValid: true, planning: planning);

  factory StaffPlanningResult.failure(List<String> errors) =>
      StaffPlanningResult(isValid: false, errors: errors);
}

/// Provider per il selettore di planning.
final staffPlanningSelectorProvider = Provider<StaffPlanningSelector>((ref) {
  return StaffPlanningSelector();
});

/// Provider per il validatore di planning.
final staffPlanningValidatorProvider = Provider<StaffPlanningValidator>((ref) {
  return StaffPlanningValidator();
});

/// State per i planning degli staff.
/// Mappa: staffId → `List<StaffPlanning>`
typedef StaffPlanningsState = Map<int, List<StaffPlanning>>;

/// Provider per la gestione dei planning degli staff.
///
/// Gestisce:
/// - Caricamento planning da API
/// - Selezione planning per data (biweekly A/B incluso)
/// - Validazione create/update
/// - Cache locale dei planning
class StaffPlanningsNotifier extends Notifier<StaffPlanningsState> {
  @override
  StaffPlanningsState build() {
    return {};
  }

  StaffPlanningValidator get _validator =>
      ref.read(staffPlanningValidatorProvider);

  /// Lista flat di tutti i planning (per validazione).
  List<StaffPlanning> get _allPlannings {
    return state.values.expand((list) => list).toList();
  }

  /// Carica i planning per uno staff specifico dall'API.
  Future<void> loadPlanningsForStaff(int staffId) async {
    // ignore: avoid_print
    print('DEBUG loadPlanningsForStaff staffId=$staffId');
    try {
      final api = ref.read(apiClientProvider);
      final planningsJson = await api.getStaffPlannings(staffId);
      // ignore: avoid_print
      print('DEBUG loadPlanningsForStaff response: $planningsJson');

      final plannings = planningsJson
          .map((json) => StaffPlanning.fromJson(json))
          .toList();
      // ignore: avoid_print
      print('DEBUG loadPlanningsForStaff parsed ${plannings.length} plannings');

      state = {...state, staffId: plannings};
    } catch (e, st) {
      // ignore: avoid_print
      print('DEBUG loadPlanningsForStaff ERROR: $e');
      // ignore: avoid_print
      print('DEBUG stackTrace: $st');
    }
  }

  /// Aggiunge un planning con validazione.
  ///
  /// Ritorna [StaffPlanningResult] con esito e planning creato (con ID dal server).
  Future<StaffPlanningResult> addPlanning(StaffPlanning planning) async {
    final validation = _validator.validateForCreate(planning, _allPlannings);

    if (!validation.isValid) {
      return StaffPlanningResult.failure(validation.errors);
    }

    try {
      final api = ref.read(apiClientProvider);
      // DEBUG: stampa payload
      final payload = {
        'staffId': planning.staffId,
        'type': planning.type.name,
        'validFrom': _dateToIso(planning.validFrom),
        'validTo': planning.validTo != null
            ? _dateToIso(planning.validTo!)
            : null,
        'templates': planning.templates.map((t) => t.toJson()).toList(),
      };
      // ignore: avoid_print
      print('DEBUG createStaffPlanning payload: $payload');

      final response = await api.createStaffPlanning(
        staffId: planning.staffId,
        type: planning.type.name,
        validFrom: _dateToIso(planning.validFrom),
        validTo: planning.validTo != null
            ? _dateToIso(planning.validTo!)
            : null,
        templates: planning.templates.map((t) => t.toJson()).toList(),
      );

      // ignore: avoid_print
      print('DEBUG createStaffPlanning response: $response');

      // Usa il planning ritornato dal server (con ID generato)
      final createdPlanning = StaffPlanning.fromJson(response);
      final staffPlannings = List<StaffPlanning>.from(
        state[planning.staffId] ?? [],
      );
      staffPlannings.add(createdPlanning);

      state = {...state, planning.staffId: staffPlannings};

      return StaffPlanningResult.success(createdPlanning);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('DEBUG createStaffPlanning ERROR: $e');
      // ignore: avoid_print
      print('DEBUG stackTrace: $stackTrace');
      return StaffPlanningResult.failure(['api_error: ${e.toString()}']);
    }
  }

  /// Aggiorna un planning esistente con validazione.
  Future<StaffPlanningValidationResult> updatePlanning(
    StaffPlanning planning,
    StaffPlanning original,
  ) async {
    // ignore: avoid_print
    print(
      'DEBUG updatePlanning called: planningId=${planning.id}, staffId=${planning.staffId}',
    );
    // ignore: avoid_print
    print(
      'DEBUG updatePlanning templates: ${planning.templates.map((t) => t.toJson()).toList()}',
    );

    final result = _validator.validateForUpdate(
      planning,
      _allPlannings,
      original,
    );

    if (!result.isValid) {
      return result;
    }

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.updateStaffPlanning(
        staffId: planning.staffId,
        planningId: planning.id,
        type: planning.type.name,
        validFrom: _dateToIso(planning.validFrom),
        validTo: planning.validTo != null
            ? _dateToIso(planning.validTo!)
            : null,
        templates: planning.templates.map((t) => t.toJson()).toList(),
      );

      final updatedPlanning = StaffPlanning.fromJson(response);
      final staffPlannings = List<StaffPlanning>.from(
        state[planning.staffId] ?? [],
      );

      final index = staffPlannings.indexWhere((p) => p.id == planning.id);
      if (index != -1) {
        staffPlannings[index] = updatedPlanning;
      }

      state = {...state, planning.staffId: staffPlannings};
    } catch (e) {
      return StaffPlanningValidationResult(
        isValid: false,
        errors: ['api_error: ${e.toString()}'],
      );
    }

    return result;
  }

  /// Elimina un planning.
  Future<void> deletePlanning(int staffId, int planningId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.deleteStaffPlanning(staffId, planningId);

      final staffPlannings = List<StaffPlanning>.from(state[staffId] ?? []);
      staffPlannings.removeWhere((p) => p.id == planningId);

      state = {...state, staffId: staffPlannings};
    } catch (e) {
      // In caso di errore, non modifica lo stato
      rethrow;
    }
  }

  /// Imposta i planning per uno staff (es. dopo caricamento da API).
  void setPlanningsForStaff(int staffId, List<StaffPlanning> plannings) {
    state = {...state, staffId: plannings};
  }

  /// Formatta DateTime in stringa ISO date.
  String _dateToIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Provider principale per i planning.
final staffPlanningsProvider =
    NotifierProvider<StaffPlanningsNotifier, StaffPlanningsState>(
      StaffPlanningsNotifier.new,
    );

/// Provider per ottenere il planning valido per uno staff in una data.
///
/// Ritorna [PlanningLookupResult]:
/// - [NoPlanningFound] se nessun planning valido
/// - [PlanningFound] con planning e week label (A/B)
/// - [MultiplePlanningsFound] se errore dati
final planningForStaffOnDateProvider =
    Provider.family<PlanningLookupResult, ({int staffId, DateTime date})>((
      ref,
      params,
    ) {
      final plannings = ref.watch(staffPlanningsProvider);
      final selector = ref.watch(staffPlanningSelectorProvider);

      return selector.findPlanningForDate(
        staffId: params.staffId,
        date: params.date,
        allPlannings: plannings.values.expand((list) => list).toList(),
      );
    });

/// Provider per gli slot disponibili di uno staff in una data.
///
/// Ritorna [Set<int>] degli slot index disponibili.
/// Set vuoto se nessun planning o giorno non lavorativo.
/// null se errore di consistenza (planning multipli).
final planningSlotsForDateProvider =
    Provider.family<Set<int>?, ({int staffId, DateTime date})>((ref, params) {
      final result = ref.watch(planningForStaffOnDateProvider(params));

      return switch (result) {
        NoPlanningFound() => {},
        PlanningFound(template: final t) => t.getSlotsForDay(
          params.date.weekday,
        ),
        MultiplePlanningsFound() => null,
      };
    });

/// Provider per verificare se uno staff è disponibile in una data.
final isStaffAvailableOnDateProvider =
    Provider.family<bool, ({int staffId, DateTime date})>((ref, params) {
      final slots = ref.watch(planningSlotsForDateProvider(params));
      return slots != null && slots.isNotEmpty;
    });

/// Provider per la week label (A/B) di una data per uno staff con biweekly.
///
/// Ritorna null se:
/// - Nessun planning valido
/// - Planning è weekly (non biweekly)
final weekLabelForDateProvider =
    Provider.family<WeekLabel?, ({int staffId, DateTime date})>((ref, params) {
      final result = ref.watch(planningForStaffOnDateProvider(params));

      if (result is PlanningFound) {
        final planning = result.planning;
        if (planning.type == StaffPlanningType.biweekly) {
          return result.weekLabel;
        }
      }

      return null;
    });

/// Provider per gli slot disponibili dello staff nella data corrente dell'agenda.
///
/// Combina:
/// 1. Planning base (template settimanale con supporto biweekly)
/// 2. Eccezioni (da availabilityExceptionsProvider)
///
/// Usa la data da [agendaDateProvider].
final staffPlanningBaseSlotsProvider = Provider.family<Set<int>, int>((
  ref,
  staffId,
) {
  final agendaDate = ref.watch(agendaDateProvider);
  final slots = ref.watch(
    planningSlotsForDateProvider((staffId: staffId, date: agendaDate)),
  );

  return slots ?? {};
});

/// Provider per verificare se una data è in settimana A o B.
///
/// Per planning weekly, ritorna sempre 'A'.
/// Per planning biweekly, calcola in base a validFrom.
/// Ritorna null se nessun planning.
final currentWeekLabelProvider = Provider.family<WeekLabel?, int>((
  ref,
  staffId,
) {
  final agendaDate = ref.watch(agendaDateProvider);
  return ref.watch(
    weekLabelForDateProvider((staffId: staffId, date: agendaDate)),
  );
});

/// Provider per i planning di uno staff specifico.
final planningsForStaffProvider = Provider.family<List<StaffPlanning>, int>((
  ref,
  staffId,
) {
  final plannings = ref.watch(staffPlanningsProvider);
  return plannings[staffId] ?? [];
});

/// Provider derivato per il planning attivo di uno staff nella data corrente.
final currentPlanningForStaffProvider = Provider.family<StaffPlanning?, int>((
  ref,
  staffId,
) {
  final agendaDate = ref.watch(agendaDateProvider);
  final result = ref.watch(
    planningForStaffOnDateProvider((staffId: staffId, date: agendaDate)),
  );

  if (result is PlanningFound) {
    return result.planning;
  }
  return null;
});

/// Provider che carica automaticamente i planning per uno staff.
///
/// Usa questo provider nell'agenda per assicurarsi che i planning
/// siano caricati prima di calcolare la disponibilità.
final ensureStaffPlanningLoadedProvider = FutureProvider.family<void, int>((
  ref,
  staffId,
) async {
  final plannings = ref.watch(staffPlanningsProvider);

  // Se i planning per questo staff sono già caricati, non fare nulla
  if (plannings.containsKey(staffId)) {
    return;
  }

  // Altrimenti carica i planning
  await ref
      .read(staffPlanningsProvider.notifier)
      .loadPlanningsForStaff(staffId);
});
