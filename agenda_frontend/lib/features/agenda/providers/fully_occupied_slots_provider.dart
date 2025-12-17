import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'appointment_providers.dart';
import 'date_range_provider.dart';
import 'layout_config_provider.dart';

part 'fully_occupied_slots_provider.g.dart';

/// Calcola gli indici degli slot completamente occupati per un dato staff.
/// Uno slot è "completamente occupato" quando la somma delle frazioni di larghezza
/// degli appuntamenti che lo coprono raggiunge o supera il 100%.
@riverpod
Set<int> fullyOccupiedSlots(Ref ref, int staffId) {
  final appointments = ref
      .watch(appointmentsForCurrentLocationProvider)
      .where((a) => a.staffId == staffId)
      .toList();

  if (appointments.isEmpty) return const {};

  final layoutConfig = ref.watch(layoutConfigProvider);
  final agendaDate = ref.watch(agendaDateProvider);
  final minutesPerSlot = layoutConfig.minutesPerSlot;
  final totalSlots = layoutConfig.totalSlots;

  // Calcola la geometria degli appuntamenti per determinare le frazioni di larghezza
  final layoutEntries = appointments
      .map((a) => _LayoutEntry(id: a.id, start: a.startTime, end: a.endTime))
      .toList();

  final geometryMap = _computeLayoutGeometry(
    layoutEntries,
    useClusterMaxConcurrency: layoutConfig.useClusterMaxConcurrency,
  );

  // Per ogni slot, calcola la somma delle frazioni di larghezza coperte
  final fullyOccupied = <int>{};

  for (int slotIndex = 0; slotIndex < totalSlots; slotIndex++) {
    final slotStart = agendaDate.add(
      Duration(minutes: slotIndex * minutesPerSlot),
    );
    final slotEnd = slotStart.add(Duration(minutes: minutesPerSlot));

    // Trova tutti gli appuntamenti che coprono questo slot
    double totalWidthFraction = 0.0;

    for (final appt in appointments) {
      // Verifica se l'appuntamento copre lo slot
      if (appt.startTime.isBefore(slotEnd) && appt.endTime.isAfter(slotStart)) {
        final geometry = geometryMap[appt.id];
        if (geometry != null) {
          totalWidthFraction += geometry.widthFraction;
        }
      }
    }

    // Lo slot è completamente occupato se la somma >= 1.0 (100%)
    if (totalWidthFraction >= 0.999) {
      fullyOccupied.add(slotIndex);
    }
  }

  return fullyOccupied;
}

// ── Classi helper per il calcolo della geometria ──────────────────────────────

class _LayoutEntry {
  const _LayoutEntry({
    required this.id,
    required this.start,
    required this.end,
  });

  final int id;
  final DateTime start;
  final DateTime end;
}

class _EventGeometry {
  const _EventGeometry({
    required this.leftFraction,
    required this.widthFraction,
  });

  final double leftFraction;
  final double widthFraction;
}

/// Versione semplificata del layout geometry helper.
Map<int, _EventGeometry> _computeLayoutGeometry(
  List<_LayoutEntry> entries, {
  bool useClusterMaxConcurrency = false,
}) {
  if (entries.isEmpty) return const {};

  final sorted = entries.toList()..sort((a, b) => a.start.compareTo(b.start));

  final clusters = <List<_LayoutEntry>>[];
  var currentCluster = <_LayoutEntry>[];
  DateTime? currentMaxEnd;

  for (final entry in sorted) {
    if (currentCluster.isEmpty) {
      currentCluster = [entry];
      currentMaxEnd = entry.end;
      continue;
    }

    if (entry.start.isBefore(currentMaxEnd!)) {
      currentCluster.add(entry);
      if (entry.end.isAfter(currentMaxEnd)) {
        currentMaxEnd = entry.end;
      }
    } else {
      clusters.add(List<_LayoutEntry>.from(currentCluster));
      currentCluster = [entry];
      currentMaxEnd = entry.end;
    }
  }

  if (currentCluster.isNotEmpty) {
    clusters.add(List<_LayoutEntry>.from(currentCluster));
  }

  final geometryMap = <int, _EventGeometry>{};

  for (final cluster in clusters) {
    final concurrencyMap = _computeConcurrency(cluster);

    for (final entry in cluster) {
      final concurrency = concurrencyMap[entry.id] ?? 1;
      final widthFraction = 1 / concurrency;
      geometryMap[entry.id] = _EventGeometry(
        leftFraction: 0, // Non ci serve leftFraction per questo calcolo
        widthFraction: widthFraction,
      );
    }
  }

  return geometryMap;
}

Map<int, int> _computeConcurrency(List<_LayoutEntry> cluster) {
  final result = <int, int>{};

  for (final entry in cluster) {
    int count = 0;
    for (final other in cluster) {
      if (entry.start.isBefore(other.end) && entry.end.isAfter(other.start)) {
        count++;
      }
    }
    result[entry.id] = count;
  }

  return result;
}
