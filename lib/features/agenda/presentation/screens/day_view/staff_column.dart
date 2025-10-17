import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
import '/../../../core/models/staff.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../widgets/agenda_dividers.dart';
import '../widgets/appointment_card.dart';

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
      final dragOffset = ref.read(dragOffsetProvider);

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
      if (box == null) return;

      final rect = box.localToGlobal(Offset.zero) & box.size;
      final inside = rect.contains(next);

      if (inside) {
        final local = box.globalToLocal(next);
        final double effectiveY = ((local.dy - (dragOffset ?? 0)).clamp(
          0,
          box.size.height,
        )).toDouble();

        setState(() {
          _hoverY = effectiveY;
          _isHighlighted = true;
        });
        highlightNotifier.set(widget.staff.id);

        final slotHeight = LayoutConfig.slotHeight;
        final minutesFromTop =
            (effectiveY / slotHeight) * LayoutConfig.minutesPerSlot;
        final roundedMinutes = (minutesFromTop / 5).round() * 5;

        final draggedId = ref.read(draggedAppointmentIdProvider);
        Duration duration;

        if (draggedId != null) {
          final appt = ref
              .read(appointmentsProvider)
              .firstWhere((a) => a.id == draggedId);
          duration = appt.endTime.difference(appt.startTime);
        } else {
          duration = const Duration(minutes: 30);
        }

        final today = DateTime.now();
        final start = DateTime(
          today.year,
          today.month,
          today.day,
        ).add(Duration(minutes: roundedMinutes.toInt()));
        final end = start.add(duration);

        tempTimeNotifier.setTimes(start, end);
      } else if (_isHighlighted) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slotHeight = ref.watch(layoutConfigProvider);
    final totalSlots = LayoutConfig.totalSlots;
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);

    final stackChildren = <Widget>[];

    // 🕓 Griglia oraria
    stackChildren.add(
      Column(
        children: List.generate(totalSlots, (index) {
          final slotsPerHour = 60 ~/ LayoutConfig.minutesPerSlot;
          final isHourStart = (index + 1) % slotsPerHour == 0;
          final isMainLine = (index + 1) % slotsPerHour == 0;
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
    stackChildren.addAll(_buildAppointments(slotHeight));

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
        final minutesFromTop =
            (localPosition.dy / slotHeight) * LayoutConfig.minutesPerSlot;
        final roundedMinutes = (minutesFromTop / 5).round() * 5;

        final duration = details.data.endTime.difference(
          details.data.startTime,
        );
        final today = DateTime.now();
        final newStart = DateTime(
          today.year,
          today.month,
          today.day,
        ).add(Duration(minutes: roundedMinutes.toInt()));
        final newEnd = newStart.add(duration);

        appointmentsNotifier.moveAppointment(
          appointmentId: details.data.id,
          newStaffId: widget.staff.id,
          newStart: newStart,
          newEnd: newEnd,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return SizedBox(
          width: widget.columnWidth,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _isHighlighted
                  ? widget.staff.color.withOpacity(0.05)
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
        );
      },
    );
  }

  List<Widget> _buildAppointments(double slotHeight) {
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final List<List<Appointment>> overlapGroups = [];

    // 🔹 Raggruppa appuntamenti che si sovrappongono
    for (final appt in widget.appointments) {
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

    final List<Widget> positionedAppointments = [];

    // 🔹 Costruisci i widget
    for (final group in overlapGroups) {
      final groupSize = group.length;
      for (int i = 0; i < groupSize; i++) {
        final a = group[i];
        final bool isDragged = a.id == draggedId;

        final startMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final endMinutes = a.endTime.hour * 60 + a.endTime.minute;

        final double top =
            (startMinutes / LayoutConfig.minutesPerSlot) * slotHeight;
        final double height =
            ((endMinutes - startMinutes) / LayoutConfig.minutesPerSlot) *
            slotHeight;

        double widthFraction = 1 / groupSize;
        double leftFraction = i * widthFraction;
        double opacity = 1.0;

        if (isDragged) {
          // 👻 Ghost → solo opacità ridotta, nessuna espansione
          opacity = AgendaTheme.ghostOpacity;
        }

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
                expandToLeft: i > 0, // ✅ destra → espansione verso sinistra
              ),
            ),
          ),
        );
      }
    }

    return positionedAppointments;
  }
}
