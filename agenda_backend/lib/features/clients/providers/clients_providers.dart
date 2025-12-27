import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/appointment_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../data/clients_repository.dart';
import '../domain/client_sort_option.dart';
import '../domain/clients.dart';

// Repository provider con ApiClient
final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientsRepository(apiClient: apiClient);
});

/// AsyncNotifier per caricare i clienti dall'API
class ClientsNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() async {
    final repository = ref.watch(clientsRepositoryProvider);
    final business = ref.watch(currentBusinessProvider);
    return repository.getAll(business.id);
  }

  /// Ricarica i clienti dall'API
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(clientsRepositoryProvider);
      final business = ref.read(currentBusinessProvider);
      return repository.getAll(business.id);
    });
  }

  /// Aggiunge un nuovo cliente via API e aggiorna lo state locale
  Future<Client> addClient(Client client) async {
    final repository = ref.read(clientsRepositoryProvider);
    final newClient = await repository.add(client);
    state = AsyncValue.data([...state.value ?? [], newClient]);
    return newClient;
  }

  /// Aggiorna un cliente via API e aggiorna lo state locale
  Future<void> updateClient(Client client) async {
    final repository = ref.read(clientsRepositoryProvider);
    final updated = await repository.save(client);
    state = AsyncValue.data([
      for (final c in state.value ?? [])
        if (c.id == updated.id) updated else c,
    ]);
  }

  /// Soft delete - imposta isArchived = true
  Future<void> deleteClient(int id) async {
    final current = state.value?.firstWhere((c) => c.id == id);
    if (current == null) return;
    final archived = current.copyWith(isArchived: true);
    await updateClient(archived);
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, List<Client>>(
  ClientsNotifier.new,
);

// Indicizzazione rapida per id (restituisce mappa vuota se ancora in caricamento)
final clientsByIdProvider = Provider<Map<int, Client>>((ref) {
  final asyncClients = ref.watch(clientsProvider);
  final list = asyncClients.value ?? [];
  return {for (final c in list) c.id: c};
});

/// Notifier per il criterio di ordinamento corrente
class ClientSortOptionNotifier extends Notifier<ClientSortOption> {
  @override
  ClientSortOption build() => ClientSortOption.nameAsc;

  void set(ClientSortOption option) => state = option;
}

final clientSortOptionProvider =
    NotifierProvider<ClientSortOptionNotifier, ClientSortOption>(
      ClientSortOptionNotifier.new,
    );

/// Ordina una lista di clienti secondo il criterio specificato
List<Client> _sortClients(List<Client> clients, ClientSortOption sort) {
  final sorted = List<Client>.from(clients);

  switch (sort) {
    case ClientSortOption.nameAsc:
      sorted.sort(
        (a, b) => (a.firstName ?? '').toLowerCase().compareTo(
          (b.firstName ?? '').toLowerCase(),
        ),
      );
    case ClientSortOption.nameDesc:
      sorted.sort(
        (a, b) => (b.firstName ?? '').toLowerCase().compareTo(
          (a.firstName ?? '').toLowerCase(),
        ),
      );
    case ClientSortOption.lastNameAsc:
      sorted.sort(
        (a, b) => (a.lastName ?? '').toLowerCase().compareTo(
          (b.lastName ?? '').toLowerCase(),
        ),
      );
    case ClientSortOption.lastNameDesc:
      sorted.sort(
        (a, b) => (b.lastName ?? '').toLowerCase().compareTo(
          (a.lastName ?? '').toLowerCase(),
        ),
      );
    case ClientSortOption.lastVisitDesc:
      sorted.sort((a, b) {
        if (a.lastVisit == null && b.lastVisit == null) return 0;
        if (a.lastVisit == null) return 1;
        if (b.lastVisit == null) return -1;
        return b.lastVisit!.compareTo(a.lastVisit!);
      });
    case ClientSortOption.lastVisitAsc:
      sorted.sort((a, b) {
        if (a.lastVisit == null && b.lastVisit == null) return 0;
        if (a.lastVisit == null) return 1;
        if (b.lastVisit == null) return -1;
        return a.lastVisit!.compareTo(b.lastVisit!);
      });
    case ClientSortOption.createdAtDesc:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case ClientSortOption.createdAtAsc:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  return sorted;
}

/// Provider che restituisce la lista clienti ordinata secondo il criterio corrente
/// Esclude i clienti archiviati (isArchived = true)
final sortedClientsProvider = Provider<List<Client>>((ref) {
  final asyncClients = ref.watch(clientsProvider);
  final clients = (asyncClients.value ?? [])
      .where((c) => !c.isArchived)
      .toList();
  final sortOption = ref.watch(clientSortOptionProvider);
  return _sortClients(clients, sortOption);
});

// Ricerca base (case-insensitive su name + email + phone) con ordinamento
// Esclude i clienti archiviati (isArchived = true)
final clientsSearchProvider = Provider.family<List<Client>, String>((ref, q) {
  final sortOption = ref.watch(clientSortOptionProvider);
  final query = q.trim().toLowerCase();
  final asyncClients = ref.watch(clientsProvider);
  final allClients = asyncClients.value ?? [];

  List<Client> result;
  if (query.isEmpty) {
    result = allClients.where((c) => !c.isArchived).toList();
  } else {
    result = allClients
        .where(
          (c) =>
              !c.isArchived &&
              (c.name.toLowerCase().contains(query) ||
                  (c.email?.toLowerCase().contains(query) ?? false) ||
                  (c.phone?.toLowerCase().contains(query) ?? false)),
        )
        .toList();
  }

  return _sortClients(result, sortOption);
});

// Segmenti
const _kInactiveDays = 90;
const _kNewDays = 45;
const _kFrequentThreshold = 10; // placeholder (in futuro basato su bookings)

DateTime _now() => DateTime.now();

final inactiveClientsProvider = Provider<List<Client>>((ref) {
  final limit = _now().subtract(const Duration(days: _kInactiveDays));
  final asyncClients = ref.watch(clientsProvider);
  return (asyncClients.value ?? [])
      .where(
        (c) =>
            !c.isArchived &&
            (c.lastVisit == null || c.lastVisit!.isBefore(limit)),
      )
      .toList();
});

final newClientsProvider = Provider<List<Client>>((ref) {
  final limit = _now().subtract(const Duration(days: _kNewDays));
  final asyncClients = ref.watch(clientsProvider);
  return (asyncClients.value ?? [])
      .where((c) => !c.isArchived && c.createdAt.isAfter(limit))
      .toList();
});

final vipClientsProvider = Provider<List<Client>>((ref) {
  final asyncClients = ref.watch(clientsProvider);
  return (asyncClients.value ?? [])
      .where((c) => !c.isArchived && (c.tags?.contains('VIP') ?? false))
      .toList();
});

final frequentClientsProvider = Provider<List<Client>>((ref) {
  final asyncClients = ref.watch(clientsProvider);
  // Placeholder: usa loyaltyPoints come proxy delle visite
  return (asyncClients.value ?? [])
      .where(
        (c) => !c.isArchived && (c.loyaltyPoints ?? 0) >= _kFrequentThreshold,
      )
      .toList();
});

// Collegamenti Booking <-> Client (stub per futura integrazione bookings reali)
final clientWithAppointmentsProvider = Provider.family<List<Appointment>, int>((
  ref,
  clientId,
) {
  final all = ref.watch(appointmentsProvider).value ?? [];
  return all.where((a) => a.clientId == clientId).toList();
});

final bookingIdsByClientProvider = Provider.family<Set<int>, int>((
  ref,
  clientId,
) {
  final appointments = ref.watch(clientWithAppointmentsProvider(clientId));
  return appointments.map((a) => a.bookingId).toSet();
});
