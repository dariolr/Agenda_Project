import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/clients.dart';

/// API layer per Clients - chiamate reali a agenda_core
class ClientsApi {
  final ApiClient _apiClient;

  ClientsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /v1/clients?business_id=X
  Future<List<Client>> fetchClients(int businessId) async {
    final data = await _apiClient.getClients(businessId);
    final List<dynamic> items = data['clients'] ?? [];
    return items.map((json) => _clientFromJson(json)).toList();
  }

  /// POST /v1/clients
  Future<Client> createClient(Client client) async {
    final data = await _apiClient.post(
      ApiConfig.clients,
      data: _clientToJson(client),
    );
    return _clientFromJson(data);
  }

  /// PUT /v1/clients/{id}
  Future<Client> updateClient(Client client) async {
    final data = await _apiClient.put(
      '${ApiConfig.clients}/${client.id}',
      data: _clientToJson(client),
    );
    return _clientFromJson(data);
  }

  /// DELETE /v1/clients/{id}
  Future<void> deleteClient(int clientId) async {
    await _apiClient.delete('${ApiConfig.clients}/$clientId');
  }

  /// Converte JSON snake_case in Client
  Client _clientFromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      city: json['city'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastVisit: json['last_visit'] != null
          ? DateTime.parse(json['last_visit'] as String)
          : null,
      loyaltyPoints: json['loyalty_points'] as int?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  /// Converte Client in JSON snake_case
  Map<String, dynamic> _clientToJson(Client client) {
    return {
      'business_id': client.businessId,
      if (client.firstName != null) 'first_name': client.firstName,
      if (client.lastName != null) 'last_name': client.lastName,
      if (client.email != null) 'email': client.email,
      if (client.phone != null) 'phone': client.phone,
      if (client.gender != null) 'gender': client.gender,
      if (client.birthDate != null)
        'birth_date': client.birthDate!.toIso8601String().split('T')[0],
      if (client.city != null) 'city': client.city,
      if (client.notes != null) 'notes': client.notes,
      if (client.tags != null) 'tags': client.tags,
      'is_archived': client.isArchived,
    };
  }
}
