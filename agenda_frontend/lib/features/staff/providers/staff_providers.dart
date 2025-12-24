import 'package:agenda_frontend/features/agenda/providers/business_providers.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';

class StaffNotifier extends Notifier<List<Staff>> {
  @override
  List<Staff> build() {
    final business = ref.watch(currentBusinessProvider);
    return [
      Staff(
        id: 1,
        businessId: business.id,
        name: 'Dario',
        surname: 'La Rosa',
        color: Colors.green,
        locationIds: const [101],
        sortOrder: 0,
      ),
      Staff(
        id: 2,
        businessId: business.id,
        name: 'Luca',
        surname: 'Bianchi',
        color: Colors.cyan,
        locationIds: const [102],
        sortOrder: 1,
      ),
      Staff(
        id: 3,
        businessId: business.id,
        name: 'Sara',
        surname: 'Verdi',
        color: Colors.orange,
        locationIds: const [101, 102],
        sortOrder: 2,
      ),
      Staff(
        id: 4,
        businessId: business.id,
        name: 'Alessia',
        surname: 'Neri',
        color: Colors.pinkAccent,
        locationIds: const [101],
        sortOrder: 3,
      ),
    ];
  }

  void add(Staff staff) {
    state = [...state, staff];
  }

  void update(Staff updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
  }

  void delete(int id) {
    state = state.where((s) => s.id != id).toList();
  }

  void duplicate(Staff original) {
    final newId = _nextId();
    final existingNames = state.map((s) => s.displayName).toSet();
    var base = original.displayName;
    var candidate = '$base Copia';
    var i = 1;
    while (existingNames.contains(candidate)) {
      candidate = '$base Copia $i';
      i++;
    }
    final parts = candidate.split(' ');
    final name = parts.first;
    final surname =
        parts.length > 1 ? parts.sublist(1).join(' ') : original.surname;
    add(
      original.copyWith(
        id: newId,
        name: name,
        surname: surname,
      ),
    );
  }

  int nextId() => _nextId();

  int nextSortOrderForLocations(Iterable<int> locationIds) {
    if (state.isEmpty) return 0;
    final ids = locationIds.toSet();
    final relevant = ids.isEmpty
        ? state
        : state.where((s) => s.locationIds.any(ids.contains));
    final base = relevant.isEmpty ? state : relevant;
    final maxSort = base
        .map((s) => s.sortOrder)
        .reduce((a, b) => a > b ? a : b);
    return maxSort + 1;
  }

  void reorderForLocation(int locationId, int oldIndex, int newIndex) {
    final inLocation = state
        .where((s) => s.worksAtLocation(locationId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (newIndex > oldIndex) newIndex -= 1;
    final item = inLocation.removeAt(oldIndex);
    inLocation.insert(newIndex, item);

    final updated = <Staff>[];
    for (int i = 0; i < inLocation.length; i++) {
      updated.add(inLocation[i].copyWith(sortOrder: i));
    }

    final updatedAll = [
      for (final s in state)
        if (s.worksAtLocation(locationId))
          updated.firstWhere((u) => u.id == s.id)
        else
          s,
    ];

    state = updatedAll;
  }

  int _nextId() {
    if (state.isEmpty) return 1;
    final maxId = state.map((s) => s.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}

final allStaffProvider = NotifierProvider<StaffNotifier, List<Staff>>(
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
  final staff = ref.watch(allStaffProvider);
  return _sortStaff(staff);
});

final staffForCurrentLocationProvider = Provider<List<Staff>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final staff = ref.watch(allStaffProvider);
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
  final staff = ref.watch(allStaffProvider);

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
