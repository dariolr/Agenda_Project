import '../../../core/models/staff.dart';
import '../../../core/network/api_client.dart';
import 'staff_api.dart';

class StaffRepository {
  StaffRepository({required ApiClient apiClient})
    : _api = StaffApi(apiClient: apiClient);

  final StaffApi _api;

  Future<List<Staff>> getByLocation(int locationId) =>
      _api.fetchStaff(locationId);
}
