import '../../../core/models/location.dart';
import '../../../core/network/api_client.dart';

class LocationsRepository {
  LocationsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Location>> getByBusinessId(int businessId) async {
    final data = await _apiClient.getLocations(businessId);
    return data.map((json) => Location.fromJson(json)).toList();
  }
}
