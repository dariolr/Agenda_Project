import '../domain/clients.dart';
import 'clients_api.dart';

class ClientsRepository {
  ClientsRepository({ClientsApi? api}) : _api = api ?? ClientsApi();

  final ClientsApi _api;

  Future<List<Client>> getAll() => _api.fetchClients();
  Future<Client> add(Client client) => _api.createClient(client);
  Future<Client> save(Client client) => _api.updateClient(client);
}
