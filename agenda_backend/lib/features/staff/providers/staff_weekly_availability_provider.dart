import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff_planning.dart';
import '../../../core/services/staff_planning_selector.dart' show PlanningFound;
import '../../agenda/providers/date_range_provider.dart';
import 'staff_planning_provider.dart';
import 'staff_providers.dart';

/// Disponibilità settimanale derivata dal planning:
/// staffId -> weekday(1..7) -> slot indices.
class StaffAvailabilityByStaffNotifier
    extends AsyncNotifier<Map<int, Map<int, Set<int>>>> {
  @override
  FutureOr<Map<int, Map<int, Set<int>>>> build() async {
    final staffList = ref.watch(sortedAllStaffProvider);
    final allPlanningsState = ref.watch(staffPlanningsProvider);
    final selector = ref.watch(staffPlanningSelectorProvider);
    final weekDate = ref.watch(agendaDateProvider);
    final monday = _mondayOfWeek(weekDate);

    final allPlannings = allPlanningsState.values.expand((list) => list).toList();
    final result = <int, Map<int, Set<int>>>{};

    for (final staff in staffList) {
      final staffWeek = <int, Set<int>>{};
      for (int weekday = 1; weekday <= 7; weekday++) {
        final date = monday.add(Duration(days: weekday - 1));
        final lookup = selector.findPlanningForDate(
          staffId: staff.id,
          date: date,
          allPlannings: allPlannings,
        );
        final daySlots = switch (lookup) {
          PlanningFound(template: final template) => template.getSlotsForDay(
            weekday,
          ),
          _ => <int>{},
        };
        staffWeek[weekday] = Set<int>.from(daySlots);
      }
      result[staff.id] = staffWeek;
    }

    return result;
  }

  DateTime _mondayOfWeek(DateTime d) {
    final onlyDate = DateTime(d.year, d.month, d.day);
    return onlyDate.subtract(Duration(days: onlyDate.weekday - 1));
  }

  Future<void> saveForStaff(int staffId, Map<int, Set<int>> weeklySlots) async {
    final previousState = state;
    state = const AsyncLoading();

    try {
      final planningNotifier = ref.read(staffPlanningsProvider.notifier);
      var plannings = List<StaffPlanning>.from(
        ref.read(planningsForStaffProvider(staffId)),
      );
      if (plannings.isEmpty) {
        await planningNotifier.loadPlanningsForStaff(staffId);
        plannings = List<StaffPlanning>.from(
          ref.read(planningsForStaffProvider(staffId)),
        );
      }

      if (plannings.isEmpty) {
        state = previousState;
        return;
      }

      final selector = ref.read(staffPlanningSelectorProvider);
      final weekDate = ref.read(agendaDateProvider);
      final monday = _mondayOfWeek(weekDate);
      final originalsById = {for (final p in plannings) p.id: p};
      final updatedById = <int, StaffPlanning>{};

      for (int weekday = 1; weekday <= 7; weekday++) {
        final date = monday.add(Duration(days: weekday - 1));
        final lookup = selector.findPlanningForDate(
          staffId: staffId,
          date: date,
          allPlannings: plannings,
        );
        if (lookup is! PlanningFound) continue;

        final original = originalsById[lookup.planning.id];
        if (original == null) continue;
        final currentPlanning = updatedById[original.id] ?? original;
        final template = lookup.weekLabel == WeekLabel.a
            ? currentPlanning.templateA
            : currentPlanning.templateB;
        if (template == null) continue;

        final updatedDaySlots = Map<int, Set<int>>.from(template.daySlots);
        updatedDaySlots[weekday] = Set<int>.from(weeklySlots[weekday] ?? {});
        final updatedTemplate = template.copyWith(daySlots: updatedDaySlots);

        final updatedTemplates = currentPlanning.templates
            .map(
              (t) => t.weekLabel == updatedTemplate.weekLabel
                  ? updatedTemplate
                  : t,
            )
            .toList();
        updatedById[original.id] = currentPlanning.copyWith(
          templates: updatedTemplates,
        );
      }

      for (final entry in updatedById.entries) {
        final original = originalsById[entry.key];
        if (original == null) continue;
        final result = await planningNotifier.updatePlanning(
          entry.value,
          original,
        );
        if (!result.isValid) {
          throw Exception(result.errors.join('\n'));
        }
      }

      ref.invalidateSelf();
      state = AsyncData(await future);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final staffAvailabilityByStaffProvider = AsyncNotifierProvider<
  StaffAvailabilityByStaffNotifier,
  Map<int, Map<int, Set<int>>>
>(StaffAvailabilityByStaffNotifier.new);
