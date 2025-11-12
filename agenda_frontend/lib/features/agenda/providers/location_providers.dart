import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/location.dart';
import '../../agenda/providers/business_providers.dart';

///
/// 🔹 ELENCO LOCATIONS (mock statiche)
///
final locationsProvider = Provider<List<Location>>((ref) {
  final business = ref.watch(currentBusinessProvider);
  return [
    Location(
      id: 101,
      businessId: business.id,
      name: 'Sede Centrale',
      address: 'Via Roma 12',
      city: 'Roma',
      region: 'Lazio',
      country: 'Italia',
      phone: '+39 06 1234567',
      email: 'roma@azienda.it',
      latitude: 41.9028,
      longitude: 12.4964,
      currency: 'EUR', // 🔹 Valuta locale per la sede
      isDefault: true, // ✅ aggiunto per default
    ),
    Location(
      id: 102,
      businessId: business.id,
      name: 'Filiale Estera',
      address: 'Main Street 22',
      city: 'Lugano',
      region: 'TI',
      country: 'Svizzera',
      phone: '+41 91 654321',
      email: 'lugano@azienda.ch',
      latitude: 46.0037,
      longitude: 8.9511,
      currency: 'CHF', // 🔹 Valuta diversa (franchi svizzeri)
      isDefault: false,
    ),
  ];
});

///
/// 🔹 LOCATION CORRENTE
///
class CurrentLocationId extends Notifier<int> {
  @override
  int build() {
    final locations = ref.read(locationsProvider);
    return locations
        .firstWhere((l) => l.isDefault, orElse: () => locations.first)
        .id;
  }

  void set(int id) => state = id;
}

final currentLocationIdProvider = NotifierProvider<CurrentLocationId, int>(
  CurrentLocationId.new,
);

final currentLocationProvider = Provider<Location>((ref) {
  final locations = ref.watch(locationsProvider);
  final currentId = ref.watch(currentLocationIdProvider);
  return locations.firstWhere((l) => l.id == currentId);
});

///
/// 🔹 VALUTA EFFETTIVA DELLA LOCATION CORRENTE
///
/// Se la location ha una valuta specifica, viene usata.
/// Altrimenti eredita quella del business.
///
final effectiveCurrencyProvider = Provider<String>((ref) {
  final location = ref.watch(currentLocationProvider);
  final business = ref.watch(currentBusinessProvider);
  return location.currency ?? business.currency;
});
