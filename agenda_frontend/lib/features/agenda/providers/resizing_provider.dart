import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dati della sessione di resize per un singolo appuntamento.
class _ResizingEntry {
  final double baseHeightPx;
  final DateTime startTimeInitial;
  final DateTime endTimeInitial;
  final double currentPreviewHeightPx;
  final DateTime provisionalEndTime;

  const _ResizingEntry({
    required this.baseHeightPx,
    required this.startTimeInitial,
    required this.endTimeInitial,
    required this.currentPreviewHeightPx,
    required this.provisionalEndTime,
  });

  _ResizingEntry copyWith({
    double? baseHeightPx,
    DateTime? startTimeInitial,
    DateTime? endTimeInitial,
    double? currentPreviewHeightPx,
    DateTime? provisionalEndTime,
  }) {
    return _ResizingEntry(
      baseHeightPx: baseHeightPx ?? this.baseHeightPx,
      startTimeInitial: startTimeInitial ?? this.startTimeInitial,
      endTimeInitial: endTimeInitial ?? this.endTimeInitial,
      currentPreviewHeightPx:
          currentPreviewHeightPx ?? this.currentPreviewHeightPx,
      provisionalEndTime: provisionalEndTime ?? this.provisionalEndTime,
    );
  }
}

/// Stato globale del resize (più entry contemporanee per staff multipli).
class ResizingState {
  final Map<int, _ResizingEntry> entries;
  final bool isResizing;

  const ResizingState({this.entries = const {}, this.isResizing = false});

  const ResizingState.initial() : entries = const {}, isResizing = false;

  ResizingState copyWith({
    Map<int, _ResizingEntry>? entries,
    bool? isResizing,
  }) {
    return ResizingState(
      entries: entries ?? this.entries,
      isResizing: isResizing ?? this.isResizing,
    );
  }
}

/// Gestore centralizzato dei resize attivi.
class ResizingNotifier extends Notifier<ResizingState> {
  @override
  ResizingState build() => const ResizingState.initial();

  /// Avvia una nuova sessione di resize per una card specifica.
  void startResize({
    required int appointmentId,
    required double currentHeightPx,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    // 🔹 Reset completo della base e altezza provvisoria
    final newEntry = _ResizingEntry(
      baseHeightPx: currentHeightPx,
      startTimeInitial: startTime,
      endTimeInitial: endTime,
      currentPreviewHeightPx: currentHeightPx,
      provisionalEndTime: endTime,
    );

    // 🔹 Aggiorna solo la entry corrente senza cancellare le altre
    final updated = Map<int, _ResizingEntry>.from(state.entries);
    updated[appointmentId] = newEntry;

    state = state.copyWith(entries: updated, isResizing: true);
  }

  /// Aggiornamento live durante il drag del bordo inferiore.
  void updateDuringResize({
    required int appointmentId,
    required double deltaDy,
    required double pixelsPerMinute,
    required DateTime dayEnd,
    required int minDurationMinutes,
    required int snapMinutes,
  }) {
    final entry = state.entries[appointmentId];
    if (entry == null) return;

    // 🔹 Calcola nuova altezza cumulativa a partire dall'altezza corrente
    double proposedHeightPx = (entry.currentPreviewHeightPx + deltaDy).clamp(
      0,
      double.infinity,
    );

    final proposedDurationMinutes = proposedHeightPx / pixelsPerMinute;

    // 🔹 Durata minima
    final durationAfterMin = proposedDurationMinutes < minDurationMinutes
        ? minDurationMinutes.toDouble()
        : proposedDurationMinutes;

    // 🔹 Snap ai minuti impostati
    double snappedMinutes = _snapToStep(durationAfterMin, snapMinutes);

    // 🔹 Nuovo end provvisorio
    DateTime candidateEnd = entry.startTimeInitial.add(
      Duration(minutes: snappedMinutes.round()),
    );

    // 🔹 Clamp a fine giornata
    if (candidateEnd.isAfter(dayEnd)) {
      candidateEnd = dayEnd;
      snappedMinutes = candidateEnd
          .difference(entry.startTimeInitial)
          .inMinutes
          .toDouble();
      proposedHeightPx = snappedMinutes * pixelsPerMinute;
    } else {
      proposedHeightPx = snappedMinutes * pixelsPerMinute;
    }

    final updatedEntry = entry.copyWith(
      currentPreviewHeightPx: proposedHeightPx,
      provisionalEndTime: candidateEnd,
    );

    final updated = Map<int, _ResizingEntry>.from(state.entries);
    updated[appointmentId] = updatedEntry;

    state = state.copyWith(entries: updated, isResizing: true);
  }

  /// Conclude il resize e restituisce il nuovo endTime definitivo.
  DateTime? commitResizeAndEnd({required int appointmentId}) {
    final entry = state.entries[appointmentId];
    final finalEnd = entry?.provisionalEndTime;
    if (entry == null) return null;

    // 🔹 Prima di rimuovere, resetta la preview height alla base originale
    final resetEntry = entry.copyWith(
      currentPreviewHeightPx: entry.baseHeightPx,
    );

    final updated = Map<int, _ResizingEntry>.from(state.entries);
    updated[appointmentId] = resetEntry;
    updated.remove(appointmentId);

    state = state.copyWith(entries: updated, isResizing: updated.isNotEmpty);

    return finalEnd;
  }

  /// Annulla un resize senza commit.
  void cancelResize({required int appointmentId}) {
    final updated = Map<int, _ResizingEntry>.from(state.entries);
    updated.remove(appointmentId);
    state = state.copyWith(entries: updated, isResizing: updated.isNotEmpty);
  }

  /// Accessori utili.
  double? previewHeightFor(int appointmentId) =>
      state.entries[appointmentId]?.currentPreviewHeightPx;

  DateTime? previewEndTimeFor(int appointmentId) =>
      state.entries[appointmentId]?.provisionalEndTime;

  double _snapToStep(double minutes, int step) {
    if (step <= 1) return minutes;
    final m = minutes / step;
    final rounded = m.round();
    return (rounded * step).toDouble();
  }
}

/// Provider principale di stato di resize.
final resizingProvider = NotifierProvider<ResizingNotifier, ResizingState>(
  ResizingNotifier.new,
);

/// Provider per una singola entry di appointment.
final resizingEntryProvider = Provider.family<_ResizingEntry?, int>(
  (ref, appointmentId) => ref.watch(resizingProvider).entries[appointmentId],
);
