import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ResizingEntry {
  final double? tempHeight;
  final DateTime? provisionalEndTime;

  const _ResizingEntry({this.tempHeight, this.provisionalEndTime});

  _ResizingEntry copyWith({double? tempHeight, DateTime? provisionalEndTime}) {
    return _ResizingEntry(
      tempHeight: tempHeight ?? this.tempHeight,
      provisionalEndTime: provisionalEndTime ?? this.provisionalEndTime,
    );
  }
}

class ResizingState {
  final Map<int, _ResizingEntry> entries;
  const ResizingState({this.entries = const {}});

  ResizingState copyWith({Map<int, _ResizingEntry>? entries}) =>
      ResizingState(entries: entries ?? this.entries);
}

class ResizingNotifier extends Notifier<ResizingState> {
  @override
  ResizingState build() => const ResizingState();

  void start(int id, double startHeight) {
    final newMap = Map<int, _ResizingEntry>.from(state.entries);
    newMap[id] = _ResizingEntry(tempHeight: startHeight);
    state = state.copyWith(entries: newMap);
  }

  void updateHeight(int id, double h) {
    final entry = state.entries[id];
    if (entry != null) {
      final newMap = Map<int, _ResizingEntry>.from(state.entries);
      newMap[id] = entry.copyWith(tempHeight: h);
      state = state.copyWith(entries: newMap);
    }
  }

  void updateProvisionalEndTime(int id, DateTime newEnd) {
    final entry = state.entries[id];
    if (entry != null) {
      final newMap = Map<int, _ResizingEntry>.from(state.entries);
      newMap[id] = entry.copyWith(provisionalEndTime: newEnd);
      state = state.copyWith(entries: newMap);
    }
  }

  void stop(int id) {
    final newMap = Map<int, _ResizingEntry>.from(state.entries);
    newMap.remove(id);
    state = state.copyWith(entries: newMap);
  }

  void clearAll() => state = const ResizingState();
}

final resizingProvider = NotifierProvider<ResizingNotifier, ResizingState>(
  ResizingNotifier.new,
);

/// 🟢 Provider selettivo: restituisce solo l’entry del singolo appointment
final resizingEntryProvider = Provider.family<_ResizingEntry?, int>((
  ref,
  appointmentId,
) {
  final state = ref.watch(resizingProvider);
  return state.entries[appointmentId];
});
