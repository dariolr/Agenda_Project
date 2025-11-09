import 'dart:async';
import 'dart:math' as math;

import 'package:agenda_frontend/features/agenda/providers/dragged_card_size_provider.dart';
import 'package:agenda_frontend/features/services/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '/core/models/staff.dart';
import '/core/utils/color_utils.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/drag_session_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/dragged_base_range_provider.dart';
import '../../../providers/dragged_last_staff_provider.dart';
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/resizing_provider.dart';
import '../../../providers/selected_appointment_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../widgets/agenda_dividers.dart';
import '../widgets/appointment_card_base.dart';
import 'drag_drop_helper.dart';
import 'layout_geometry_helper.dart';

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
  late final HighlightedStaffIdNotifier _highlightedNotifier;
  late final StaffColumnsGeometryNotifier _geometryNotifier;
  late final ProviderSubscription<int?> _highlightSubscription;
  int? _latestHighlightedId;

  // 1. Aggiunta sottoscrizione per il layout
  late final ProviderSubscription<LayoutConfig> _layoutConfigSub;

  @override
  void initState() {
    super.initState();

    _highlightedNotifier = ref.read(highlightedStaffIdProvider.notifier);
    _geometryNotifier = ref.read(staffColumnsGeometryProvider.notifier);
    _latestHighlightedId = ref.read(highlightedStaffIdProvider);
    _highlightSubscription = ref.listenManual<int?>(
      highlightedStaffIdProvider,
      (previous, next) => _latestHighlightedId = next,
    );

    // 2. Pianifica l'aggiornamento della geometria dopo il primo frame
    _scheduleGeometryUpdate();

    // 3. Ascolta i cambi di layout per ri-pianificare l'aggiornamento
    _layoutConfigSub = ref.listenManual<LayoutConfig>(layoutConfigProvider, (
      prev,
      next,
    ) {
      // Aggiorna la geometria solo se le dimensioni cambiano
      if (prev == null ||
          prev.slotHeight != next.slotHeight ||
          prev.headerHeight != next.headerHeight) {
        _scheduleGeometryUpdate();
      }
    });

    _dragListener = ref.listenManual<Offset?>(dragPositionProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      final tempTimeNotifier = ref.read(tempDragTimeProvider.notifier);

      if (next == null) {
        if (_isHighlighted || _hoverY != null) {
          setState(() {
            _isHighlighted = false;
            _hoverY = null;
          });
        }
        _highlightedNotifier.clear();
        tempTimeNotifier.clear();
        return;
      }

      final box = context.findRenderObject() as RenderBox?;
      final bodyBox = ref.read(dragBodyBoxProvider);
      if (box == null || bodyBox == null) return;

      final columnTopLeftInBody = bodyBox.globalToLocal(
        box.localToGlobal(Offset.zero),
      );

      // ✅ Aggiorna la geometria solo se cambia realmente (scroll o resize)
      final newRect = Rect.fromLTWH(
        columnTopLeftInBody.dx,
        columnTopLeftInBody.dy,
        box.size.width,
        box.size.height,
      );

      if (_lastGeometryRect == null ||
          (newRect.top - _lastGeometryRect!.top).abs() > 0.5 ||
          (newRect.left - _lastGeometryRect!.left).abs() > 0.5 ||
          (newRect.width - _lastGeometryRect!.width).abs() > 0.5 ||
          (newRect.height - _lastGeometryRect!.height).abs() > 0.5) {
        _lastGeometryRect = newRect;
        _geometryNotifier.setRect(widget.staff.id, newRect);
      }

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
        final clampedLocalDy = localInColumn.dy.clamp(
          0.0,
          box.size.height.toDouble(),
        );
        final double effectiveY = (clampedLocalDy - (dragOffset ?? 0))
            .clamp(0, maxYStartPx)
            .toDouble();

        setState(() {
          _hoverY = effectiveY;
          _isHighlighted = true;
        });
        _highlightedNotifier.set(widget.staff.id);
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
        final maxStartMinutesNum = (totalMinutes - durationMinutes).clamp(
          0,
          totalMinutes,
        );

        if (roundedMinutes > maxStartMinutesNum) {
          roundedMinutes = maxStartMinutesNum.toDouble();
        } else if (roundedMinutes < 0) {
          roundedMinutes = 0;
        }

        final startMinutes = roundedMinutes.toInt();
        final endMinutes = (startMinutes + durationMinutes)
            .clamp(0, totalMinutes)
            .toInt();

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
        _highlightedNotifier.clear();
        tempTimeNotifier.clear();
      }
    }, fireImmediately: false);
  }

  bool _geometryInitialized = false;
  Timer? _geometryDebounce;
  Rect? _lastGeometryRect;

  void _scheduleGeometryUpdate() {
    // Se già inizializzato e debounce attivo, salta
    if (_geometryInitialized && _geometryDebounce != null) return;

    _geometryDebounce?.cancel();
    _geometryDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final bodyBox = ref.read(dragBodyBoxProvider);
      if (box == null || bodyBox == null) return;
      if (!box.attached || !bodyBox.attached) return;

      final topLeft = bodyBox.globalToLocal(box.localToGlobal(Offset.zero));
      final newRect = Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        box.size.width,
        box.size.height,
      );

      // ignora microvariazioni
      if (_lastGeometryRect != null &&
          (newRect.top - _lastGeometryRect!.top).abs() < 1.0 &&
          (newRect.left - _lastGeometryRect!.left).abs() < 1.0 &&
          (newRect.width - _lastGeometryRect!.width).abs() < 1.0 &&
          (newRect.height - _lastGeometryRect!.height).abs() < 1.0) {
        return;
      }

      _lastGeometryRect = newRect;
      _geometryInitialized = true; // ✅ segna come inizializzato
      debugPrint('[Geometry] Updated for staff ${widget.staff.name}');
      _geometryNotifier.setRect(widget.staff.id, newRect);
    });
  }

  @override
  void dispose() {
    _dragListener.close();
    _highlightSubscription.close();
    _layoutConfigSub.close(); // 5. Ricorda di chiudere la sottoscrizione
    final shouldClearHighlight = _latestHighlightedId == widget.staff.id;
    final staffId = widget.staff.id;
    Future.microtask(() {
      if (shouldClearHighlight) {
        _highlightedNotifier.clear();
      }
      _geometryNotifier.clearFor(staffId);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAppointments = ref.watch(appointmentsForCurrentLocationProvider);
    final staffAppointments = allAppointments
        .where((a) => a.staffId == widget.staff.id)
        .toList();

    // 6. RIMOSSO il blocco addPostFrameCallback da qui

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
        final pointerGlobal = details.offset + Offset(dragOffsetX, dragOffsetY);
        final localPointer = box.globalToLocal(pointerGlobal);
        final draggedCardHeightPx =
            ref.read(draggedCardSizeProvider)?.height ?? 50.0;

        final dropResult = computeDropResult(
          DropComputationParams(
            appointment: details.data,
            layoutConfig: layoutConfig,
            columnHeight: box.size.height,
            localPointer: localPointer,
            dragOffsetY: dragOffsetY,
            draggedCardHeightPx: draggedCardHeightPx,
            previewTimes: previewTimes,
          ),
        );

        ref.read(dragSessionProvider.notifier).markHandled();
        appointmentsNotifier.moveAppointment(
          appointmentId: details.data.id,
          newStaffId: widget.staff.id,
          newStart: dropResult.newStart,
          newEnd: dropResult.newEnd,
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
                          width: 1.0,
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
      if (!added) {
        overlapGroups.add([appt]);
      }
    }

    final positionedAppointments = <Widget>[];

    final originalAppointmentsMap = {for (var a in appointments) a.id: a};
    final layoutEntries = layoutAppointments
        .map((a) => LayoutEntry(id: a.id, start: a.startTime, end: a.endTime))
        .toList();
    final layoutGeometry = computeLayoutGeometry(
      layoutEntries,
      useClusterMaxConcurrency: layoutConfig.useClusterMaxConcurrency,
    );

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

        final startMinutes = originalAppt.startTime
            .difference(dayStart)
            .inMinutes;

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

        final geometry =
            layoutGeometry[originalAppt.id] ??
            const EventGeometry(leftFraction: 0, widthFraction: 1);
        double opacity = isDragged ? AgendaTheme.ghostOpacity : 1.0;

        // 🔹 Costruisci la card
        final padding = LayoutConfig.columnInnerPadding;
        final fullColumnWidth = math.max(widget.columnWidth - padding * 2, 0.0);
        final cardLeft = widget.columnWidth * geometry.leftFraction + padding;
        final cardWidth = math.max(
          widget.columnWidth * geometry.widthFraction - padding * 2,
          0.0,
        );

        Color cardColor = widget.staff.color;
        if (layoutConfig.useServiceColorsForAppointments) {
          final variant = ref.watch(
            serviceVariantByIdProvider(originalAppt.serviceVariantId),
          );
          if (variant != null && variant.colorHex != null) {
            cardColor = ColorUtils.fromHex(variant.colorHex!);
          } else {
            final services = ref.watch(servicesProvider);
            for (final service in services) {
              if (service.id == originalAppt.serviceId &&
                  service.color != null) {
                cardColor = service.color!;
                break;
              }
            }
          }
        }

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
                color: cardColor,
                columnWidth: cardWidth,
                columnOffset: cardLeft,
                dragTargetWidth: fullColumnWidth,
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
}
