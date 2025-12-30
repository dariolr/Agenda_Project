import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';
import 'staff_repository_provider.dart';

class StaffNotifier extends AsyncNotifier<List<Staff>> {
  @override
  Future<List<Staff>> build() async {
    final repository = ref.watch(staffRepositoryProvider);
    final locations = ref.watch(locationsProvider);

    // ⚠️ Non fare chiamate API se le locations non sono ancora caricate
    if (locations.isEmpty) {
      return [];
    }

    final location = ref.watch(currentLocationProvider);

    try {
      return await repository.getByLocation(location.id);
    } catch (e) {
      // In caso di errore (es. 404), ritorna lista vuota senza riprovare
      debugPrint('⚠️ StaffNotifier: errore caricamento staff: $e');
      return [];
    }
  }

  void add(Staff staff) {
    final current = state.value ?? [];
    state = AsyncData([...current, staff]);
  }

  void updateStaff(Staff updated) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final s in current)
        if (s.id == updated.id) updated else s,
    ]);
  }

  void delete(int id) {
    final current = state.value ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }

  void duplicate(Staff original) {
    final current = state.value ?? [];
    final newId = _nextId(current);
    final existingNames = current.map((s) => s.displayName).toSet();
    var base = original.displayName;
    var candidate = '$base Copia';
    var i = 1;
    while (existingNames.contains(candidate)) {
      candidate = '$base Copia $i';
      i++;
    }
    final parts = candidate.split(' ');
    final name = parts.first;
    final surname = parts.length > 1
        ? parts.sublist(1).join(' ')
        : original.surname;
    add(original.copyWith(id: newId, name: name, surname: surname));
  }

  int nextId() => _nextId(state.value ?? []);

  int nextSortOrderForLocations(Iterable<int> locationIds) {
    final current = state.value ?? [];
    if (current.isEmpty) return 0;
    final ids = locationIds.toSet();
    final relevant = ids.isEmpty
        ? current
        : current.where((s) => s.locationIds.any(ids.contains));
    if (relevant.isEmpty) return 0;
    return relevant.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  void reorderForLocation(int locationId, int oldIndex, int newIndex) {
    final current = state.value ?? [];
    final inLocation =
        current.where((s) => s.worksAtLocation(locationId)).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (newIndex > oldIndex) newIndex -= 1;
    final item = inLocation.removeAt(oldIndex);
    inLocation.insert(newIndex, item);

    final updated = <Staff>[];
    for (int i = 0; i < inLocation.length; i++) {
      updated.add(inLocation[i].copyWith(sortOrder: i));
    }

    final updatedAll = [
      for (final s in current)
        if (s.worksAtLocation(locationId))
          updated.firstWhere((u) => u.id == s.id)
        else
          s,
    ];

    state = AsyncData(updatedAll);
  }

  int _nextId(List<Staff> current) {
    if (current.isEmpty) return 1;
    final maxId = current.map((s) => s.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}

final allStaffProvider = AsyncNotifierProvider<StaffNotifier, List<Staff>>(
  StaffNotifier.new,
);

List<Staff> _sortStaff(List<Staff> staff) {
  final list = [...staff];
  list.sort((a, b) {
    final so = a.sortOrder.compareTo(b.sortOrder);
    return so != 0 ? so : a.displayName.compareTo(b.displayName);
  });
  return list;
}

final sortedAllStaffProvider = Provider<List<Staff>>((ref) {
  final staffAsync = ref.watch(allStaffProvider);
  return _sortStaff(staffAsync.value ?? []);
});

final staffForCurrentLocationProvider = Provider<List<Staff>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final staffAsync = ref.watch(allStaffProvider);
  final staff = staffAsync.value ?? [];
  return _sortStaff([
    for (final member in staff)
      if (member.worksAtLocation(location.id)) member,
  ]);
});

// ──────────────────────────────────────────────
// 🏢 Location provider separato per la sezione Staff
// null = "Tutte le sedi" (default)
// ──────────────────────────────────────────────

class StaffSectionLocationNotifier extends Notifier<int?> {
  @override
  int? build() => null; // Default: tutte le sedi

  void set(int? locationId) => state = locationId;

  void setAll() => state = null;
}

final staffSectionLocationIdProvider =
    NotifierProvider<StaffSectionLocationNotifier, int?>(
      StaffSectionLocationNotifier.new,
    );

/// Staff filtrato per la location selezionata nella sezione Staff.
/// Se locationId è null (tutte le sedi), restituisce tutti gli staff.
final staffForStaffSectionProvider = Provider<List<Staff>>((ref) {
  final locationId = ref.watch(staffSectionLocationIdProvider);
  final staffAsync = ref.watch(allStaffProvider);
  final staff = staffAsync.value ?? [];

  if (locationId == null) {
    // Tutte le sedi: restituisci tutti gli staff
    return _sortStaff(staff);
  }

  return _sortStaff([
    for (final member in staff)
      if (member.worksAtLocation(locationId)) member,
  ]);
});

/// Holds the staffId that should be pre-selected when navigating to
/// the single-staff availability edit screen. Cleared after consumption.
final initialStaffToEditProvider = Provider<ValueNotifier<int?>>((ref) {
  final vn = ValueNotifier<int?>(null);
  ref.onDispose(vn.dispose);
  return vn;
});
