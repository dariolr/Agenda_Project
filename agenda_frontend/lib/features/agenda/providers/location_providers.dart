import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import 'business_providers.dart';

final locationsProvider = Provider<List<Location>>((ref) {
  final business = ref.watch(currentBusinessProvider);
  // Mock location data per business
  return [
    Location(
      id: 101,
      businessId: business.id,
      name: 'Roma Centro',
      address: 'Via Appia 10, Roma',
      timezone: 'Europe/Rome',
    ),
    Location(
      id: 102,
      businessId: business.id,
      name: 'Milano Brera',
      address: 'Via Solferino 45, Milano',
      timezone: 'Europe/Rome',
    ),
  ];
});

class CurrentLocationId extends Notifier<int> {
  @override
  int build() {
    final locations = ref.read(locationsProvider);
    return locations.first.id;
  }

  void set(int id) => state = id;
}

final currentLocationIdProvider =
    NotifierProvider<CurrentLocationId, int>(CurrentLocationId.new);

final currentLocationProvider = Provider<Location>((ref) {
  final locations = ref.watch(locationsProvider);
  final currentId = ref.watch(currentLocationIdProvider);
  return locations.firstWhere((loc) => loc.id == currentId);
});
