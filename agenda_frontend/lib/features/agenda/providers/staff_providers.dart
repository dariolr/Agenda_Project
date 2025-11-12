import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';
import 'business_providers.dart';
import 'location_providers.dart';

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
    Staff(
      id: 5,
      businessId: business.id,
      name: 'Luisa',
      surname: 'Gialli',
      color: Colors.purpleAccent,
      locationIds: const [102],
    ),
    Staff(
      id: 6,
      businessId: business.id,
      name: 'Marco',
      surname: 'Rossi',
      color: Colors.lime,
      locationIds: const [101],
    ),
    Staff(
      id: 7,
      businessId: business.id,
      name: 'Elena',
      surname: 'Fontana',
      color: Colors.indigo,
      locationIds: const [101],
    ),
    Staff(
      id: 8,
      businessId: business.id,
      name: 'Giorgio',
      surname: 'Ferrari',
      color: Colors.teal,
      locationIds: const [102],
    ),
    Staff(
      id: 9,
      businessId: business.id,
      name: 'Clara',
      surname: 'Almeida',
      color: Colors.deepOrange,
      locationIds: const [102],
    ),
    Staff(
      id: 10,
      businessId: business.id,
      name: 'Michele',
      surname: 'Berti',
      color: Colors.blueGrey,
      locationIds: const [101, 102],
    ),
    Staff(
      id: 11,
      businessId: business.id,
      name: 'Giulia',
      surname: 'Sala',
      color: Colors.lightGreen,
      locationIds: const [101, 102],
    ),
    Staff(
      id: 12,
      businessId: business.id,
      name: 'Matteo',
      surname: 'Corsi',
      color: Colors.deepPurple,
      locationIds: const [101, 102],
    ),
    Staff(
      id: 13,
      businessId: business.id,
      name: 'Chiara',
      surname: 'Rinaldi',
      color: Colors.amber,
      locationIds: const [101, 102],
    ),
    Staff(
      id: 14,
      businessId: business.id,
      name: 'Federico',
      surname: 'Gatti',
      color: Colors.tealAccent,
      locationIds: const [101, 102],
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
