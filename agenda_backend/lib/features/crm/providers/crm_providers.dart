import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../data/crm_repository.dart';
import '../domain/crm_models.dart';

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CrmRepository(apiClient: apiClient);
});

class CrmClientsState {
  final List<CrmClient> clients;
  final bool hasMore;
  final bool loadingMore;
  final String searchQuery;
  final String statusFilter;
  final String sort;
  final int page;
  final int total;

  const CrmClientsState({
    this.clients = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.searchQuery = '',
    this.statusFilter = '',
    this.sort = 'last_visit_desc',
    this.page = 1,
    this.total = 0,
  });

  CrmClientsState copyWith({
    List<CrmClient>? clients,
    bool? hasMore,
    bool? loadingMore,
    String? searchQuery,
    String? statusFilter,
    String? sort,
    int? page,
    int? total,
  }) {
    return CrmClientsState(
      clients: clients ?? this.clients,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class CrmClientsNotifier extends AsyncNotifier<CrmClientsState> {
  Timer? _debounce;

  @override
  Future<CrmClientsState> build() async {
    final business = ref.watch(currentBusinessProvider);
    final canManage = ref.watch(currentUserCanManageClientsProvider);
    if (!canManage || business.id <= 0) {
      return const CrmClientsState();
    }

    final repo = ref.watch(crmRepositoryProvider);
    final page = await repo.getClients(business.id, page: 1, pageSize: 30);
    return CrmClientsState(
      clients: page.clients,
      hasMore: page.hasMore,
      total: page.total,
    );
  }

  Future<void> refresh() async {
    final current = state.value ?? const CrmClientsState();
    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(crmRepositoryProvider);
      final page = await repo.getClients(
        business.id,
        q: current.searchQuery,
        status: current.statusFilter.isEmpty ? null : current.statusFilter,
        sort: current.sort,
        page: 1,
        pageSize: 30,
      );
      return current.copyWith(
        clients: page.clients,
        hasMore: page.hasMore,
        total: page.total,
        page: 1,
      );
    });
  }

  void setSearch(String query) {
    final current = state.value ?? const CrmClientsState();
    state = AsyncValue.data(current.copyWith(searchQuery: query));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });
  }

  Future<void> setStatusFilter(String status) async {
    final current = state.value ?? const CrmClientsState();
    state = AsyncValue.data(current.copyWith(statusFilter: status));
    await refresh();
  }

  Future<void> setSort(String sort) async {
    final current = state.value ?? const CrmClientsState();
    state = AsyncValue.data(current.copyWith(sort: sort));
    await refresh();
  }

  Future<void> loadMore() async {
    final current = state.value;
    final business = ref.read(currentBusinessProvider);
    if (current == null || !current.hasMore || current.loadingMore || business.id <= 0) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));

    try {
      final repo = ref.read(crmRepositoryProvider);
      final nextPage = current.page + 1;
      final page = await repo.getClients(
        business.id,
        q: current.searchQuery,
        status: current.statusFilter.isEmpty ? null : current.statusFilter,
        sort: current.sort,
        page: nextPage,
        pageSize: 30,
      );

      state = AsyncValue.data(
        current.copyWith(
          loadingMore: false,
          clients: [...current.clients, ...page.clients],
          hasMore: page.hasMore,
          page: nextPage,
          total: page.total,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final crmClientsProvider = AsyncNotifierProvider<CrmClientsNotifier, CrmClientsState>(
  CrmClientsNotifier.new,
);

final clientDetailProvider = FutureProvider.family<CrmClient, int>((ref, clientId) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) throw Exception('Business not selected');
  return ref.watch(crmRepositoryProvider).getClientDetail(businessId, clientId);
});

final clientEventsProvider = FutureProvider.family<List<CrmEvent>, int>((ref, clientId) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  return ref.watch(crmRepositoryProvider).getClientEvents(businessId, clientId);
});

