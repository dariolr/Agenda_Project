import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../agenda/providers/business_providers.dart';
import 'services_provider.dart';
import 'services_repository_provider.dart';

/// Notifier per la gestione delle categorie di servizi (CRUD via API)
/// Le categorie vengono inizializzate vuote e popolate dal ServicesNotifier
/// quando i dati vengono caricati dall'API.
class ServiceCategoriesNotifier extends Notifier<List<ServiceCategory>> {
  @override
  List<ServiceCategory> build() {
    // Inizia vuoto - le categorie vengono caricate dall'API insieme ai servizi
    return [];
  }

  /// Imposta le categorie caricate dall'API
  void setCategories(List<ServiceCategory> categories) {
    state = _sorted(categories);
  }

  List<ServiceCategory> _sorted(List<ServiceCategory> list) {
    final copy = [...list];
    copy.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  // ===== API METHODS =====

  /// Creates a new category via API and updates local state
  Future<ServiceCategory?> createCategoryApi({
    required String name,
    String? description,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    final businessId = ref.read(currentBusinessIdProvider);

    if (businessId <= 0) return null;

    try {
      final newCategory = await repository.createCategory(
        businessId: businessId,
        name: name,
        description: description,
      );

      // Add to local state with high sort order (will be bumped if empty)
      final nextSort = state.isEmpty
          ? 0
          : (state.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
      final withOrder = newCategory.copyWith(sortOrder: nextSort);
      state = _sorted([...state, withOrder]);

      bumpEmptyCategoriesToEnd();

      return newCategory;
    } catch (e) {
      return null;
    }
  }

  /// Updates a category via API and updates local state
  Future<ServiceCategory?> updateCategoryApi({
    required int categoryId,
    String? name,
    String? description,
    int? sortOrder,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);

    try {
      final updatedCategory = await repository.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        sortOrder: sortOrder,
      );

      // Update local state
      state = _sorted([
        for (final c in state)
          if (c.id == updatedCategory.id) updatedCategory else c,
      ]);

      return updatedCategory;
    } catch (e) {
      return null;
    }
  }

  /// Deletes a category via API and updates local state
  Future<bool> deleteCategoryApi(int categoryId) async {
    final repository = ref.read(servicesRepositoryProvider);

    try {
      await repository.deleteCategory(categoryId);

      // Remove from local state
      state = _sorted(state.where((c) => c.id != categoryId).toList());

      return true;
    } catch (e) {
      return false;
    }
  }

  // ===== LOCAL METHODS (legacy, for backward compatibility) =====

  @Deprecated('Use createCategoryApi instead for persistence')
  void addCategory(ServiceCategory newCategory) {
    final nextSort = state.isEmpty
        ? 0
        : (state.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
    final withOrder = newCategory.copyWith(sortOrder: nextSort);
    state = _sorted([...state, withOrder]);
    bumpEmptyCategoriesToEnd();
  }

  @Deprecated('Use updateCategoryApi instead for persistence')
  void updateCategory(ServiceCategory updatedCategory) {
    state = _sorted([
      for (final c in state)
        if (c.id == updatedCategory.id) updatedCategory else c,
    ]);
  }

  @Deprecated('Use deleteCategoryApi instead for persistence')
  void deleteCategory(int id) {
    state = _sorted(state.where((c) => c.id != id).toList());
  }

  /// Imposta un sortOrder elevato per le categorie senza servizi,
  /// in modo che siano naturalmente in coda all'ordinamento.
  ///
  /// Per evitare dipendenze circolari quando chiamata da ServicesNotifier,
  /// si può passare la lista servizi già aggiornata tramite [servicesOverride].
  void bumpEmptyCategoriesToEnd({List<Service>? servicesOverride}) {
    final List<Service> services =
        servicesOverride ?? (ref.read(servicesProvider).value ?? []);
    final nonEmptyCatIds = <int>{for (final s in services) s.categoryId};

    int maxNonEmptySort = -1;
    for (final c in state) {
      if (nonEmptyCatIds.contains(c.id)) {
        if (c.sortOrder > maxNonEmptySort) maxNonEmptySort = c.sortOrder;
      }
    }

    // Base alta per evitare collisioni con futuri riordini
    final base = (maxNonEmptySort < 0 ? 0 : maxNonEmptySort + 1) + 1000;
    int offset = 0;

    final updated = [
      for (final c in state)
        if (nonEmptyCatIds.contains(c.id))
          c
        else
          c.copyWith(sortOrder: base + offset++),
    ];

    state = _sorted(updated);
  }
}

final serviceCategoriesProvider =
    NotifierProvider<ServiceCategoriesNotifier, List<ServiceCategory>>(
      ServiceCategoriesNotifier.new,
    );
