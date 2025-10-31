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
        final slotHeight = LayoutConfig.slotHeight;

        // minuti dall'inizio giornata (00:00)
        final minutesFromTop =
            (effectiveY / slotHeight) * LayoutConfig.minutesPerSlot;

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
        final headerHeight = LayoutConfig.headerHeight;
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

    final slotHeight = ref.watch(layoutConfigProvider);
    final totalSlots = LayoutConfig.totalSlots;
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);

    final stackChildren = <Widget>[];

    // 🔹 Griglia oraria
    stackChildren.add(
      Column(
        children: List.generate(totalSlots, (index) {
          final slotsPerHour = 60 ~/ LayoutConfig.minutesPerSlot;
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
        setState(() {
          _isHighlighted = false;
          _hoverY = null;
        });
        ref.read(highlightedStaffIdProvider.notifier).clear();
        ref.read(tempDragTimeProvider.notifier).clear();

        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;

        final localPosition = box.globalToLocal(details.offset);
        double effectiveDy = localPosition.dy;
        if (effectiveDy <= 0.0) effectiveDy = 0.1;

        final minutesFromTop =
            (effectiveDy / slotHeight) * LayoutConfig.minutesPerSlot;
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

        DateTime newStart = baseDate.add(Duration(minutes: startMinutes));
        DateTime newEnd = baseDate.add(Duration(minutes: endMinutes));

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

    final List<List<Appointment>> overlapGroups = [];

    for (final appt in appointments) {
      bool added = false;
      for (final group in overlapGroups) {
        if (group.any(
          (g) =>
              appt.startTime.isBefore(g.endTime) &&
              appt.endTime.isAfter(g.startTime),
        )) {
          group.add(appt);
          added = true;
          break;
        }
      }
      if (!added) overlapGroups.add([appt]);
    }

    final positionedAppointments = <Widget>[];

    for (final group in overlapGroups) {
      final groupSize = group.length;
      for (int i = 0; i < groupSize; i++) {
        final a = group[i];
        final isDragged = a.id == draggedId;

        final dayStart = DateTime(
          a.startTime.year,
          a.startTime.month,
          a.startTime.day,
        );

        final startMinutes = a.startTime.difference(dayStart).inMinutes;
        final endMinutes = a.endTime.difference(dayStart).inMinutes;

        final double top =
            (startMinutes / LayoutConfig.minutesPerSlot) * slotHeight;
        double height =
            ((endMinutes - startMinutes) / LayoutConfig.minutesPerSlot) *
            slotHeight;

        final entry = ref.watch(resizingEntryProvider(a.id));
        if (entry != null) {
          if (a.endTime != entry.provisionalEndTime) {
            height = entry.currentPreviewHeightPx;
          }
        }

        // 🔹 Gestione overlap orizzontale
        double widthFraction = 1 / groupSize;
        double leftFraction = i * widthFraction;
        double opacity = isDragged ? AgendaTheme.ghostOpacity : 1.0;

        // 🔹 Costruisci la card
        positionedAppointments.add(
          Positioned(
            top: top,
            left: leftFraction * widget.columnWidth + 2,
            width: widget.columnWidth * widthFraction - 4,
            height: height,
            child: Opacity(
              opacity: opacity,
              child: AppointmentCard(
                appointment: a,
                color: widget.staff.color,
                columnWidth: widget.columnWidth,
                expandToLeft: i > 0,
              ),
            ),
          ),
        );
      }
    }

    return positionedAppointments;
  }
}
