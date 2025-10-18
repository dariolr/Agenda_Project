import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation_destinations.dart';

/// 🔹 Tiene traccia della sezione selezionata.
/// Mantiene lo stato anche se il widget viene ricostruito.
class NavigationController extends Notifier<AppSection> {
  @override
  AppSection build() => AppSection.agenda;

  void select(AppSection section) => state = section;
}

final navigationControllerProvider =
    NotifierProvider<NavigationController, AppSection>(
      NavigationController.new,
    );
