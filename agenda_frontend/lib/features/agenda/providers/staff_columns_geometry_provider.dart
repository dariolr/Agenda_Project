import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mappa: staffId -> Rect della colonna in coordinate BODY-LOCAL
class StaffColumnsGeometryNotifier extends Notifier<Map<int, Rect>> {
  @override
  Map<int, Rect> build() => <int, Rect>{};

  void setRect(int staffId, Rect rect) {
    final next = Map<int, Rect>.from(state)..[staffId] = rect;
    state = next;
  }

  void clearFor(int staffId) {
    if (!state.containsKey(staffId)) return;
    final next = Map<int, Rect>.from(state)..remove(staffId);
    state = next;
  }

  void clearAll() => state = <int, Rect>{};
}

final staffColumnsGeometryProvider =
    NotifierProvider<StaffColumnsGeometryNotifier, Map<int, Rect>>(
      StaffColumnsGeometryNotifier.new,
    );
