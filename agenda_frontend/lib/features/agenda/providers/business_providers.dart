import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/business.dart';

final businessesProvider = Provider<List<Business>>((ref) {
  return [
    Business(
      id: 1,
      name: 'Centro Massaggi La Rosa',
      createdAt: DateTime(2021, 3, 12),
    ),
  ];
});

class CurrentBusinessId extends Notifier<int> {
  @override
  int build() {
    final businesses = ref.read(businessesProvider);
    return businesses.first.id;
  }

  void set(int id) => state = id;
}

final currentBusinessIdProvider =
    NotifierProvider<CurrentBusinessId, int>(CurrentBusinessId.new);

final currentBusinessProvider = Provider<Business>((ref) {
  final businesses = ref.watch(businessesProvider);
  final currentId = ref.watch(currentBusinessIdProvider);
  return businesses.firstWhere((b) => b.id == currentId);
});
