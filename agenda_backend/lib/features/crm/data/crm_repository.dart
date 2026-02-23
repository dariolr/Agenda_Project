import '../../../core/network/api_client.dart';
import '../domain/crm_models.dart';

class CrmRepository {
  final ApiClient _api;

  CrmRepository({required ApiClient apiClient}) : _api = apiClient;

  String _base(int businessId) => '/v1/businesses/$businessId';

  Future<CrmClientsPage> getClients(
    int businessId, {
    String? q,
    String? status,
    String? sort,
    int page = 1,
    int pageSize = 20,
    bool? isArchived,
  }) async {
    final data = await _api.get(
      '${_base(businessId)}/clients',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (isArchived != null) 'is_archived': isArchived,
        'page': page,
        'page_size': pageSize,
      },
    );

    final items = (data['clients'] as List? ?? const []).whereType<Map>().cast<Map<String, dynamic>>();
    return CrmClientsPage(
      clients: items.map(CrmClient.fromJson).toList(),
      total: (data['total'] as num?)?.toInt() ?? items.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      pageSize: (data['page_size'] as num?)?.toInt() ?? pageSize,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  Future<CrmClient> getClientDetail(int businessId, int clientId) async {
    final data = await _api.get('${_base(businessId)}/clients/$clientId');
    return CrmClient.fromJson(data);
  }

  Future<void> upsertClient(int businessId, Map<String, dynamic> payload, {int? clientId}) async {
    if (clientId == null) {
      await _api.post('${_base(businessId)}/clients', data: payload);
    } else {
      await _api.patch('${_base(businessId)}/clients/$clientId', data: payload);
    }
  }

  Future<void> archiveClient(int businessId, int clientId, bool archive) async {
    final suffix = archive ? 'archive' : 'unarchive';
    await _api.post('${_base(businessId)}/clients/$clientId/$suffix');
  }

  Future<List<CrmTag>> getTags(int businessId) async {
    final data = await _api.get('${_base(businessId)}/client-tags');
    final items = (data['tags'] as List? ?? const []).whereType<Map>().cast<Map<String, dynamic>>();
    return items.map(CrmTag.fromJson).toList();
  }

  Future<void> createTag(int businessId, String name, {String? color}) async {
    await _api.post('${_base(businessId)}/client-tags', data: {'name': name, if (color != null) 'color': color});
  }

  Future<void> deleteTag(int businessId, int tagId, {bool force = false}) async {
    await _api.delete('${_base(businessId)}/client-tags/$tagId${force ? '?force=true' : ''}');
  }

  Future<void> replaceClientTags(int businessId, int clientId, List<int> tagIds) async {
    await _api.put('${_base(businessId)}/clients/$clientId/tags', data: {'tag_ids': tagIds});
  }

  Future<List<CrmTask>> getClientTasks(int businessId, int clientId) async {
    final data = await _api.get('${_base(businessId)}/clients/$clientId/tasks');
    final items = (data['tasks'] as List? ?? const []).whereType<Map>().cast<Map<String, dynamic>>();
    return items.map(CrmTask.fromJson).toList();
  }

  Future<List<CrmTask>> getClientTasksForAll(int businessId, List<CrmClient> clients) async {
    final all = <CrmTask>[];
    for (final client in clients) {
      all.addAll(await getClientTasks(businessId, client.id));
    }
    return all;
  }

  Future<void> createTask(int businessId, int clientId, Map<String, dynamic> payload) async {
    await _api.post('${_base(businessId)}/clients/$clientId/tasks', data: payload);
  }

  Future<void> patchTask(int businessId, int clientId, int taskId, Map<String, dynamic> payload) async {
    await _api.patch('${_base(businessId)}/clients/$clientId/tasks/$taskId', data: payload);
  }

  Future<void> completeTask(int businessId, int clientId, int taskId) async {
    await _api.post('${_base(businessId)}/clients/$clientId/tasks/$taskId/complete');
  }

  Future<void> reopenTask(int businessId, int clientId, int taskId) async {
    await _api.post('${_base(businessId)}/clients/$clientId/tasks/$taskId/reopen');
  }

  Future<List<CrmEvent>> getClientEvents(int businessId, int clientId, {int page = 1}) async {
    final data = await _api.get(
      '${_base(businessId)}/clients/$clientId/events',
      queryParameters: {'page': page, 'page_size': 30},
    );
    final items = (data['events'] as List? ?? const []).whereType<Map>().cast<Map<String, dynamic>>();
    return items.map(CrmEvent.fromJson).toList();
  }

  Future<List<CrmSegment>> getSegments(int businessId) async {
    final data = await _api.get('${_base(businessId)}/client-segments');
    final items = (data['segments'] as List? ?? const []).whereType<Map>().cast<Map<String, dynamic>>();
    return items.map(CrmSegment.fromJson).toList();
  }

  Future<void> createSegment(int businessId, String name, Map<String, dynamic> filters) async {
    await _api.post('${_base(businessId)}/client-segments', data: {'name': name, 'filters': filters});
  }

  Future<void> updateSegment(int businessId, int segmentId, String name, Map<String, dynamic> filters) async {
    await _api.patch('${_base(businessId)}/client-segments/$segmentId', data: {'name': name, 'filters': filters});
  }

  Future<void> deleteSegment(int businessId, int segmentId) async {
    await _api.delete('${_base(businessId)}/client-segments/$segmentId');
  }

  Future<Map<String, dynamic>> dedupSuggestions(int businessId, String query) async {
    return _api.get('${_base(businessId)}/clients/dedup/suggestions', queryParameters: {'q': query});
  }

  Future<void> mergeClient(int businessId, int sourceClientId, int targetClientId) async {
    await _api.post('${_base(businessId)}/clients/$sourceClientId/merge-into/$targetClientId');
  }

  Future<Map<String, dynamic>> importCsv(
    int businessId, {
    required String csv,
    required Map<String, dynamic> mapping,
    required bool dryRun,
  }) {
    return _api.post('${_base(businessId)}/clients/import/csv', data: {
      'csv': csv,
      'mapping': mapping,
      'dry_run': dryRun,
    });
  }

  Future<Map<String, dynamic>> exportCsv(int businessId, {int? segmentId}) {
    return _api.get(
      '${_base(businessId)}/clients/export/csv',
      queryParameters: {if (segmentId != null) 'segment_id': segmentId},
    );
  }

  Future<Map<String, dynamic>> gdprExport(int businessId, int clientId) {
    return _api.post('${_base(businessId)}/clients/$clientId/gdpr/export');
  }

  Future<void> gdprDelete(int businessId, int clientId) async {
    await _api.post('${_base(businessId)}/clients/$clientId/gdpr/delete');
  }
}
