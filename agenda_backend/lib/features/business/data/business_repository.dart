import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';

class BusinessRepository {
  BusinessRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Business>> getAll() async {
    final data = await _apiClient.getBusinesses();
    return data.map((json) => Business.fromJson(json)).toList();
  }
}
