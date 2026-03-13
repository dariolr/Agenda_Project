import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/availability_exception.dart';
import '../../../core/models/staff_planning.dart';
import '../../../core/services/staff_planning_selector.dart';
import '../../business/providers/location_closures_provider.dart';
import '../../staff/providers/staff_planning_provider.dart';
import '../../staff/providers/availability_exceptions_provider.dart';
import 'date_range_provider.dart';
import 'layout_config_provider.dart';

/// Provider che fornisce la disponibilità degli slot per uno staff specifico
/// in base alla data corrente dell'agenda.
///
/// La disponibilità finale è calcolata come:
/// 0. CHECK: Se la data è in un periodo di chiusura, ritorna Set vuoto
/// 1. Base: planning da API (template settimanale con supporto biweekly A/B)
/// 2. + Eccezioni "available": aggiungono slot disponibili
/// 3. - Eccezioni "unavailable": rimuovono slot disponibili
///
/// Ritorna un `Set<int>` contenente gli indici degli slot DISPONIBILI.
/// - Set vuoto = nessuna disponibilità (staff non lavora quel giorno o sede chiusa)
/// - Se non ci sono dati configurati, lo staff è considerato NON disponibile (comportamento restrittivo)
final staffSlotAvailabilityForDateProvider =
    Provider.family<Set<int>, ({int staffId, DateTime date})>((ref, params) {
      final agendaDate = DateUtils.dateOnly(params.date);
      final staffId = params.staffId;
      final layoutConfig = ref.watch(layoutConfigProvider);

      final isClosed = ref.watch(isDateClosedProvider(agendaDate));
      if (isClosed) {
        return const {};
      }

      ref.watch(ensureStaffPlanningLoadedProvider(staffId));

      final planningLookup = ref.watch(
        planningForStaffOnDateProvider((staffId: staffId, date: agendaDate)),
      );
      const planningSlotMinutes = StaffPlanning.planningStepMinutes;
      final planningTotalSlots = (24 * 60) ~/ planningSlotMinutes;

      Set<int> basePlanningSlots = switch (planningLookup) {
        NoPlanningFound() => <int>{},
        PlanningFound(template: final template) => template.getSlotsForDay(
          agendaDate.weekday,
        ),
        MultiplePlanningsFound() => <int>{},
      };

      final exceptions = ref.watch(
        exceptionsForStaffOnDateProvider((staffId: staffId, date: agendaDate)),
      );

      if (exceptions.isEmpty) {
        return _projectPlanningSlotsToLayoutSlots(
          planningSlots: basePlanningSlots,
          planningSlotMinutes: planningSlotMinutes,
          layoutMinutesPerSlot: layoutConfig.minutesPerSlot,
          layoutTotalSlots: layoutConfig.totalSlots,
        );
      }

      Set<int> finalPlanningSlots = Set<int>.from(basePlanningSlots);

      for (final exception in exceptions) {
        final exceptionSlots = exception.toSlotIndices(
          minutesPerSlot: planningSlotMinutes,
          totalSlotsPerDay: planningTotalSlots,
        );

        if (exception.type == AvailabilityExceptionType.available) {
          finalPlanningSlots = finalPlanningSlots.union(exceptionSlots);
        } else {
          finalPlanningSlots = finalPlanningSlots.difference(exceptionSlots);
        }
      }

      return _projectPlanningSlotsToLayoutSlots(
        planningSlots: finalPlanningSlots,
        planningSlotMinutes: planningSlotMinutes,
        layoutMinutesPerSlot: layoutConfig.minutesPerSlot,
        layoutTotalSlots: layoutConfig.totalSlots,
      );
    });

final staffSlotAvailabilityProvider = Provider.family<Set<int>, int>((ref, staffId) {
  final agendaDate = ref.watch(agendaDateProvider);
  return ref.watch(
    staffSlotAvailabilityForDateProvider((staffId: staffId, date: agendaDate)),
  );
});

