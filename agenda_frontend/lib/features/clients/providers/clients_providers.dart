import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../agenda/providers/appointment_providers.dart';
import '../data/clients_repository.dart';
import '../data/mock_clients.dart';
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

  void addClient(Client client) {
    state = [
      ...state,
      client.copyWith(id: _nextId++, createdAt: DateTime.now()),
    ];
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

// Ricerca base (case-insensitive su name + email + phone)
final clientsSearchProvider = Provider.family<List<Client>, String>((ref, q) {
  final query = q.trim().toLowerCase();
  if (query.isEmpty) return ref.watch(clientsProvider);
  return ref
      .watch(clientsProvider)
      .where(
        (c) =>
            c.name.toLowerCase().contains(query) ||
            (c.email?.toLowerCase().contains(query) ?? false) ||
            (c.phone?.toLowerCase().contains(query) ?? false),
      )
      .toList();
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
      .where((c) => (c.lastVisit == null || c.lastVisit!.isBefore(limit)))
      .toList();
});

final newClientsProvider = Provider<List<Client>>((ref) {
  final limit = _now().subtract(const Duration(days: _kNewDays));
  return ref
      .watch(clientsProvider)
      .where((c) => c.createdAt.isAfter(limit))
      .toList();
});

final vipClientsProvider = Provider<List<Client>>((ref) {
  return ref
      .watch(clientsProvider)
      .where((c) => c.tags?.contains('VIP') ?? false)
      .toList();
});

final frequentClientsProvider = Provider<List<Client>>((ref) {
  // Placeholder: usa loyaltyPoints come proxy delle visite
  return ref
      .watch(clientsProvider)
      .where((c) => (c.loyaltyPoints ?? 0) >= _kFrequentThreshold)
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
