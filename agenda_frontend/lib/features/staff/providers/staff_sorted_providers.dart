import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../../core/models/staff.dart';
import '../../agenda/providers/location_providers.dart';
import 'staff_providers.dart';

final sortedLocationsProvider = Provider<List<Location>>((ref) {
  // usa l'ordine della lista nello stato
  return [...ref.watch(locationsProvider)];
});

final staffByLocationProvider = Provider.family<List<Staff>, int>((
  ref,
  locationId,
) {
  final staff = ref.watch(allStaffProvider);
  final list = [
    for (final s in staff)
      if (s.worksAtLocation(locationId)) s,
  ];
  list.sort((a, b) {
    final so = a.sortOrder.compareTo(b.sortOrder);
    return so != 0 ? so : a.displayName.compareTo(b.displayName);
  });
  return list;
});
