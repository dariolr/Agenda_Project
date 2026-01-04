import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agenda/providers/location_providers.dart';
import 'staff_providers.dart';

class TeamReorderNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void setReordering(bool value) => state = value;

  Future<void> reorderLocations(int oldIndex, int newIndex) async {
    await ref.read(locationsProvider.notifier).reorder(oldIndex, newIndex);
  }

  Future<void> reorderStaffForLocation(
    int locationId,
    int oldIndex,
    int newIndex,
  ) async {
    await ref
        .read(allStaffProvider.notifier)
        .reorderForLocation(locationId, oldIndex, newIndex);
  }
}

final teamReorderProvider = NotifierProvider<TeamReorderNotifier, bool>(
  TeamReorderNotifier.new,
);

class TeamReorderPanelNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void setVisible(bool value) => state = value;
}

final teamReorderPanelProvider =
    NotifierProvider<TeamReorderPanelNotifier, bool>(
      TeamReorderPanelNotifier.new,
    );
