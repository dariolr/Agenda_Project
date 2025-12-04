import '../domain/clients.dart';

/// Mock iniziale per sviluppo UI/Provider
final List<Client> kMockClients = [
  Client(
    id: 1,
    businessId: 1,
    firstName: 'Mario',
    lastName: 'Rossi',
    email: 'mario.rossi@example.com',
    phone: '+39 333 1111111',
    city: 'Milano',
    notes: 'Cliente abituale, preferisce mattina',
    createdAt: DateTime.now().subtract(const Duration(days: 200)),
    lastVisit: DateTime.now().subtract(const Duration(days: 7)),
    loyaltyPoints: 120,
    tags: const ['VIP'],
  ),
  Client(
    id: 2,
    businessId: 1,
    firstName: 'Giulia',
    lastName: 'Bianchi',
    email: 'giulia.bianchi@example.com',
    phone: '+39 333 2222222',
    city: 'Torino',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    lastVisit: DateTime.now().subtract(const Duration(days: 40)),
    loyaltyPoints: 20,
    tags: const ['Nuovo'],
  ),
  Client(
    id: 3,
    businessId: 1,
    firstName: 'Luca',
    lastName: 'Verdi',
    phone: '+39 333 3333333',
    createdAt: DateTime.now().subtract(const Duration(days: 400)),
    lastVisit: DateTime.now().subtract(const Duration(days: 190)),
    loyaltyPoints: 5,
    tags: const ['Inattivo'],
  ),
];
