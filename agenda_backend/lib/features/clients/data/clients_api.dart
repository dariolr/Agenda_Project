import '../domain/clients.dart';
import 'mock_clients.dart';

/// API layer (mock) - in futuro integrerà chiamate HTTP.
class ClientsApi {
  Future<List<Client>> fetchClients() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return kMockClients;
  }

  Future<Client> createClient(Client client) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return client; // mock echo
  }

  Future<Client> updateClient(Client client) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return client; // mock echo
  }
}
