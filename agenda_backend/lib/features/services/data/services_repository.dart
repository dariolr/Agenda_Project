import '../../../core/models/service.dart';
import '../../../core/network/api_client.dart';
import 'services_api.dart';

class ServicesRepository {
  ServicesRepository({required ApiClient apiClient})
    : _api = ServicesApi(apiClient: apiClient);

  final ServicesApi _api;

  Future<List<Service>> getServices({required int locationId}) =>
      _api.fetchServices(locationId);
}
