import 'dart:math' as math;

import 'package:agenda_frontend/features/agenda/providers/dragged_card_size_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '/core/models/staff.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/dragged_base_range_provider.dart';
import '../../../providers/dragged_last_staff_provider.dart';
import '../../../providers/resizing_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../../../providers/selected_appointment_provider.dart'; // Added missing import
import '../widgets/agenda_dividers.dart';
import '../widgets/appointment_card_base.dart';

class StaffColumn extends ConsumerStatefulWidget {
  final Staff staff;
  final List<Appointment> appointments;
  final double columnWidth;
  final bool showRightBorder;

  const StaffColumn({
    super.key,
    required this.staff,
    required this.appointments,
    required this.columnWidth,
    this.showRightBorder = true,
  });

  @override
  ConsumerState<StaffColumn> createState() => _StaffColumnState();
}

class _StaffColumnState extends ConsumerState<StaffColumn> {
  bool _isHighlighted = false;
  double? _hoverY;
  late final ProviderSubscription<Offset?> _dragListener;

  @override
  void initState() {
    super.initState();

    _dragListener = ref.listenManual<Offset?>(dragPositionProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      final highlightNotifier = ref.read(highlightedStaffIdProvider.notifier);
      final tempTimeNotifier = ref.read(tempDragTimeProvider.notifier);

      if (next == null) {
        if (_isHighlighted || _hoverY != null) {
          setState(() {
            _isHighlighted = false;
            _hoverY = null;
          });
        }
        highlightNotifier.clear();
        tempTimeNotifier.clear();
        return;
      }

      final box = context.findRenderObject() as RenderBox?;
      final bodyBox = ref.read(dragBodyBoxProvider);
      if (box == null || bodyBox == null) return;

      final columnTopLeftInBody = bodyBox.globalToLocal(
        box.localToGlobal(Offset.zero),
      );
      ref
          .read(staffColumnsGeometryProvider.notifier)
          .setRect(
            widget.staff.id,
            Rect.fromLTWH(
              columnTopLeftInBody.dx,
              columnTopLeftInBody.dy,
              box.size.width,
              box.size.height,
            ),
          );

      final localInColumn = Offset(
        next.dx - columnTopLeftInBody.dx,
        next.dy - columnTopLeftInBody.dy,
      );

      final withinHorizontal =
          localInColumn.dx >= 0 && localInColumn.dx <= box.size.width;
      if (withinHorizontal) {
        final dragOffset = ref.read(dragOffsetProvider);
        final layoutConfig = ref.read(layoutConfigProvider);

        // 🔹 Altezza effettiva della card trascinata (fallback 50px se non nota)
        final draggedCardHeightPx =
            ref.read(draggedCardSizeProvider)?.height ?? 50.0;

        // 🔹 Punto massimo CONSENTITO per l'inizio della card in pixel
        final maxYStartPx = (box.size.height - draggedCardHeightPx)
            .clamp(0, box.size.height)
            .toDouble();

        // 🔹 Y effettiva del "top" della card, clampata ai limiti verticali
        final clampedLocalDy =
            localInColumn.dy.clamp(0.0, box.size.height.toDouble());
        final double effectiveY =
            (clampedLocalDy - (dragOffset ?? 0)).clamp(0, maxYStartPx).toDouble();

        setState(() {
          _hoverY = effectiveY;
          _isHighlighted = true;
        });
        highlightNotifier.set(widget.staff.id);
        ref.read(draggedLastStaffIdProvider.notifier).set(widget.staff.id);

        // ─────────────────────────────────────────
        // ⏱ Calcolo orario proposto
        // ─────────────────────────────────────────
        final slotHeight = layoutConfig.slotHeight;

        // minuti dall'inizio giornata (00:00)
        final minutesFromTop =
            (effectiveY / slotHeight) * layoutConfig.minutesPerSlot;

        // arrotondiamo a step di 5 minuti
        double roundedMinutes = (minutesFromTop / 5).round() * 5;

        // durata dell'appuntamento trascinato
        final draggedId = ref.read(draggedAppointmentIdProvider);
        Duration duration;
        DateTime baseDate;
        if (draggedId != null) {
          final appt = ref
              .read(appointmentsProvider)
              .firstWhere((a) => a.id == draggedId);
          duration = appt.endTime.difference(appt.startTime);
          baseDate = DateTime(
            appt.startTime.year,
            appt.startTime.month,
            appt.startTime.day,
          );
        } else {
          final baseRange = ref.read(draggedBaseRangeProvider);
          if (baseRange != null) {
            final start = baseRange.$1;
            final end = baseRange.$2;
            duration = end.difference(start);
            baseDate = DateTime(start.year, start.month, start.day);
          } else {
            duration = const Duration(minutes: 30);
            final now = DateTime.now();
            baseDate = DateTime(now.year, now.month, now.day);
          }
        }

        final durationMinutes = duration.inMinutes;

        // 🔒 Limiti nell'arco della giornata
        const totalMinutes = LayoutConfig.hoursInDay * 60; // 1440
        final maxStartMinutesNum =
            (totalMinutes - durationMinutes).clamp(0, totalMinutes);

        if (roundedMinutes > maxStartMinutesNum) {
          roundedMinutes = maxStartMinutesNum.toDouble();
        } else if (roundedMinutes < 0) {
          roundedMinutes = 0;
        }

        final startMinutes = roundedMinutes.toInt();
        final endMinutes =
            (startMinutes + durationMinutes).clamp(0, totalMinutes).toInt();

        final start = baseDate.add(Duration(minutes: startMinutes));
        var end = baseDate.add(Duration(minutes: endMinutes));

        final dayBoundary = baseDate.add(const Duration(days: 1));
        if (end.isAfter(dayBoundary)) end = dayBoundary;

        // aggiorna l'anteprima oraria mostrata nella card fantasma
        tempTimeNotifier.setTimes(start, end);
      } else if (_isHighlighted) {
        final headerHeight = ref.read(layoutConfigProvider).headerHeight;
        final globalY = next.dy;
        if (globalY > headerHeight - 5) return;

        setState(() {
          _isHighlighted = false;
          _hoverY = null;
        });
        highlightNotifier.clear();
        tempTimeNotifier.clear();
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _dragListener.close();
    final highlightedId = ref.read(highlightedStaffIdProvider);
    if (highlightedId == widget.staff.id) {
      ref.read(highlightedStaffIdProvider.notifier).clear();
    }
    ref.read(staffColumnsGeometryProvider.notifier).clearFor(widget.staff.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAppointments = ref.watch(appointmentsProvider);
    final staffAppointments = allAppointments
        .where((a) => a.staffId == widget.staff.id)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox?;
      final bodyBox = ref.read(dragBodyBoxProvider);
      if (box != null && bodyBox != null) {
        final topLeft = bodyBox.globalToLocal(box.localToGlobal(Offset.zero));
        ref
            .read(staffColumnsGeometryProvider.notifier)
            .setRect(
              widget.staff.id,
              Rect.fromLTWH(
                topLeft.dx,
                topLeft.dy,
                box.size.width,
                box.size.height,
              ),
            );
      }
    });

    final layoutConfig = ref.watch(layoutConfigProvider);
    final slotHeight = layoutConfig.slotHeight;
    final totalSlots = layoutConfig.totalSlots;
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);

    final stackChildren = <Widget>[];

    // 🔹 Griglia oraria
    stackChildren.add(
      Column(
        children: List.generate(totalSlots, (index) {
          final slotsPerHour = 60 ~/ layoutConfig.minutesPerSlot;
          final isHourStart = (index + 1) % slotsPerHour == 0;
          return SizedBox(
            height: slotHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: AgendaHorizontalDivider(
                color: Colors.grey.withOpacity(isHourStart ? 0.5 : 0.2),
                thickness: isHourStart ? 1 : 0.5,
              ),
            ),
          );
        }),
      ),
    );

