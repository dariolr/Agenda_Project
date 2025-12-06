import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../agenda/providers/appointment_providers.dart';
import '../data/clients_repository.dart';
import '../data/mock_clients.dart';
import '../domain/client_sort_option.dart';
import '../domain/clients.dart';

// Repository provider (mock)
final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository();
});

/// Notifier principale che mantiene la lista clienti.
class ClientsNotifier extends Notifier<List<Client>> {
  int _nextId = 1000;

  @override
  List<Client> build() {
    // Stato iniziale mock
    return kMockClients;
  }

  /// Aggiunge un nuovo cliente e restituisce il client con l'ID assegnato.
  Client addClient(Client client) {
    final newClient = client.copyWith(id: _nextId++, createdAt: DateTime.now());
    state = [...state, newClient];
    return newClient;
  }

  void updateClient(Client client) {
    state = [
      for (final c in state)
        if (c.id == client.id) client else c,
    ];
  }

  void deleteClient(int id) {
    // Soft delete -> isArchived
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(isArchived: true) else c,
    ];
  }
}

final clientsProvider = NotifierProvider<ClientsNotifier, List<Client>>(
  ClientsNotifier.new,
);

// Indicizzazione rapida per id
final clientsByIdProvider = Provider<Map<int, Client>>((ref) {
  final list = ref.watch(clientsProvider);
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
  final clients = ref
      .watch(clientsProvider)
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

  List<Client> result;
  if (query.isEmpty) {
    result = ref.watch(clientsProvider).where((c) => !c.isArchived).toList();
  } else {
    result = ref
        .watch(clientsProvider)
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
  return ref
      .watch(clientsProvider)
      .where(
        (c) =>
            !c.isArchived &&
            (c.lastVisit == null || c.lastVisit!.isBefore(limit)),
      )
      .toList();
});

final newClientsProvider = Provider<List<Client>>((ref) {
  final limit = _now().subtract(const Duration(days: _kNewDays));
  return ref
      .watch(clientsProvider)
      .where((c) => !c.isArchived && c.createdAt.isAfter(limit))
      .toList();
});

final vipClientsProvider = Provider<List<Client>>((ref) {
  return ref
      .watch(clientsProvider)
      .where((c) => !c.isArchived && (c.tags?.contains('VIP') ?? false))
      .toList();
});

final frequentClientsProvider = Provider<List<Client>>((ref) {
  // Placeholder: usa loyaltyPoints come proxy delle visite
  return ref
      .watch(clientsProvider)
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
  final all = ref.watch(appointmentsProvider);
  return all.where((a) => a.clientId == clientId).toList();
});

final bookingIdsByClientProvider = Provider.family<Set<int>, int>((
  ref,
  clientId,
) {
  final appointments = ref.watch(clientWithAppointmentsProvider(clientId));
  return appointments.map((a) => a.bookingId).toSet();
});
