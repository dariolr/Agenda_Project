import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/business.dart';

///
/// 🔹 ELENCO BUSINESS (mock statico)
///
final businessesProvider = Provider<List<Business>>((ref) {
  return [
    Business(
      id: 1,
      name: 'Centro Massaggi La Rosa',
      createdAt: DateTime(2021, 3, 12),
      currency: 'EUR',
      defaultPhonePrefix: '+39',
    ),
    Business(
      id: 2,
      name: 'Wellness Global Spa',
      createdAt: DateTime(2022, 1, 20),
      currency: 'USD',
      defaultPhonePrefix: '+1',
    ),
  ];
});

///
/// 🔹 BUSINESS CORRENTE (ID)
///
class CurrentBusinessId extends Notifier<int> {
  @override
  int build() {
    final businesses = ref.read(businessesProvider);
    // ✅ Imposta come default il primo business disponibile
    return businesses.first.id;
  }

  void set(int id) => state = id;
}

final currentBusinessIdProvider = NotifierProvider<CurrentBusinessId, int>(
  CurrentBusinessId.new,
);

///
/// 🔹 BUSINESS CORRENTE (oggetto)
///
final currentBusinessProvider = Provider<Business>((ref) {
  final businesses = ref.watch(businessesProvider);
  final currentId = ref.watch(currentBusinessIdProvider);
  return businesses.firstWhere((b) => b.id == currentId);
});
