import '../../../core/models/service.dart';
import '../../../core/network/api_client.dart';

/// API layer per Services - chiamate reali a agenda_core
class ServicesApi {
  final ApiClient _apiClient;

  ServicesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /v1/services?location_id=X
  Future<List<Service>> fetchServices(int locationId) async {
    final data = await _apiClient.getServices(locationId);
    final List<dynamic> items = data['services'] ?? [];
    return items
        .map((json) => Service.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
