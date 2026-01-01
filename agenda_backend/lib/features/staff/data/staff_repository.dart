import '../../../core/models/staff.dart';
import '../../../core/network/api_client.dart';
import 'staff_api.dart';

class StaffRepository {
  StaffRepository({required ApiClient apiClient})
    : _apiClient = apiClient,
      _api = StaffApi(apiClient: apiClient);

  final ApiClient _apiClient;
  final StaffApi _api;

  Future<List<Staff>> getByLocation(int locationId) =>
      _api.fetchStaff(locationId);

  Future<List<Staff>> getByBusiness(int businessId) async {
    final data = await _apiClient.getStaffByBusiness(businessId);
    return data.map((json) => Staff.fromJson(json)).toList();
  }

  Future<Staff> create({
    required int businessId,
    required String name,
    String? surname,
    String? colorHex,
    String? avatarUrl,
    bool? isBookableOnline,
    List<int>? locationIds,
  }) async {
    final data = await _apiClient.createStaff(
      businessId: businessId,
      name: name,
      surname: surname,
      colorHex: colorHex,
      avatarUrl: avatarUrl,
      isBookableOnline: isBookableOnline,
      locationIds: locationIds,
    );
    return Staff.fromJson(data);
  }

  Future<Staff> update({
    required int staffId,
    String? name,
    String? surname,
    String? colorHex,
    String? avatarUrl,
    bool? isBookableOnline,
    int? sortOrder,
    List<int>? locationIds,
  }) async {
    final data = await _apiClient.updateStaff(
      staffId: staffId,
      name: name,
      surname: surname,
      colorHex: colorHex,
      avatarUrl: avatarUrl,
      isBookableOnline: isBookableOnline,
      sortOrder: sortOrder,
      locationIds: locationIds,
    );
    return Staff.fromJson(data);
  }

  Future<void> delete(int staffId) async {
    await _apiClient.deleteStaff(staffId);
  }
}