    // 🔹 Appuntamenti
    stackChildren.addAll(_buildAppointments(slotHeight, staffAppointments));

    return DragTarget<Appointment>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isHighlighted = true);
        ref.read(highlightedStaffIdProvider.notifier).set(widget.staff.id);
        return true;
      },
      onLeave: (_) {
        setState(() => _isHighlighted = false);
        ref.read(highlightedStaffIdProvider.notifier).clear();
      },
      onAcceptWithDetails: (details) {
        final previewTimes = ref.read(tempDragTimeProvider);
        setState(() {
          _isHighlighted = false;
          _hoverY = null;
        });
        ref.read(highlightedStaffIdProvider.notifier).clear();
        ref.read(tempDragTimeProvider.notifier).clear();

        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;

        final dragOffsetY = ref.read(dragOffsetProvider) ?? 0.0;
        final dragOffsetX = ref.read(dragOffsetXProvider) ?? 0.0;
        final pointerGlobal =
            details.offset + Offset(dragOffsetX, dragOffsetY);
        final localPointer = box.globalToLocal(pointerGlobal);
        final draggedCardHeightPx =
            ref.read(draggedCardSizeProvider)?.height ?? 50.0;
        final maxYStartPx = (box.size.height - draggedCardHeightPx)
            .clamp(0, box.size.height)
            .toDouble();
        final clampedLocalDy =
            localPointer.dy.clamp(0.0, box.size.height.toDouble());
        final double effectiveDy =
            (clampedLocalDy - dragOffsetY).clamp(0.0, maxYStartPx).toDouble();

        DateTime newStart;
        DateTime newEnd;

        if (previewTimes != null) {
          newStart = previewTimes.$1;
          newEnd = previewTimes.$2;
        } else {
          final minutesFromTop =
              (effectiveDy / slotHeight) * layoutConfig.minutesPerSlot;
          double roundedMinutes = (minutesFromTop / 5).round() * 5;

          final duration = details.data.endTime.difference(
            details.data.startTime,
          );
          final durationMinutes = duration.inMinutes;

          // ✅ Data base dell'app originale
          final baseDate = DateTime(
            details.data.startTime.year,
            details.data.startTime.month,
            details.data.startTime.day,
          );

          // 🔒 Limiti della giornata in minuti
          const totalMinutes = LayoutConfig.hoursInDay * 60; // 1440
          final maxStartMinutesNum =
              (totalMinutes - durationMinutes).clamp(0, totalMinutes);

          int startMinutes = roundedMinutes.toInt();
          final maxStartMinutes = maxStartMinutesNum.toInt();

          if (startMinutes > maxStartMinutes) startMinutes = maxStartMinutes;
          if (startMinutes < 0) startMinutes = 0;

          final endMinutes =
              (startMinutes + durationMinutes).clamp(0, totalMinutes).toInt();

          newStart = baseDate.add(Duration(minutes: startMinutes));
          newEnd = baseDate.add(Duration(minutes: endMinutes));
        }

        appointmentsNotifier.moveAppointment(
          appointmentId: details.data.id,
          newStaffId: widget.staff.id,
          newStart: newStart,
          newEnd: newEnd,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            ref.read(selectedAppointmentProvider.notifier).clear();
          },
          child: SizedBox(
            width: widget.columnWidth,
            child: Container(
              decoration: BoxDecoration(
                color: _isHighlighted
                    ? widget.staff.color.withOpacity(0.01)
                    : Colors.transparent,
                border: widget.showRightBorder
                    ? Border(
                        right: BorderSide(
                          color: Colors.grey.withOpacity(0.5),
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              child: Stack(children: stackChildren),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAppointments(
    double slotHeight,
    List<Appointment> appointments,
  ) {
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);

    final layoutAppointments = appointments.map((appt) {
      final resizingEntry = ref.watch(resizingEntryProvider(appt.id));
      if (resizingEntry != null &&
          resizingEntry.provisionalEndTime != appt.endTime) {
        return appt.copyWith(endTime: resizingEntry.provisionalEndTime);
      }
      return appt;
    }).toList();

    final List<List<Appointment>> overlapGroups = [];
    for (final appt in layoutAppointments) {
      bool added = false;
      for (final group in overlapGroups) {
        if (group.any((g) =>
            appt.startTime.isBefore(g.endTime) &&
            appt.endTime.isAfter(g.startTime))) {
          group.add(appt);
          added = true;
          break;
        }
      }
      if (!added) {
        overlapGroups.add([appt]);
      }
    }

    final positionedAppointments = <Widget>[];

    final originalAppointmentsMap = {for (var a in appointments) a.id: a};
    final layoutInputs = layoutAppointments
        .map(
          (a) => _LayoutEntry(
            id: a.id,
            start: a.startTime,
            end: a.endTime,
          ),
        )
        .toList();
    final layoutGeometry = _computeLayoutGeometry(layoutInputs);

    for (final group in overlapGroups) {
      final groupWidgets = <Widget>[];
      final groupSize = group.length;
      group.sort((a, b) => a.startTime.compareTo(b.startTime));

      for (int i = 0; i < groupSize; i++) {
        final layoutAppt = group[i];
        final originalAppt = originalAppointmentsMap[layoutAppt.id]!;

        final isDragged = originalAppt.id == draggedId;

        final dayStart = DateTime(
          originalAppt.startTime.year,
          originalAppt.startTime.month,
          originalAppt.startTime.day,
        );

        final startMinutes =
            originalAppt.startTime.difference(dayStart).inMinutes;

        final endMinutes = layoutAppt.endTime.difference(dayStart).inMinutes;

        final double top =
            (startMinutes / layoutConfig.minutesPerSlot) * slotHeight;
        double height =
            ((endMinutes - startMinutes) / layoutConfig.minutesPerSlot) *
                slotHeight;

        final entry = ref.watch(resizingEntryProvider(originalAppt.id));
        if (entry != null) {
          height = entry.currentPreviewHeightPx;
        }

        final geometry = layoutGeometry[originalAppt.id] ??
            const _EventGeometry(leftFraction: 0, widthFraction: 1);
        double opacity = isDragged ? AgendaTheme.ghostOpacity : 1.0;

        // 🔹 Costruisci la card
        final padding = LayoutConfig.columnInnerPadding;
        final cardLeft =
            widget.columnWidth * geometry.leftFraction + padding;
        final cardWidth = math.max(
          widget.columnWidth * geometry.widthFraction - padding * 2,
          0.0,
        );

        groupWidgets.add(
          Positioned(
            key: ValueKey(originalAppt.id),
            top: top,
            left: cardLeft,
            width: cardWidth,
            height: height,
            child: Opacity(
              opacity: opacity,
              child: AppointmentCard(
                appointment: originalAppt,
                color: widget.staff.color,
                columnWidth: cardWidth,
                columnOffset: cardLeft,
                expandToLeft: i > 0,
              ),
            ),
          ),
        );
      }

      // Posizioniamo i widget del gruppo in ordine inverso, così gli
      // appuntamenti che iniziano prima rimangono sopra e non vengono
      // parzialmente coperti da quelli iniziati dopo.
      positionedAppointments.addAll(groupWidgets.reversed);
    }

    return positionedAppointments;
  }

  Map<int, _EventGeometry> _computeLayoutGeometry(List<_LayoutEntry> entries) {
    if (entries.isEmpty) return const {};

    final sorted = entries.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
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
      final columnAssignments = _assignColumns(cluster);
      final concurrencyMap = _computeConcurrency(cluster);

      for (final entry in cluster) {
        final concurrency = concurrencyMap[entry.id] ?? 1;
        final widthFraction = 1 / concurrency;
        final columnIndex = columnAssignments[entry.id] ?? 0;
        final leftFraction = columnIndex * widthFraction;
        geometryMap[entry.id] = _EventGeometry(
          leftFraction: leftFraction,
          widthFraction: widthFraction,
        );
      }
    }

    return geometryMap;
  }

  Map<int, int> _assignColumns(List<_LayoutEntry> cluster) {
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

  Map<int, int> _computeConcurrency(List<_LayoutEntry> cluster) {
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
        // Process exits (-1) before entries (+1) at the same instant to avoid
        // over-counting appointments that only touch at boundaries.
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
}

class _LayoutEntry {
  const _LayoutEntry({required this.id, required this.start, required this.end});

  final int id;
  final DateTime start;
  final DateTime end;
}

class _EventGeometry {
  const _EventGeometry({required this.leftFraction, required this.widthFraction});

  final double leftFraction;
  final double widthFraction;
}

class _Edge {
  const _Edge(this.instant, this.delta);

  final DateTime instant;
  final int delta;
}
