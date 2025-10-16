import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
import '/../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/layout_config_provider.dart';
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

      if (next == null) {
        if (_isHighlighted || _hoverY != null) {
          setState(() {
            _isHighlighted = false;
            _hoverY = null;
          });
        }
        highlightNotifier.clear();
        return;
      }

      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final rect = box.localToGlobal(Offset.zero) & box.size;
      final inside = rect.contains(next);

      if (inside) {
        final local = box.globalToLocal(next);
        setState(() {
          _hoverY = local.dy;
          _isHighlighted = true;
        });
        highlightNotifier.set(widget.staff.id);
      } else if (_isHighlighted) {
        setState(() {
          _isHighlighted = false;
          _hoverY = null;
        });
        highlightNotifier.clear();
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

    // Griglia oraria
    stackChildren.add(
      Column(
        children: List.generate(totalSlots, (index) {
          final slotsPerHour = 60 ~/ LayoutConfig.minutesPerSlot;
          final isHourStart = index % slotsPerHour == 0;
          return SizedBox(
            height: slotHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: AgendaHorizontalDivider(
                color: Colors.grey.withOpacity(isHourStart ? 0.2 : 0.5),
                thickness: isHourStart ? 0.5 : 1,
              ),
            ),
          );
        }),
      ),
    );

    stackChildren.addAll(_buildAppointments(slotHeight));

    // 🔴 Linea e badge durante il drag
    if (_isHighlighted && _hoverY != null) {
      // 👇 offset fisso: badge e linea allineati al bordo superiore
      final dragged = ref.read(appointmentsProvider).isNotEmpty
          ? ref.read(appointmentsProvider).first
          : null;

      final durationMinutes = dragged?.totalDuration ?? 30;
      final offset =
          (durationMinutes / LayoutConfig.minutesPerSlot) * slotHeight / 2;
      final double adjustedY = (_hoverY! - slotHeight).clamp(
        0,
        totalSlots * slotHeight,
      );

      final slotMinutes = LayoutConfig.minutesPerSlot;
      final minutesFromTop = (adjustedY / slotHeight) * slotMinutes;
      final roundedMinutes = (minutesFromTop / 5).round() * 5;
      final hour = roundedMinutes ~/ 60;
      final minute = roundedMinutes % 60;
      final formatted =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      const double badgeOffset = 15; // prova valori tra 15 e 22

      stackChildren.addAll([
        Positioned(
          top: (adjustedY - 25).clamp(0, totalSlots * slotHeight - 25),

          left: 0,
          right: 0,
          child: Container(
            height: 1.2,
            color: widget.staff.color.withOpacity(0.55),
          ),
        ),
        Positioned(
          top: (adjustedY - badgeOffset).clamp(
            0,
            totalSlots * slotHeight - badgeOffset,
          ),
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formatted,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ]);
    }

    // Container principale
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

        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;

        final localPosition = box.globalToLocal(details.offset);
        final minutesFromTop =
            (localPosition.dy / slotHeight) * LayoutConfig.minutesPerSlot;
        final roundedMinutes = (minutesFromTop / 5).round() * 5;

        final duration = details.data.endTime.difference(
          details.data.startTime,
        );
        final dayStart = 0;
        final dayEnd = LayoutConfig.totalSlots * LayoutConfig.minutesPerSlot;
        final safeStartMinutes = roundedMinutes.clamp(
          dayStart,
          dayEnd - duration.inMinutes,
        );

        final today = DateTime.now();
        final newStart = DateTime(
          today.year,
          today.month,
          today.day,
        ).add(Duration(minutes: safeStartMinutes));
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
                        color: Colors.grey.withOpacity(0.25),
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

  /// Gestione overlapping
  List<Widget> _buildAppointments(double slotHeight) {
    final List<List<Appointment>> overlapGroups = [];

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
    for (final group in overlapGroups) {
      final groupSize = group.length;
      for (int i = 0; i < groupSize; i++) {
        final a = group[i];
        final startMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final endMinutes = a.endTime.hour * 60 + a.endTime.minute;

        final double top =
            (startMinutes / LayoutConfig.minutesPerSlot) * slotHeight;
        final double height =
            ((endMinutes - startMinutes) / LayoutConfig.minutesPerSlot) *
            slotHeight;

        final double widthFraction = 1 / groupSize;
        final double leftFraction = i * widthFraction;

        positionedAppointments.add(
          Positioned(
            top: top,
            left: leftFraction * widget.columnWidth + 2,
            width: widget.columnWidth * widthFraction - 4,
            height: height,
            child: AppointmentCard(appointment: a, color: widget.staff.color),
          ),
        );
      }
    }

    return positionedAppointments;
  }
}
