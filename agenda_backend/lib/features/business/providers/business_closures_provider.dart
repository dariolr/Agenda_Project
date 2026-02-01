import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/business_closure.dart';
import '/core/network/network_providers.dart';
import '/features/agenda/providers/location_providers.dart';

/// Provider per gestire le chiusure dell'attività
final businessClosuresProvider =
    AsyncNotifierProvider<BusinessClosuresNotifier, List<BusinessClosure>>(
      BusinessClosuresNotifier.new,
    );

class BusinessClosuresNotifier extends AsyncNotifier<List<BusinessClosure>> {
  @override
  Future<List<BusinessClosure>> build() async {
    return _loadClosures();
  }

  Future<List<BusinessClosure>> _loadClosures() async {
    final businessId = ref.read(businessIdForLocationsProvider);
    if (businessId == null) {
      return [];
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final closures = await apiClient.getBusinessClosures(businessId);
      return closures;
    } catch (e) {
      // Se errore, ritorna lista vuota
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadClosures());
  }

  Future<void> addClosure({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final businessId = ref.read(businessIdForLocationsProvider);
    if (businessId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final closure = await apiClient.createBusinessClosure(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    state = state.whenData((closures) {
      final newList = [...closures, closure];
      // Ordina per data inizio
      newList.sort((a, b) => a.startDate.compareTo(b.startDate));
      return newList;
    });
  }

  Future<void> updateClosure({
    required int closureId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final updated = await apiClient.updateBusinessClosure(
      closureId: closureId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    state = state.whenData((closures) {
      return closures.map((c) => c.id == closureId ? updated : c).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
    });
  }

  Future<void> deleteClosure(int closureId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteBusinessClosure(closureId);

    state = state.whenData((closures) {
      return closures.where((c) => c.id != closureId).toList();
    });
  }
}

/// Provider derivato: chiusure future (a partire da oggi)
final futureClosuresProvider = Provider<AsyncValue<List<BusinessClosure>>>((
  ref,
) {
  final closuresAsync = ref.watch(businessClosuresProvider);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);

  return closuresAsync.whenData((closures) {
    return closures.where((c) {
      // Include se la data fine è >= oggi
      return !c.endDate.isBefore(todayOnly);
    }).toList();
  });
});

/// Provider derivato: chiusure passate (terminate prima di oggi)
final pastClosuresProvider = Provider<AsyncValue<List<BusinessClosure>>>((ref) {
  final closuresAsync = ref.watch(businessClosuresProvider);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);

  return closuresAsync.whenData((closures) {
    return closures.where((c) {
      return c.endDate.isBefore(todayOnly);
    }).toList();
  });
});

/// Provider per controllare se una data specifica è un giorno di chiusura
final isDateClosedProvider = Provider.family<bool, DateTime>((ref, date) {
  final closuresAsync = ref.watch(businessClosuresProvider);
  final dateOnly = DateTime(date.year, date.month, date.day);

  return closuresAsync.maybeWhen(
    data: (closures) {
      return closures.any((c) => c.containsDate(dateOnly));
    },
    orElse: () => false,
  );
});
