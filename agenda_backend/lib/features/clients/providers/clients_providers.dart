import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../data/clients_api.dart';
import '../data/clients_repository.dart';
import '../domain/client_sort_option.dart';
import '../domain/clients.dart';

// Repository provider con ApiClient
final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientsRepository(apiClient: apiClient);
});

// ClientsApi provider
final clientsApiProvider = Provider<ClientsApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientsApi(apiClient: apiClient);
});

/// Stato per la lista clienti con paginazione
class ClientsState {
  final List<Client> clients;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSearching;
  final String searchQuery;
  final ClientSortOption sortOption;

  const ClientsState({
    this.clients = const [],
    this.total = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.sortOption = ClientSortOption.nameAsc,
  });

  ClientsState copyWith({
    List<Client>? clients,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSearching,
    String? searchQuery,
    ClientSortOption? sortOption,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

/// Limite di clienti per pagina
const int _kClientsPageSize = 100;

/// Converte ClientSortOption in stringa per API
String _sortOptionToApiString(ClientSortOption option) {
  return switch (option) {
    ClientSortOption.nameAsc => 'name_asc',
    ClientSortOption.nameDesc => 'name_desc',
    ClientSortOption.lastNameAsc => 'last_name_asc',
    ClientSortOption.lastNameDesc => 'last_name_desc',
    ClientSortOption.createdAtAsc => 'created_asc',
    ClientSortOption.createdAtDesc => 'created_desc',
  };
}

/// AsyncNotifier per caricare i clienti dall'API con paginazione, ricerca e ordinamento lato server
class ClientsNotifier extends AsyncNotifier<ClientsState> {
  Timer? _searchDebounce;

  @override
  Future<ClientsState> build() async {
    // Verifica autenticazione
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return const ClientsState();
    }

    final business = ref.watch(currentBusinessProvider);
    if (business.id <= 0) {
      return const ClientsState();
    }
    if (!ref.watch(currentUserCanManageClientsProvider)) {
      return const ClientsState();
    }

    final repository = ref.watch(clientsRepositoryProvider);
    final response = await repository.getPage(
      business.id,
      limit: _kClientsPageSize,
      offset: 0,
      sort: _sortOptionToApiString(ClientSortOption.nameAsc),
    );
    return ClientsState(
      clients: response.clients,
      total: response.total,
      hasMore: response.hasMore,
    );
  }

  /// Cambia l'ordinamento e ricarica i dati dal server
  Future<void> setSortOption(ClientSortOption option) async {
    final current = state.value;
    if (current == null) return;
    if (current.sortOption == option) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) return;
    if (!ref.read(currentUserCanManageClientsProvider)) {
      state = const AsyncValue.data(ClientsState());
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(clientsRepositoryProvider);
      final response = await repository.getPage(
        business.id,
        limit: _kClientsPageSize,
        offset: 0,
        search: current.searchQuery.isNotEmpty ? current.searchQuery : null,
        sort: _sortOptionToApiString(option),
      );
      return ClientsState(
        clients: response.clients,
        total: response.total,
        hasMore: response.hasMore,
        searchQuery: current.searchQuery,
        sortOption: option,
      );
    });
  }

  /// Imposta la query di ricerca e ricarica i dati dal server (con debounce)
  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  /// Esegue la ricerca immediatamente
  Future<void> _executeSearch(String query) async {
    final current = state.value;
    if (current == null) return;

    final trimmedQuery = query.trim();
    if (current.searchQuery == trimmedQuery) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) return;
    if (!ref.read(currentUserCanManageClientsProvider)) {
      state = const AsyncValue.data(ClientsState());
      return;
    }

