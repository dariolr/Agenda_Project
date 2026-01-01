import '../../../core/models/service.dart';
import '../../../core/network/api_client.dart';
import 'services_api.dart';

class ServicesRepository {
  ServicesRepository({required ApiClient apiClient})
    : _api = ServicesApi(apiClient: apiClient);

  final ServicesApi _api;

  /// Carica servizi e categorie dall'API
  Future<ServicesApiResult> getServicesWithCategories({
    required int locationId,
  }) => _api.fetchServicesWithCategories(locationId);

  /// Carica solo i servizi (legacy)
  Future<List<Service>> getServices({required int locationId}) =>
      _api.fetchServices(locationId);
}