final clientTasksProvider = FutureProvider.family<List<CrmTask>, int>((ref, clientId) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  return ref.watch(crmRepositoryProvider).getClientTasks(businessId, clientId);
});

final clientTagsProvider = FutureProvider<List<CrmTag>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  return ref.watch(crmRepositoryProvider).getTags(businessId);
});

final overdueTasksProvider = FutureProvider<List<CrmTask>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  final clients = ref.watch(crmClientsProvider).value?.clients ?? const <CrmClient>[];
  if (clients.isEmpty) return const [];
  final tasks = await ref.watch(crmRepositoryProvider).getClientTasksForAll(businessId, clients);
  return tasks.where((t) => t.isOverdue).toList();
});

class ClientUpsertController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(Map<String, dynamic> payload, {int? clientId}) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).upsertClient(businessId, payload, clientId: clientId);
      ref.invalidate(crmClientsProvider);
    });
  }
}

final clientUpsertControllerProvider =
    AsyncNotifierProvider<ClientUpsertController, void>(ClientUpsertController.new);

class ClientMergeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> merge(int sourceClientId, int targetClientId) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).mergeClient(businessId, sourceClientId, targetClientId);
      ref.invalidate(crmClientsProvider);
    });
  }
}

final clientMergeControllerProvider =
    AsyncNotifierProvider<ClientMergeController, void>(ClientMergeController.new);

class ClientTaskController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(int clientId, Map<String, dynamic> payload) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).createTask(businessId, clientId, payload);
      ref.invalidate(clientTasksProvider(clientId));
      ref.invalidate(overdueTasksProvider);
    });
  }

  Future<void> complete(int clientId, int taskId) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).completeTask(businessId, clientId, taskId);
      ref.invalidate(clientTasksProvider(clientId));
      ref.invalidate(overdueTasksProvider);
    });
  }

  Future<void> reopen(int clientId, int taskId) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).reopenTask(businessId, clientId, taskId);
      ref.invalidate(clientTasksProvider(clientId));
      ref.invalidate(overdueTasksProvider);
    });
  }
}

final clientTaskControllerProvider =
    AsyncNotifierProvider<ClientTaskController, void>(ClientTaskController.new);

class ClientTagController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(String name, {String? color}) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).createTag(businessId, name, color: color);
      ref.invalidate(clientTagsProvider);
    });
  }

  Future<void> delete(int tagId, {bool force = false}) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(crmRepositoryProvider).deleteTag(businessId, tagId, force: force);
      ref.invalidate(clientTagsProvider);
      ref.invalidate(crmClientsProvider);
    });
  }
}

final clientTagControllerProvider =
    AsyncNotifierProvider<ClientTagController, void>(ClientTagController.new);

class ClientConsentController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(int clientId, Map<String, dynamic> payload) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(apiClientProvider).put(
            '/v1/businesses/$businessId/clients/$clientId/consents',
            data: payload,
          );
      ref.invalidate(clientDetailProvider(clientId));
    });
  }
}

final clientConsentControllerProvider =
    AsyncNotifierProvider<ClientConsentController, void>(ClientConsentController.new);

class ClientImportController extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<void> preview({required String csv, required Map<String, dynamic> mapping}) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(crmRepositoryProvider).importCsv(
            businessId,
            csv: csv,
            mapping: mapping,
            dryRun: true,
          ),
    );
  }

  Future<void> commit({required String csv, required Map<String, dynamic> mapping}) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(crmRepositoryProvider).importCsv(
            businessId,
            csv: csv,
            mapping: mapping,
            dryRun: false,
          );
      ref.invalidate(crmClientsProvider);
      return result;
    });
  }
}

final clientImportControllerProvider =
    AsyncNotifierProvider<ClientImportController, Map<String, dynamic>?>(ClientImportController.new);

final crmSegmentsProvider = FutureProvider<List<CrmSegment>>((ref) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];
  return ref.watch(crmRepositoryProvider).getSegments(businessId);
});
