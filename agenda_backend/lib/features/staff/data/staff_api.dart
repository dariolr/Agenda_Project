import '../../../core/models/staff.dart';
import '../../../core/network/api_client.dart';

/// API layer per Staff - chiamate reali a agenda_core
class StaffApi {
  final ApiClient _apiClient;

  StaffApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /v1/staff?location_id=X
  Future<List<Staff>> fetchStaff(int locationId) async {
    final data = await _apiClient.getStaff(locationId);
    final List<dynamic> items = data['staff'] ?? [];
    return items
        .map((json) => Staff.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