Set<int> _projectPlanningSlotsToLayoutSlots({
  required Set<int> planningSlots,
  required int planningSlotMinutes,
  required int layoutMinutesPerSlot,
  required int layoutTotalSlots,
}) {
  if (planningSlots.isEmpty) return const {};

  // Mappa minuti disponibili (0..1439) derivati dagli slot planning.
  final availableMinutes = List<bool>.filled(24 * 60, false);
  for (final slot in planningSlots) {
    final start = slot * planningSlotMinutes;
    final end = start + planningSlotMinutes;
    if (start < 0 || start >= 24 * 60) continue;
    final clampedEnd = end.clamp(0, 24 * 60);
    for (int minute = start; minute < clampedEnd; minute++) {
      availableMinutes[minute] = true;
    }
  }

  // Uno slot UI è disponibile solo se TUTTI i minuti nel suo intervallo sono disponibili.
  final layoutSlots = <int>{};
  for (int slot = 0; slot < layoutTotalSlots; slot++) {
    final start = slot * layoutMinutesPerSlot;
    final end = (start + layoutMinutesPerSlot).clamp(0, 24 * 60);
    var fullyAvailable = true;
    for (int minute = start; minute < end; minute++) {
      if (!availableMinutes[minute]) {
        fullyAvailable = false;
        break;
      }
    }
    if (fullyAvailable) {
      layoutSlots.add(slot);
    }
  }

  return layoutSlots;
}

/// Provider che verifica se uno slot specifico è disponibile.
/// Più efficiente per query puntuali.
final isSlotAvailableProvider =
    Provider.family<bool, ({int staffId, int slotIndex})>((ref, params) {
      final availableSlots = ref.watch(
        staffSlotAvailabilityProvider(params.staffId),
      );

      // Se il set è vuoto, lo staff non è disponibile
      if (availableSlots.isEmpty) {
        return false;
      }

      return availableSlots.contains(params.slotIndex);
    });

/// Provider che raggruppa gli slot non disponibili consecutivi
/// per ottimizzare il rendering (un solo widget per range).
///
/// Ritorna una lista di (startIndex, count) per ogni range non disponibile.
final unavailableSlotRangesProvider =
    Provider.family<List<({int startIndex, int count})>, int>((ref, staffId) {
      final availableSlots = ref.watch(staffSlotAvailabilityProvider(staffId));
      final layoutConfig = ref.watch(layoutConfigProvider);
      return _buildUnavailableSlotRanges(
        availableSlots: availableSlots,
        totalSlots: layoutConfig.totalSlots,
      );
    });

final unavailableSlotRangesForDateProvider = Provider.family<
  List<({int startIndex, int count})>,
  ({int staffId, DateTime date})
>((ref, params) {
  final availableSlots = ref.watch(staffSlotAvailabilityForDateProvider(params));
      final layoutConfig = ref.watch(layoutConfigProvider);
      return _buildUnavailableSlotRanges(
        availableSlots: availableSlots,
        totalSlots: layoutConfig.totalSlots,
      );
    });

List<({int startIndex, int count})> _buildUnavailableSlotRanges({
  required Set<int> availableSlots,
  required int totalSlots,
}) {
  if (availableSlots.isEmpty) {
    return [(startIndex: 0, count: totalSlots)];
  }

  final List<({int startIndex, int count})> ranges = [];
  int? rangeStart;
  int rangeCount = 0;

  for (int i = 0; i < totalSlots; i++) {
    final isAvailable = availableSlots.contains(i);

    if (!isAvailable) {
      if (rangeStart == null) {
        rangeStart = i;
        rangeCount = 1;
      } else {
        rangeCount++;
      }
    } else {
      if (rangeStart != null) {
        ranges.add((startIndex: rangeStart, count: rangeCount));
        rangeStart = null;
        rangeCount = 0;
      }
    }
  }

  if (rangeStart != null) {
    ranges.add((startIndex: rangeStart, count: rangeCount));
  }

  return ranges;
}
