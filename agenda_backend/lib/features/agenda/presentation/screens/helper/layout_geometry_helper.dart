import 'dart:math' as math;

class LayoutEntry {
  const LayoutEntry({
    required this.id,
    required this.start,
    required this.end,
  });

  final int id;
  final DateTime start;
  final DateTime end;
}

class EventGeometry {
  const EventGeometry({
    required this.leftFraction,
    required this.widthFraction,
  });

  final double leftFraction;
  final double widthFraction;
}

Map<int, EventGeometry> computeLayoutGeometry(
  List<LayoutEntry> entries, {
  bool useClusterMaxConcurrency = false,
}) {
  if (entries.isEmpty) return const {};

  final sorted = entries.toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final clusters = <List<LayoutEntry>>[];

  var currentCluster = <LayoutEntry>[];
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
      clusters.add(List<LayoutEntry>.from(currentCluster));
      currentCluster = [entry];
      currentMaxEnd = entry.end;
    }
  }

  if (currentCluster.isNotEmpty) {
    clusters.add(List<LayoutEntry>.from(currentCluster));
  }

  final geometryMap = <int, EventGeometry>{};

  for (final cluster in clusters) {
    final columnAssignments = _assignColumns(cluster);
    final concurrencyMap = _computeConcurrency(cluster);

    if (useClusterMaxConcurrency) {
      final clusterMaxConcurrency =
          concurrencyMap.values.fold<int>(1, math.max);
      final totalColumns =
          math.max(clusterMaxConcurrency, 1); // evita divisione per zero

      final columnMap = <int, List<LayoutEntry>>{};
      for (final entry in cluster) {
        final columnIndex = columnAssignments[entry.id] ?? 0;
        columnMap.putIfAbsent(columnIndex, () => []).add(entry);
      }

      for (final entry in cluster) {
        final columnIndex = columnAssignments[entry.id] ?? 0;
        int widthInColumns = 1;

        while (columnIndex + widthInColumns < totalColumns) {
          final candidateColumn = columnIndex + widthInColumns;
          final occupants = columnMap[candidateColumn];
          final hasOverlap = occupants?.any(
                (other) =>
                    _entriesOverlap(entry, other) &&
                    other.id != entry.id,
              ) ??
              false;

          if (hasOverlap) {
            break;
          }

          widthInColumns++;
        }

        for (int col = columnIndex; col < columnIndex + widthInColumns; col++) {
          final list = columnMap.putIfAbsent(col, () => []);
          if (!list.contains(entry)) {
            list.add(entry);
          }
        }

        final widthFraction = widthInColumns / totalColumns;
        final leftFraction = columnIndex / totalColumns;
        geometryMap[entry.id] = EventGeometry(
          leftFraction: leftFraction,
          widthFraction: widthFraction,
        );
      }
    } else {
      for (final entry in cluster) {
        final concurrency = concurrencyMap[entry.id] ?? 1;
        final widthFraction = 1 / concurrency;
        final columnIndex = columnAssignments[entry.id] ?? 0;
        final leftFraction = columnIndex * widthFraction;
        geometryMap[entry.id] = EventGeometry(
          leftFraction: leftFraction,
          widthFraction: widthFraction,
        );
      }
    }
  }

  return geometryMap;
}

bool _entriesOverlap(LayoutEntry a, LayoutEntry b) {
  if (identical(a, b)) return false;
  return a.start.isBefore(b.end) && a.end.isAfter(b.start);
}

Map<int, int> _assignColumns(List<LayoutEntry> cluster) {
  final assignments = <int, int>{};
  final columnEndTimes = <DateTime>[];

  final ordered = cluster.toList()
    ..sort((a, b) {
      final compareStart = a.start.compareTo(b.start);
      if (compareStart != 0) return compareStart;
      return a.end.compareTo(b.end);
    });

  for (final entry in ordered) {
    int assignedColumn = -1;
    for (int i = 0; i < columnEndTimes.length; i++) {
      if (!entry.start.isBefore(columnEndTimes[i])) {
        assignedColumn = i;
        columnEndTimes[i] = entry.end;
        break;
      }
    }

    if (assignedColumn == -1) {
      assignedColumn = columnEndTimes.length;
      columnEndTimes.add(entry.end);
    }

    assignments[entry.id] = assignedColumn;
  }

  return assignments;
}

Map<int, int> _computeConcurrency(List<LayoutEntry> cluster) {
  final concurrencyMap = <int, int>{};

  for (final entry in cluster) {
    final edges = <_Edge>[];

    for (final other in cluster) {
      final overlapStart = entry.start.isAfter(other.start)
          ? entry.start
          : other.start;
      final overlapEnd = entry.end.isBefore(other.end)
          ? entry.end
          : other.end;

      if (overlapStart.isBefore(overlapEnd)) {
        edges.add(_Edge(overlapStart, 1));
        edges.add(_Edge(overlapEnd, -1));
      }
    }

    edges.sort((a, b) {
      final compare = a.instant.compareTo(b.instant);
      if (compare != 0) return compare;
      if (a.delta == b.delta) return 0;
      return a.delta == -1 ? -1 : 1;
    });

    int active = 0;
    int maxActive = 0;
    for (final edge in edges) {
      active += edge.delta;
      if (active > maxActive) {
        maxActive = active;
      }
    }

    concurrencyMap[entry.id] = math.max(maxActive, 1);
  }

  return concurrencyMap;
}

class _Edge {
  const _Edge(this.instant, this.delta);

  final DateTime instant;
  final int delta;
}
