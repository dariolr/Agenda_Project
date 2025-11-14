import 'package:flutter/foundation.dart';

/// Skeleton: controller per reorder servizi – API da collegare 1:1
class ServicesReorderController {
  const ServicesReorderController();

  // Esempio di firma che potrà essere implementata 1:1 durante l'estrazione
  void onReorder({required int oldIndex, required int newIndex}) {
    // Implementazione reale verrà estratta da services_screen.dart
    if (kDebugMode) {
      // ignore: avoid_print
      print('Services reorder: $oldIndex -> $newIndex (skeleton)');
    }
  }
}