    // Mantieni i dati visibili, mostra solo indicatore di ricerca
    state = AsyncValue.data(current.copyWith(isSearching: true));

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final response = await repository.getPage(
        business.id,
        limit: _kClientsPageSize,
        offset: 0,
        search: trimmedQuery.isNotEmpty ? trimmedQuery : null,
        sort: _sortOptionToApiString(current.sortOption),
      );
      state = AsyncValue.data(
        ClientsState(
          clients: response.clients,
          total: response.total,
          hasMore: response.hasMore,
          searchQuery: trimmedQuery,
          sortOption: current.sortOption,
          isSearching: false,
        ),
      );
    } catch (e) {
      // In caso di errore, mantieni i dati precedenti e mostra errore
      state = AsyncValue.data(current.copyWith(isSearching: false));
      // ignore: avoid_print
      print('Error searching clients: $e');
    }
  }

  /// Carica la prossima pagina di clienti
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) return;
    if (!ref.read(currentUserCanManageClientsProvider)) return;

    // Imposta loading state
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final response = await repository.getPage(
        business.id,
        limit: _kClientsPageSize,
        offset: current.clients.length,
        search: current.searchQuery.isNotEmpty ? current.searchQuery : null,
        sort: _sortOptionToApiString(current.sortOption),
      );

      state = AsyncValue.data(
        current.copyWith(
          clients: [...current.clients, ...response.clients],
          total: response.total,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      // ignore: avoid_print
      print('Error loading more clients: $e');
    }
  }

  /// Ricarica i clienti dall'API (mantiene filtri attuali)
  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) return;
    if (!ref.read(currentUserCanManageClientsProvider)) {
      state = const AsyncValue.data(ClientsState());
      return;
    }

    final current = state.value;
    final searchQuery = current?.searchQuery ?? '';
    final sortOption = current?.sortOption ?? ClientSortOption.nameAsc;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(clientsRepositoryProvider);
      final response = await repository.getPage(
        business.id,
        limit: _kClientsPageSize,
        offset: 0,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        sort: _sortOptionToApiString(sortOption),
      );
      return ClientsState(
        clients: response.clients,
        total: response.total,
        hasMore: response.hasMore,
        searchQuery: searchQuery,
        sortOption: sortOption,
      );
    });
  }

  /// Aggiunge un nuovo cliente via API e aggiorna lo state locale
  Future<Client> addClient(Client client) async {
    final repository = ref.read(clientsRepositoryProvider);
    final newClient = await repository.add(client);
    final current = state.value ?? const ClientsState();
    // Inserisci all'inizio della lista (sarà riordinato al prossimo refresh)
    state = AsyncValue.data(
      current.copyWith(
        clients: [newClient, ...current.clients],
        total: current.total + 1,
      ),
    );
    return newClient;
  }

  /// Aggiorna un cliente via API e aggiorna lo state locale
  Future<void> updateClient(Client client) async {
    final repository = ref.read(clientsRepositoryProvider);
    final updated = await repository.save(client);
    final current = state.value ?? const ClientsState();
    state = AsyncValue.data(
      current.copyWith(
        clients: [
          for (final c in current.clients)
            if (c.id == updated.id) updated else c,
        ],
      ),
    );
  }

  /// Soft delete - imposta isArchived = true
  Future<void> deleteClient(int id) async {
    final current = state.value?.clients.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Client not found'),
    );
    if (current == null) return;
    final archived = current.copyWith(isArchived: true);
    await updateClient(archived);
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, ClientsState>(
  ClientsNotifier.new,
);

/// Provider di convenienza che restituisce solo la lista clienti (per retrocompatibilità)
final clientsListProvider = Provider<List<Client>>((ref) {
  final asyncState = ref.watch(clientsProvider);
  return asyncState.value?.clients ?? [];
});

/// Provider che restituisce la lista clienti filtrata (già filtrata dal server)
/// I clienti archiviati sono già esclusi dal backend
final filteredClientsProvider = Provider<List<Client>>((ref) {
  return ref.watch(clientsListProvider).where((c) => !c.isArchived).toList();
});

// Indicizzazione rapida per id (restituisce mappa vuota se ancora in caricamento)
final clientsByIdProvider = Provider<Map<int, Client>>((ref) {
  final clients = ref.watch(clientsListProvider);
  return {for (final c in clients) c.id: c};
});

/// Provider per l'ordinamento corrente (legge dallo stato)
final clientSortOptionProvider = Provider<ClientSortOption>((ref) {
  final asyncState = ref.watch(clientsProvider);
  return asyncState.value?.sortOption ?? ClientSortOption.nameAsc;
});

/// Provider per la query di ricerca corrente (legge dallo stato)
final clientSearchQueryProvider = Provider<String>((ref) {
  final asyncState = ref.watch(clientsProvider);
  return asyncState.value?.searchQuery ?? '';
});

/// Provider che restituisce il conteggio totale dei clienti (non archiviati)
/// Usa il totale dal server, non la lista locale
final totalClientsCountProvider = Provider<int>((ref) {
  final asyncState = ref.watch(clientsProvider);
  return asyncState.value?.total ?? 0;
});

// Segmenti
const _kInactiveDays = 90;
const _kNewDays = 45;
const _kFrequentThreshold = 10; // placeholder (in futuro basato su bookings)

DateTime _now() => DateTime.now();

final inactiveClientsProvider = Provider<List<Client>>((ref) {
  final limit = _now().subtract(const Duration(days: _kInactiveDays));
  final allClients = ref.watch(clientsListProvider);
  return allClients
      .where(
        (c) =>
            !c.isArchived &&
            (c.lastVisit == null || c.lastVisit!.isBefore(limit)),
      )
      .toList();
});

final newClientsProvider = Provider<List<Client>>((ref) {
  final limit = _now().subtract(const Duration(days: _kNewDays));
  final allClients = ref.watch(clientsListProvider);
  return allClients
      .where((c) => !c.isArchived && c.createdAt.isAfter(limit))
      .toList();
});

final vipClientsProvider = Provider<List<Client>>((ref) {
  final allClients = ref.watch(clientsListProvider);
  return allClients
      .where((c) => !c.isArchived && (c.tags?.contains('VIP') ?? false))
      .toList();
});

final frequentClientsProvider = Provider<List<Client>>((ref) {
  final allClients = ref.watch(clientsListProvider);
  // Placeholder: usa loyaltyPoints come proxy delle visite
  return allClients
      .where(
        (c) => !c.isArchived && (c.loyaltyPoints ?? 0) >= _kFrequentThreshold,
      )
      .toList();
});

