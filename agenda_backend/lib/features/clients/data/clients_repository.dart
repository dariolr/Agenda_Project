import '../../../core/network/api_client.dart';
import '../domain/clients.dart';
import 'clients_api.dart';

class ClientsRepository {
  ClientsRepository({required ApiClient apiClient})
    : _api = ClientsApi(apiClient: apiClient);

  final ClientsApi _api;

  /// Carica clienti con paginazione, ricerca e ordinamento
  Future<ClientsPageResponse> getPage(
    int businessId, {
    int? limit,
    int? offset,
    String? search,
    String? sort,
  }) => _api.fetchClients(
    businessId,
    limit: limit,
    offset: offset,
    search: search,
    sort: sort,
  );

  /// Carica tutti i clienti (senza limite)
  Future<List<Client>> getAll(int businessId) async {
    final response = await _api.fetchClients(businessId, limit: 10000);
    return response.clients;
  }

  Future<Client> add(Client client) => _api.createClient(client);
  Future<Client> save(Client client) => _api.updateClient(client);
  Future<void> delete(int clientId) => _api.deleteClient(clientId);
}
