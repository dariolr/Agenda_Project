import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';
import '../domain/staff_filter_mode.dart';
import 'staff_slot_availability_provider.dart';

/// Provider per la modalità di filtro staff corrente.
final staffFilterModeProvider =
    NotifierProvider<StaffFilterModeNotifier, StaffFilterMode>(
      StaffFilterModeNotifier.new,
    );

class StaffFilterModeNotifier extends Notifier<StaffFilterMode> {
  @override
  StaffFilterMode build() => StaffFilterMode.onDutyTeam;

  void set(StaffFilterMode mode) {
    state = mode;
  }
}

/// Provider per gli ID degli staff selezionati manualmente.
final selectedStaffIdsProvider =
    NotifierProvider<SelectedStaffIdsNotifier, Set<int>>(
      SelectedStaffIdsNotifier.new,
    );

class SelectedStaffIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int staffId) {
    if (state.contains(staffId)) {
      state = {...state}..remove(staffId);
    } else {
      state = {...state, staffId};
    }
  }

  void selectAll(List<Staff> staff) {
    state = staff.map((s) => s.id).toSet();
  }

  void clear() {
    state = {};
  }

  void setFromList(List<int> ids) {
    state = ids.toSet();
  }
}

/// Provider che restituisce gli ID dello staff di turno per il giorno corrente.
final onDutyStaffIdsProvider = Provider<Set<int>>((ref) {
  final allStaff = ref.watch(staffForCurrentLocationProvider);
  final onDutyIds = <int>{};

  for (final staff in allStaff) {
    final availableSlots = ref.watch(staffSlotAvailabilityProvider(staff.id));
    // Staff è di turno se ha almeno uno slot disponibile nel giorno,
    // incluse eventuali eccezioni.
    if (availableSlots.isNotEmpty) {
      onDutyIds.add(staff.id);
    }
  }

  return onDutyIds;
});

/// Provider che restituisce lo staff filtrato in base alla modalità selezionata.
final filteredStaffProvider = Provider<List<Staff>>((ref) {
  final mode = ref.watch(staffFilterModeProvider);
  final allStaff = ref.watch(staffForCurrentLocationProvider);
  final selectedIds = ref.watch(selectedStaffIdsProvider);
  final onDutyIds = ref.watch(onDutyStaffIdsProvider);

  switch (mode) {
    case StaffFilterMode.allTeam:
      return allStaff;

    case StaffFilterMode.onDutyTeam:
      // Filtra solo lo staff che ha disponibilità per il giorno corrente
      return allStaff.where((s) => onDutyIds.contains(s.id)).toList();

    case StaffFilterMode.custom:
      return allStaff.where((s) => selectedIds.contains(s.id)).toList();
  }
});
