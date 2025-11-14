import 'package:flutter/foundation.dart';

/// Skeleton: controller per reorder categorie – API da collegare 1:1
class CategoriesReorderController {
  const CategoriesReorderController();

  // Esempio di firma che potrà essere implementata 1:1 durante l'estrazione
  void onReorder({required int oldIndex, required int newIndex}) {
    // Implementazione reale verrà estratta da services_screen.dart
    if (kDebugMode) {
      // ignore: avoid_print
      print('Categories reorder: $oldIndex -> $newIndex (skeleton)');
    }
  }
}
