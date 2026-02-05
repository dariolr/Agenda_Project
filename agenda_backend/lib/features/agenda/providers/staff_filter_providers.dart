import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';
import '../domain/staff_filter_mode.dart';
import 'business_providers.dart';
import 'staff_slot_availability_provider.dart';

/// Provider per la modalità di filtro staff corrente.
final staffFilterModeProvider =
    NotifierProvider<StaffFilterModeNotifier, StaffFilterMode>(
      StaffFilterModeNotifier.new,
    );

class StaffFilterModeNotifier extends Notifier<StaffFilterMode> {
  @override
  StaffFilterMode build() {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId <= 0) return StaffFilterMode.allTeam;

    // Carica da preferenze salvate
    final prefs = ref.watch(preferencesServiceProvider);
    final saved = prefs.getStaffFilterMode(businessId);
    if (saved != null) {
      return StaffFilterMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => StaffFilterMode.allTeam,
      );
    }
    return StaffFilterMode.allTeam;
  }

  void set(StaffFilterMode mode) {
    state = mode;
    // Salva in preferenze
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId > 0) {
      ref
          .read(preferencesServiceProvider)
          .setStaffFilterMode(businessId, mode.name);
    }
  }
}

/// Provider per gli ID degli staff selezionati manualmente.
final selectedStaffIdsProvider =
    NotifierProvider<SelectedStaffIdsNotifier, Set<int>>(
      SelectedStaffIdsNotifier.new,
    );

class SelectedStaffIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId <= 0) return {};

    // Carica da preferenze salvate
    final prefs = ref.watch(preferencesServiceProvider);
    final saved = prefs.getSelectedStaffIds(businessId);

    // Valida gli ID contro lo staff esistente nella location corrente
    final allStaff = ref.watch(staffForCurrentLocationProvider);
    final validIds = allStaff.map((s) => s.id).toSet();

    // Filtra solo gli ID che esistono ancora
    final validSavedIds = saved.where((id) => validIds.contains(id)).toSet();

    // Se c'erano ID salvati ma ora sono tutti invalidi, pulisci le preferenze
    if (saved.isNotEmpty && validSavedIds.isEmpty) {
      _saveAsync(businessId, {});
    }

    return validSavedIds;
  }

  void _save() {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId > 0) {
      ref
          .read(preferencesServiceProvider)
          .setSelectedStaffIds(businessId, state);
    }
  }

  // Versione async per cleanup
  void _saveAsync(int businessId, Set<int> ids) {
    ref.read(preferencesServiceProvider).setSelectedStaffIds(businessId, ids);
  }

  void toggle(int staffId) {
    if (state.contains(staffId)) {
      state = {...state}..remove(staffId);
    } else {
      state = {...state, staffId};
    }
    _save();
  }

  void selectAll(List<Staff> staff) {
    state = staff.map((s) => s.id).toSet();
    _save();
  }

  void clear() {
    state = {};
    _save();
  }

  void setFromList(List<int> ids) {
    state = ids.toSet();
    _save();
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
/// Se l'utente è ruolo staff, vede solo se stesso.
final filteredStaffProvider = Provider<List<Staff>>((ref) {
  final allStaff = ref.watch(staffForCurrentLocationProvider);

  // Se l'utente è ruolo staff, mostra solo se stesso
  final canViewAll = ref.watch(canViewAllAppointmentsProvider);
  final currentUserStaffId = ref.watch(currentUserStaffIdProvider);

  if (!canViewAll && currentUserStaffId != null) {
    return allStaff.where((s) => s.id == currentUserStaffId).toList();
  }

  // Altrimenti applica i filtri normali
  final mode = ref.watch(staffFilterModeProvider);
  final selectedIds = ref.watch(selectedStaffIdsProvider);
  final onDutyIds = ref.watch(onDutyStaffIdsProvider);

  switch (mode) {
    case StaffFilterMode.allTeam:
      return allStaff;

    case StaffFilterMode.onDutyTeam:
      // Restituisce solo lo staff di turno (anche lista vuota se nessuno è di turno)
      return allStaff.where((s) => onDutyIds.contains(s.id)).toList();

    case StaffFilterMode.custom:
      // Restituisce solo gli staff selezionati (anche lista vuota se nessuno selezionato)
      return allStaff.where((s) => selectedIds.contains(s.id)).toList();
  }
});
