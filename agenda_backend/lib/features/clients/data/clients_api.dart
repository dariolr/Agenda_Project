import '../../../core/models/appointment.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../domain/clients.dart';

/// Struttura per gli appuntamenti di un cliente divisi per tempo
class ClientAppointmentsData {
  final List<Appointment> upcoming;
  final List<Appointment> past;

  ClientAppointmentsData({required this.upcoming, required this.past});
}

/// Risposta paginata per la lista clienti
class ClientsPageResponse {
  final List<Client> clients;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  ClientsPageResponse({
    required this.clients,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });
}

/// API layer per Clients - chiamate reali a agenda_core
class ClientsApi {
  final ApiClient _apiClient;

  ClientsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /v1/clients?business_id=X[&limit=N][&offset=N][&search=term][&sort=name_asc]
  /// Supporta paginazione, ricerca e ordinamento lato server
  Future<ClientsPageResponse> fetchClients(
    int businessId, {
    int? limit,
    int? offset,
    String? search,
    String? sort,
  }) async {
    final data = await _apiClient.getClients(
      businessId,
      limit: limit,
      offset: offset,
      search: search,
      sort: sort,
    );
    final List<dynamic> items = data['clients'] ?? [];
    return ClientsPageResponse(
      clients: items.map((json) => _clientFromJson(json)).toList(),
      total: data['total'] as int? ?? items.length,
      limit: data['limit'] as int? ?? items.length,
      offset: data['offset'] as int? ?? 0,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  /// GET /v1/clients/{id}/appointments
  /// Carica tutti gli appuntamenti di un cliente, divisi in passati e futuri.
  Future<ClientAppointmentsData> fetchClientAppointments(int clientId) async {
    final data = await _apiClient.get(
      '${ApiConfig.clients}/$clientId/appointments',
    );

    final List<dynamic> upcomingJson = data['upcoming'] ?? [];
    final List<dynamic> pastJson = data['past'] ?? [];

    return ClientAppointmentsData(
      upcoming: upcomingJson.map((json) => _appointmentFromJson(json)).toList(),
      past: pastJson.map((json) => _appointmentFromJson(json)).toList(),
    );
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
  /// I campi nullable vengono sempre inviati per permettere la rimozione del valore
  Map<String, dynamic> _clientToJson(Client client) {
    return {
      'business_id': client.businessId,
      'first_name': client.firstName,
      'last_name': client.lastName,
      'email': client.email,
      'phone': client.phone,
      'gender': client.gender,
      'birth_date': client.birthDate?.toIso8601String().split('T')[0],
      'city': client.city,
      'notes': client.notes,
      'tags': client.tags,
      'is_archived': client.isArchived,
    };
  }

  /// Converte JSON snake_case in Appointment (per cronologia cliente)
  Appointment _appointmentFromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      businessId: 0, // Non disponibile dalla risposta API semplificata
      locationId: json['location_id'] as int,
      serviceId: json['service_id'] as int,
      serviceVariantId: (json['service_variant_id'] as int?) ?? 0,
      staffId: json['staff_id'] as int,
      clientId: null, // Non necessario nella cronologia
      clientName: '',
      serviceName: json['service_name'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      // `ClientsController::appointments` currently returns booking status as
      // `status` (booking-level), while other endpoints may use `booking_status`.
      bookingStatus:
          json['booking_status'] as String? ?? json['status'] as String?,
    );
  }
}
