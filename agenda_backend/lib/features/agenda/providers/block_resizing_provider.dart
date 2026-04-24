import 'package:flutter_riverpod/flutter_riverpod.dart';

class _BlockResizingEntry {
  final double baseHeightPx;
  final DateTime startTimeInitial;
  final DateTime endTimeInitial;
  final double currentPreviewHeightPx;
  final DateTime provisionalEndTime;

  const _BlockResizingEntry({
    required this.baseHeightPx,
    required this.startTimeInitial,
    required this.endTimeInitial,
    required this.currentPreviewHeightPx,
    required this.provisionalEndTime,
  });

  _BlockResizingEntry copyWith({
    double? baseHeightPx,
    DateTime? startTimeInitial,
    DateTime? endTimeInitial,
    double? currentPreviewHeightPx,
    DateTime? provisionalEndTime,
  }) {
    return _BlockResizingEntry(
      baseHeightPx: baseHeightPx ?? this.baseHeightPx,
      startTimeInitial: startTimeInitial ?? this.startTimeInitial,
      endTimeInitial: endTimeInitial ?? this.endTimeInitial,
      currentPreviewHeightPx:
          currentPreviewHeightPx ?? this.currentPreviewHeightPx,
      provisionalEndTime: provisionalEndTime ?? this.provisionalEndTime,
    );
  }
}

class BlockResizingState {
  final Map<String, _BlockResizingEntry> entries;
  final bool isResizing;

  const BlockResizingState({this.entries = const {}, this.isResizing = false});
  const BlockResizingState.initial() : entries = const {}, isResizing = false;

  BlockResizingState copyWith({
    Map<String, _BlockResizingEntry>? entries,
    bool? isResizing,
  }) {
    return BlockResizingState(
      entries: entries ?? this.entries,
      isResizing: isResizing ?? this.isResizing,
    );
  }
}

class BlockResizingNotifier extends Notifier<BlockResizingState> {
  @override
  BlockResizingState build() => const BlockResizingState.initial();

  void startResize({
    required String resizeSessionKey,
    required double currentHeightPx,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final newEntry = _BlockResizingEntry(
      baseHeightPx: currentHeightPx,
      startTimeInitial: startTime,
      endTimeInitial: endTime,
      currentPreviewHeightPx: currentHeightPx,
      provisionalEndTime: endTime,
    );
    final updated = Map<String, _BlockResizingEntry>.from(state.entries);
    updated[resizeSessionKey] = newEntry;
    state = state.copyWith(entries: updated, isResizing: true);
  }

  void updateDuringResize({
    required String resizeSessionKey,
    required double deltaDy,
    required double pixelsPerMinute,
    required DateTime dayEnd,
    required int minDurationMinutes,
    required int snapMinutes,
  }) {
    final entry = state.entries[resizeSessionKey];
    if (entry == null) return;

    double proposedHeightPx = entry.currentPreviewHeightPx + deltaDy;
    final minHeightPx = minDurationMinutes * pixelsPerMinute;
    final rawMaxDurationMinutes = dayEnd
        .difference(entry.startTimeInitial)
        .inMinutes;
    final effectiveMaxDurationMinutes = rawMaxDurationMinutes <= 0
        ? minDurationMinutes
        : rawMaxDurationMinutes < minDurationMinutes
        ? minDurationMinutes
        : rawMaxDurationMinutes;
    final maxHeightPx = effectiveMaxDurationMinutes * pixelsPerMinute;

    proposedHeightPx = proposedHeightPx
        .clamp(minHeightPx, maxHeightPx)
        .toDouble();
    final proposedDurationMinutes = proposedHeightPx / pixelsPerMinute;
    final snappedMinutes = _snapToStep(proposedDurationMinutes, snapMinutes)
        .clamp(
          minDurationMinutes.toDouble(),
          effectiveMaxDurationMinutes.toDouble(),
        );

    DateTime candidateEnd = entry.startTimeInitial.add(
      Duration(minutes: snappedMinutes.round()),
    );
    if (candidateEnd.isAfter(dayEnd)) {
      candidateEnd = dayEnd;
    }

    final updatedEntry = entry.copyWith(
      currentPreviewHeightPx: proposedHeightPx,
      provisionalEndTime: candidateEnd,
    );
    final updated = Map<String, _BlockResizingEntry>.from(state.entries);
    updated[resizeSessionKey] = updatedEntry;
    state = state.copyWith(entries: updated, isResizing: true);
  }

  DateTime? commitResizeAndEnd({required String resizeSessionKey}) {
    final entry = state.entries[resizeSessionKey];
    final finalEnd = entry?.provisionalEndTime;
    if (entry == null) return null;

    final updated = Map<String, _BlockResizingEntry>.from(state.entries);
    updated.remove(resizeSessionKey);
    state = state.copyWith(entries: updated, isResizing: updated.isNotEmpty);
    return finalEnd;
  }

  void cancelResize({required String resizeSessionKey}) {
    final updated = Map<String, _BlockResizingEntry>.from(state.entries);
    updated.remove(resizeSessionKey);
    state = state.copyWith(entries: updated, isResizing: updated.isNotEmpty);
  }

  DateTime? previewEndTimeFor(String resizeSessionKey) =>
      state.entries[resizeSessionKey]?.provisionalEndTime;

  double _snapToStep(double minutes, int step) {
    if (step <= 1) return minutes;
    final m = minutes / step;
    final rounded = m.round();
    return (rounded * step).toDouble();
  }
}

final blockResizingProvider =
    NotifierProvider<BlockResizingNotifier, BlockResizingState>(
      BlockResizingNotifier.new,
    );

String blockResizeSessionKey({
  required int blockId,
  required int staffId,
  required DateTime day,
}) {
  final dateOnly = DateTime(day.year, day.month, day.day);
  return '$blockId::$staffId::${dateOnly.toIso8601String()}';
}

final blockResizingEndTimeProvider = Provider.family<DateTime?, String>(
  (ref, resizeSessionKey) => ref
      .watch(blockResizingProvider)
      .entries[resizeSessionKey]
      ?.provisionalEndTime,
);
