import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Flutter ReorderableListView semantics: adjust newIndex when moving down
    if (newIndex > oldIndex) newIndex -= 1;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Ricalcola sortOrder consecutivi
    final reordered = <ServiceCategory>[];
    for (int i = 0; i < list.length; i++) {
      reordered.add(list[i].copyWith(sortOrder: i));
    }

    notifier.state = reordered;
  }

  /// Riordina i servizi all'interno della categoria
  void reorderServices(int categoryId, int oldIndex, int newIndex) {
    final servicesNotifier = ref.read(servicesProvider.notifier);
    final all = [...ref.read(servicesProvider)];

    // Estrai solo quelli della categoria
    final byCat = [
      for (final s in all)
        if (s.categoryId == categoryId) s,
    ];

    if (newIndex > oldIndex) newIndex -= 1;
    final item = byCat.removeAt(oldIndex);
    byCat.insert(newIndex, item);

    // Ricostruisci sortOrder per la categoria
    final updatedByCat = <Service>[];
    for (int i = 0; i < byCat.length; i++) {
      updatedByCat.add(byCat[i].copyWith(sortOrder: i));
    }

    // Rimonta la lista completa sostituendo gli elementi della categoria
    final updatedAll = [
      for (final s in all)
        if (s.categoryId == categoryId)
          updatedByCat.firstWhere((x) => x.id == s.id)
        else
          s,
    ];

    servicesNotifier.state = updatedAll;
  }
}

final servicesReorderProvider = NotifierProvider<ServicesReorderNotifier, bool>(
  ServicesReorderNotifier.new,
);
