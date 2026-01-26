import '../../../core/models/location.dart';
import '../../../core/network/api_client.dart';

class LocationsRepository {
  LocationsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Location>> getByBusinessId(int businessId) async {
    final data = await _apiClient.getLocations(businessId);
    return data.map((json) => Location.fromJson(json)).toList();
  }

  Future<Location> create({
    required int businessId,
    required String name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    bool? isActive,
  }) async {
    final data = await _apiClient.createLocation(
      businessId: businessId,
      name: name,
      address: address,
      phone: phone,
      email: email,
      timezone: timezone,
      minBookingNoticeHours: minBookingNoticeHours,
      maxBookingAdvanceDays: maxBookingAdvanceDays,
      allowCustomerChooseStaff: allowCustomerChooseStaff,
      isActive: isActive,
    );
    return Location.fromJson(data);
  }

  Future<Location> update({
    required int locationId,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    int? slotIntervalMinutes,
    String? slotDisplayMode,
    int? minGapMinutes,
    bool? isActive,
  }) async {
    final data = await _apiClient.updateLocation(
      locationId: locationId,
      name: name,
      address: address,
      phone: phone,
      email: email,
      timezone: timezone,
      minBookingNoticeHours: minBookingNoticeHours,
      maxBookingAdvanceDays: maxBookingAdvanceDays,
      allowCustomerChooseStaff: allowCustomerChooseStaff,
      slotIntervalMinutes: slotIntervalMinutes,
      slotDisplayMode: slotDisplayMode,
      minGapMinutes: minGapMinutes,
      isActive: isActive,
    );
    return Location.fromJson(data);
  }

  Future<void> delete(int locationId) async {
    await _apiClient.deleteLocation(locationId);
  }
}
