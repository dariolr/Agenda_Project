import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
import '/../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/layout_config_provider.dart';
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

      if (next == null) {
        if (_isHighlighted || _hoverY != null) {
          setState(() {
            _isHighlighted = false;
            _hoverY = null;
          });
        }
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
      } else if (_isHighlighted) {
        setState(() {
          _isHighlighted = false;
          _hoverY = null;
        });
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _dragListener.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slotHeight = ref.watch(layoutConfigProvider);
    final totalSlots = LayoutConfig.totalSlots;
    final slotsPerHour = (60 ~/ LayoutConfig.minutesPerSlot);
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);

    final stackChildren = <Widget>[];

    // 🕓 Griglia oraria
    stackChildren.add(
      Column(
        children: List.generate(totalSlots, (index) {
          final isHourStart = index % slotsPerHour == 0;
          return Container(
            height: slotHeight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(isHourStart ? 0.2 : 0.5),
                  width: isHourStart ? 0.5 : 1,
                ),
              ),
            ),
          );
        }),
      ),
    );

    // 🔹 Raggruppamento overlapping appuntamenti
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

    // 📅 Appuntamenti
    for (final group in overlapGroups) {
      final groupSize = group.length;
      for (int i = 0; i < groupSize; i++) {
        final a = group[i];
        final startMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final endMinutes = a.endTime.hour * 60 + a.endTime.minute;
        final top = (startMinutes / LayoutConfig.minutesPerSlot) * slotHeight;
        final height =
            ((endMinutes - startMinutes) / LayoutConfig.minutesPerSlot) *
            slotHeight;
        final widthFraction = 1 / groupSize;
        final leftFraction = i * widthFraction;

        stackChildren.add(
          Positioned(
            top: top,
            left: leftFraction * widget.columnWidth + 4,
            width: widget.columnWidth * widthFraction - 8,
            height: height,
            child: AppointmentCard(appointment: a, color: widget.staff.color),
          ),
        );
      }
    }

    // 🟢 Riga e orario durante il drag
    if (_isHighlighted && _hoverY != null) {
      final slotMinutes = LayoutConfig.minutesPerSlot;
      final minutesFromTop = (_hoverY! / slotHeight) * slotMinutes;
      final roundedMinutes = (minutesFromTop / 5).round() * 5;
      final hour = roundedMinutes ~/ 60;
      final minute = roundedMinutes % 60;
      final formatted =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      stackChildren.addAll([
        Positioned(
          top: _hoverY!.clamp(0, totalSlots * slotHeight),
          left: 0,
          right: 0,
          child: Container(
            height: 1.2,
            color: widget.staff.color.withOpacity(0.55),
          ),
        ),
        Positioned(
          top: (_hoverY! - 20).clamp(0, totalSlots * slotHeight - 20),
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

    return DragTarget<Appointment>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isHighlighted = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHighlighted = false),
      onAcceptWithDetails: (details) {
        setState(() {
          _isHighlighted = false;
          _hoverY = null;
        });

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
        return Stack(
          children: [
            // 🔹 Contenuto scrollabile
            SizedBox(
              width: widget.columnWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: widget.showRightBorder
                      ? Border(
                          right: BorderSide(
                            color: Colors.grey.withOpacity(0.25),
                            width: 0.5,
                          ),
                        )
                      : null,
                  boxShadow: _isHighlighted
                      ? [
                          BoxShadow(
                            color: widget.staff.color.withOpacity(0.08),
                            blurRadius: 14,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : [],
                ),
                child: Stack(children: stackChildren),
              ),
            ),

            // 🔹 Badge staff — fisso in alto
            // TODO: fisso in alto ma senza scrollare via
            if (_isHighlighted)
              Positioned(
                top: 6,
                left: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.staff.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.staff.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
