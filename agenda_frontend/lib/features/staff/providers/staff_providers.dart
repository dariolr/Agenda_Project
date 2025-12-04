import 'package:agenda_frontend/features/agenda/providers/business_providers.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';

final allStaffProvider = Provider<List<Staff>>((ref) {
  final business = ref.watch(currentBusinessProvider);
  return [
    Staff(
      id: 1,
      businessId: business.id,
      name: 'Dario',
      surname: 'La Rosa',
      color: Colors.green,
      locationIds: const [101],
    ),
    Staff(
      id: 2,
      businessId: business.id,
      name: 'Luca',
      surname: 'Bianchi',
      color: Colors.cyan,
      locationIds: const [102],
    ),
    Staff(
      id: 3,
      businessId: business.id,
      name: 'Sara',
      surname: 'Verdi',
      color: Colors.orange,
      locationIds: const [101, 102],
    ),
    Staff(
      id: 4,
      businessId: business.id,
      name: 'Alessia',
      surname: 'Neri',
      color: Colors.pinkAccent,
      locationIds: const [101],
    ),
  ];
});

final staffForCurrentLocationProvider = Provider<List<Staff>>((ref) {
  final location = ref.watch(currentLocationProvider);
  final staff = ref.watch(allStaffProvider);
  return [
    for (final member in staff)
      if (member.worksAtLocation(location.id)) member,
  ];
});

/// Holds the staffId that should be pre-selected when navigating to
/// the single-staff availability edit screen. Cleared after consumption.
final initialStaffToEditProvider = Provider<ValueNotifier<int?>>((ref) {
  final vn = ValueNotifier<int?>(null);
  ref.onDispose(vn.dispose);
  return vn;
});
