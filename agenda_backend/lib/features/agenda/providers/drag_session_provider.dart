import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class DragSessionState {
  const DragSessionState({
    this.id,
    this.dropHandled = false,
  });

  final int? id;
  final bool dropHandled;

  DragSessionState copyWith({
    int? id,
    bool? dropHandled,
  }) {
    return DragSessionState(
      id: id ?? this.id,
      dropHandled: dropHandled ?? this.dropHandled,
    );
  }
}

class DragSessionNotifier extends Notifier<DragSessionState> {
  int _counter = 0;

  @override
  DragSessionState build() => const DragSessionState();

  int start() {
    final id = ++_counter;
    state = DragSessionState(id: id, dropHandled: false);
    return id;
  }

  void markHandled() {
    if (state.id == null) return;
    state = state.copyWith(dropHandled: true);
  }

  void clear() {
    state = const DragSessionState();
  }
}

final dragSessionProvider =
    NotifierProvider<DragSessionNotifier, DragSessionState>(
  DragSessionNotifier.new,
);
