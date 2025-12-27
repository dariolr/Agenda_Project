import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/business.dart';
import '../../business/providers/business_providers.dart';

///
/// 🔹 ELENCO BUSINESS (da API)
///
final businessesProvider = FutureProvider<List<Business>>((ref) async {
  final repository = ref.watch(businessRepositoryProvider);
  return repository.getAll();
});

///
/// 🔹 BUSINESS CORRENTE (ID)
///
class CurrentBusinessId extends Notifier<int> {
  @override
  int build() {
    // ✅ Imposta come default il primo business disponibile
    // Aspetta che businessesProvider carichi i dati
    ref.listen(businessesProvider, (previous, next) {
      next.whenData((businesses) {
        if (businesses.isNotEmpty && state == 0) {
          state = businesses.first.id;
        }
      });
    });
    return 1; // Default temporaneo
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
  final businessesAsync = ref.watch(businessesProvider);
  final currentId = ref.watch(currentBusinessIdProvider);

  return businessesAsync.when(
    data: (businesses) => businesses.firstWhere(
      (b) => b.id == currentId,
      orElse: () => businesses.first,
    ),
    loading: () =>
        Business(id: currentId, name: 'Loading...', createdAt: DateTime.now()),
    error: (_, __) =>
        Business(id: currentId, name: 'Error', createdAt: DateTime.now()),
  );
});
