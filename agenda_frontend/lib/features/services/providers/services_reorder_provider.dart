import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import 'service_categories_provider.dart';
import 'services_provider.dart';

/// Gestisce la modalità riordino e applica gli ordinamenti aggiornando sortOrder
class ServicesReorderNotifier extends Notifier<bool> {
  @override
  bool build() => false; // false = non in riordino

  void toggle() => state = !state;

  void setReordering(bool value) => state = value;

  /// Riordina le categorie a livello top
  void reorderCategories(int oldIndex, int newIndex) {
    final notifier = ref.read(serviceCategoriesProvider.notifier);
    final list = [...ref.read(serviceCategoriesProvider)];

    if (newIndex > oldIndex) newIndex -= 1;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final reordered = <ServiceCategory>[];
    for (int i = 0; i < list.length; i++) {
      reordered.add(list[i].copyWith(sortOrder: i));
    }

    notifier.state = reordered;
  }

  /// Riordina solo le categorie NON vuote, mantenendo le vuote in coda e non spostabili.
  void reorderNonEmptyCategories(int oldIndex, int newIndex) {
    final catsNotifier = ref.read(serviceCategoriesProvider.notifier);
    final allCats = [...ref.read(serviceCategoriesProvider)];
    final services = ref.read(servicesProvider);

    final nonEmpty = <ServiceCategory>[];
    final empty = <ServiceCategory>[];
    for (final c in allCats) {
      final hasServices = services.any((s) => s.categoryId == c.id);
      if (hasServices) {
        nonEmpty.add(c);
      } else {
        empty.add(c);
      }
    }

    final item = nonEmpty.removeAt(oldIndex);
    final insertIndex = newIndex.clamp(0, nonEmpty.length);
    nonEmpty.insert(insertIndex, item);

    final merged = [...nonEmpty, ...empty];
    final reordered = <ServiceCategory>[];
    for (int i = 0; i < merged.length; i++) {
      reordered.add(merged[i].copyWith(sortOrder: i));
    }

    catsNotifier.state = reordered;
  }

  /// Riordina i servizi all'interno della stessa categoria
  void reorderServices(int categoryId, int oldIndex, int newIndex) {
    final servicesNotifier = ref.read(servicesProvider.notifier);
    final all = [...ref.read(servicesProvider)];

    final byCat = all.where((s) => s.categoryId == categoryId).toList();
    final item = byCat.removeAt(oldIndex);
    byCat.insert(newIndex, item);

    final updatedByCat = <Service>[];
    for (int i = 0; i < byCat.length; i++) {
      updatedByCat.add(byCat[i].copyWith(sortOrder: i));
    }

    final updatedAll = [
      for (final s in all)
        if (s.categoryId == categoryId)
          updatedByCat.firstWhere((x) => x.id == s.id)
        else
          s,
    ];

    servicesNotifier.state = updatedAll;
  }

  /// 🔄 Sposta un servizio da una categoria all'altra (drag cross-categoria)
  void moveServiceBetweenCategories(
    int oldCategoryId,
    int newCategoryId,
    int serviceId,
    int newIndex,
  ) {
    final servicesNotifier = ref.read(servicesProvider.notifier);
    final all = [...ref.read(servicesProvider)];

    // servizio selezionato
    final movedService = all.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => throw Exception(L10n.current.errorServiceNotFound),
    );

    // rimuovi da categoria precedente
    final remainingOldCat = all
        .where((s) => s.categoryId == oldCategoryId && s.id != serviceId)
        .toList();

    // aggiungi nella nuova categoria
    final targetCat = all.where((s) => s.categoryId == newCategoryId).toList();
    if (newIndex > targetCat.length) newIndex = targetCat.length;
    targetCat.insert(
      newIndex,
      movedService.copyWith(categoryId: newCategoryId),
    );

    // ricalcola sortOrder in entrambe le categorie
    final updated = [
      ...all.where(
        (s) => s.categoryId != oldCategoryId && s.categoryId != newCategoryId,
      ),
      for (int i = 0; i < remainingOldCat.length; i++)
        remainingOldCat[i].copyWith(sortOrder: i),
      for (int i = 0; i < targetCat.length; i++)
        targetCat[i].copyWith(sortOrder: i),
    ];

    servicesNotifier.state = updated;
    // Aggiorna posizionamento categorie vuote vs piene
    ref.read(serviceCategoriesProvider.notifier).bumpEmptyCategoriesToEnd();
  }
}

final servicesReorderProvider = NotifierProvider<ServicesReorderNotifier, bool>(
  ServicesReorderNotifier.new,
);

class ServicesReorderPanelNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void setVisible(bool value) => state = value;
}

final servicesReorderPanelProvider =
    NotifierProvider<ServicesReorderPanelNotifier, bool>(
  ServicesReorderPanelNotifier.new,
);