/// Forza il refresh degli appuntamenti cliente quando si entra in sezione.
class ClientAppointmentsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final clientAppointmentsRefreshProvider =
    NotifierProvider<ClientAppointmentsRefreshNotifier, int>(
      ClientAppointmentsRefreshNotifier.new,
    );

// Provider per caricare appuntamenti di un cliente dall'API.
// Ritorna ClientAppointmentsData con liste upcoming e past già ordinate.
final clientAppointmentsProvider =
    FutureProvider.family<ClientAppointmentsData, int>((ref, clientId) async {
      ref.watch(clientAppointmentsRefreshProvider);
      final api = ref.watch(clientsApiProvider);
      return api.fetchClientAppointments(clientId);
    });

// Provider di convenienza che unisce upcoming + past in una lista singola
// (usato da bookingIdsByClientProvider per retrocompatibilità)
final clientWithAppointmentsProvider = Provider.family<List<Appointment>, int>((
  ref,
  clientId,
) {
  final asyncData = ref.watch(clientAppointmentsProvider(clientId));
  final data = asyncData.value;
  if (data == null) return [];
  return [...data.upcoming, ...data.past];
});

final bookingIdsByClientProvider = Provider.family<Set<int>, int>((
  ref,
  clientId,
) {
  final appointments = ref.watch(clientWithAppointmentsProvider(clientId));
  return appointments.map((a) => a.bookingId).toSet();
});

// ---------------------------------------------------------------------------
// CLIENT PICKER SEARCH PROVIDER
// Provider dedicato per la ricerca clienti nel picker di appuntamenti/prenotazioni.
// Esegue la ricerca lato server per gestire correttamente grandi volumi di clienti.
// ---------------------------------------------------------------------------

/// Limite di clienti per la ricerca nel picker
const int _kPickerSearchLimit = 50;

/// Stato della ricerca clienti nel picker
class ClientPickerSearchState {
  final List<Client> clients;
  final bool isLoading;
  final String searchQuery;
  final String? error;

  const ClientPickerSearchState({
    this.clients = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
  });

  ClientPickerSearchState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? searchQuery,
    String? error,
  }) {
    return ClientPickerSearchState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

/// Notifier per la ricerca clienti nel picker con debounce
/// Usa autoDispose per resettarsi quando il picker viene chiuso
class ClientPickerSearchNotifier extends Notifier<ClientPickerSearchState> {
  Timer? _searchDebounce;

  @override
  ClientPickerSearchState build() {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });
    // Carica i primi clienti all'apertura (senza filtro)
    _loadInitialClients();
    return const ClientPickerSearchState(isLoading: true);
  }

  /// Carica i primi clienti senza filtro all'apertura del picker
  Future<void> _loadInitialClients() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = const ClientPickerSearchState();
      return;
    }

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) {
      state = const ClientPickerSearchState();
      return;
    }
    if (!ref.read(currentUserCanManageClientsProvider)) {
      state = const ClientPickerSearchState();
      return;
    }

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final response = await repository.getPage(
        business.id,
        limit: _kPickerSearchLimit,
        offset: 0,
        sort: 'name_asc',
      );
      state = ClientPickerSearchState(
        clients: response.clients.where((c) => !c.isArchived).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = ClientPickerSearchState(isLoading: false, error: e.toString());
    }
  }

  /// Imposta la query di ricerca con debounce
  void setSearchQuery(String query) {
    final trimmed = query.trim();

    // Aggiorna subito lo stato visuale della query
    state = state.copyWith(searchQuery: trimmed);

    // Cancella il debounce precedente
    _searchDebounce?.cancel();

    // Se query vuota, ricarica i clienti iniziali
    if (trimmed.isEmpty) {
      state = state.copyWith(isLoading: true);
      _loadInitialClients();
      return;
    }

    // Debounce per evitare troppe chiamate durante la digitazione
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(trimmed);
    });
  }

  /// Esegue la ricerca lato server
  Future<void> _executeSearch(String query) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final business = ref.read(currentBusinessProvider);
    if (business.id <= 0) return;
    if (!ref.read(currentUserCanManageClientsProvider)) {
      state = const ClientPickerSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final response = await repository.getPage(
        business.id,
        limit: _kPickerSearchLimit,
        offset: 0,
        search: query,
        sort: 'name_asc',
      );
      state = ClientPickerSearchState(
        clients: response.clients.where((c) => !c.isArchived).toList(),
        isLoading: false,
        searchQuery: query,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Forza un refresh della ricerca corrente
  Future<void> refresh() async {
    final query = state.searchQuery;
    if (query.isEmpty) {
      state = state.copyWith(isLoading: true);
      await _loadInitialClients();
    } else {
      await _executeSearch(query);
    }
  }
}

/// Provider per la ricerca clienti nel picker (autoDispose si resetta alla chiusura)
final clientPickerSearchProvider =
    NotifierProvider.autoDispose<
      ClientPickerSearchNotifier,
      ClientPickerSearchState
    >(ClientPickerSearchNotifier.new);
