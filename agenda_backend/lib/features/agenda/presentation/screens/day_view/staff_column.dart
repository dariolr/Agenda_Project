
import 'dart:async';
import 'dart:math' as math;

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/service_variant.dart';
import 'package:agenda_backend/core/widgets/adaptive_dropdown.dart';
import 'package:agenda_backend/core/widgets/feedback_dialog.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/hover_slot.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/unavailable_slot_pattern.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/agenda/providers/dragged_card_size_provider.dart';
import 'package:agenda_backend/features/agenda/providers/pending_drop_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_slot_availability_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/class_events/providers/class_events_providers.dart';
import 'package:agenda_backend/features/class_events/presentation/class_events_screen.dart';
import 'package:agenda_backend/features/clients/providers/clients_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '/core/models/class_event.dart';
import '/core/models/class_type.dart';
import '/core/models/staff.dart';
import '/core/models/time_block.dart';
import '/core/utils/color_utils.dart';
import '/core/utils/price_utils.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/agenda_card_color_source.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/agenda_display_settings_provider.dart';
import '../../../providers/agenda_scroll_request_provider.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/business_providers.dart';
import '../../../providers/block_resizing_provider.dart';
import '../../../providers/booking_reschedule_provider.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/drag_session_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/dragged_base_range_provider.dart';
import '../../../providers/dragged_last_staff_provider.dart';
import '../../../providers/fully_occupied_slots_provider.dart';
import '../../../providers/highlighted_staff_provider.dart';
// Nota: isResizingProvider viene gestito a un livello superiore (MultiStaffDayView),
// non è necessario importarlo qui.
import '../../../providers/layout_config_provider.dart';
import '../../../providers/location_providers.dart';
import '../../../providers/resizing_provider.dart';
import '../../../providers/selected_appointment_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../../../providers/tenant_time_provider.dart';
import '../../../providers/time_blocks_provider.dart';
import '../../../utils/client_color_utils.dart';
import '../../utils/multi_service_move_guard.dart';
import '../../dialogs/add_block_dialog.dart';
import '../../widgets/booking_dialog.dart';
import '../helper/drag_drop_helper.dart';
import '../helper/layout_geometry_helper.dart';
import '../widgets/agenda_dividers.dart';
import '../widgets/appointment_card_base.dart';
import '../widgets/time_block_widget.dart';

Color? _parseClassTypeColor(String? hex) {
  final value = hex?.trim() ?? '';
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
    return null;
  }
  try {
    return ColorUtils.fromHex(value);
  } catch (_) {
    return null;
  }
}

class StaffColumn extends ConsumerStatefulWidget {
  final Staff staff;
  final List<Appointment> appointments;
  final double columnWidth;
  final bool showRightBorder;
  final bool isInteractionLocked;

  const StaffColumn({
    super.key,
    required this.staff,
    required this.appointments,
    required this.columnWidth,
    required this.isInteractionLocked,
    this.showRightBorder = true,
  });

  @override
  ConsumerState<StaffColumn> createState() => _StaffColumnState();
}

class _StaffColumnState extends ConsumerState<StaffColumn> {
  bool _isHighlighted = false;
  int? _hoveredSlotIndex;
  double? _hoverY;
  bool _isApplyingBookingReschedule = false;
  int? _hoveredClassEventId;
  int? _resizeHoveredClassEventId;
  int? _hoveredTimeBlockId;
  int? _draggingClassEventId;
  final Map<int, DateTime> _classResizePreviewEndByEventId = {};
  _ClassEventResizeSession? _classResizeSession;
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
        // minuti dall'inizio giornata (00:00)
        final minutesFromTop = layoutConfig.minutesFromHeight(effectiveY);

        // arrotondiamo a step di 5 minuti
        double roundedMinutes = (minutesFromTop / 5).round() * 5;

        // durata dell'appuntamento trascinato
        final draggedId = ref.read(draggedAppointmentIdProvider);
        Duration duration;
        DateTime baseDate;
        if (draggedId != null) {
          final appt = ref
              .read(appointmentsProvider)
              .requireValue
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
            final now = ref.read(tenantNowProvider);
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
    _classResizeSession = null;
    _classResizePreviewEndByEventId.clear();
    super.dispose();
  }

  String _toApiLocalDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }

  Future<void> _updateClassEventTiming({
    required int classEventId,
    required DateTime newStart,
    required DateTime newEnd,
    required int staffId,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;
    final repo = ref.read(classEventsRepositoryProvider);
    await repo.update(
      businessId: businessId,
      classEventId: classEventId,
      payload: {
        'starts_at': _toApiLocalDateTime(newStart),
        'ends_at': _toApiLocalDateTime(newEnd),
        'staff_id': staffId,
      },
    );
    ref.invalidate(classEventsProvider);
    ref.invalidate(classEventsForRangeProvider);
    ref.invalidate(classEventsForCurrentLocationDayProvider);
  }

  bool _isClassResizeHotzone({
    required double localDy,
    required double cardHeight,
  }) {
    const resizeHandleHeight = 18.0;
    return localDy >= (cardHeight - resizeHandleHeight).clamp(0.0, cardHeight);
  }

  void _startClassResize({
    required ClassEvent event,
    required DateTime startsAt,
    required DateTime initialEndsAt,
    required DragStartDetails details,
    required double cardHeight,
  }) {
    final local = details.localPosition;
    if (!_isClassResizeHotzone(localDy: local.dy, cardHeight: cardHeight)) {
      return;
    }
    _classResizeSession = _ClassEventResizeSession(
      eventId: event.id,
      staffId: event.staffId,
      startsAt: startsAt,
      initialEndsAt: initialEndsAt,
      initialGlobalDy: details.globalPosition.dy,
    );
    setState(() {
      _classResizePreviewEndByEventId[event.id] = initialEndsAt;
    });
  }

  void _updateClassResize(DragUpdateDetails details) {
    final session = _classResizeSession;
    if (session == null) return;
    final layoutConfig = ref.read(layoutConfigProvider);
    final step = layoutConfig.minutesPerSlot;
    final deltaY = details.globalPosition.dy - session.initialGlobalDy;
    final rawDeltaMinutes = layoutConfig.minutesFromHeight(deltaY.abs());
    final signedDeltaMinutes = deltaY.isNegative
        ? -rawDeltaMinutes
        : rawDeltaMinutes;
    final snappedDeltaMinutes = ((signedDeltaMinutes / step).round() * step)
        .toInt();
    var nextEnd = session.initialEndsAt.add(
      Duration(minutes: snappedDeltaMinutes),
    );
    final minEnd = session.startsAt.add(Duration(minutes: step));
    final dayBoundary = DateTime(
      session.startsAt.year,
      session.startsAt.month,
      session.startsAt.day,
    ).add(const Duration(days: 1));
    if (nextEnd.isBefore(minEnd)) nextEnd = minEnd;
    if (nextEnd.isAfter(dayBoundary)) nextEnd = dayBoundary;
    setState(() {
      _classResizePreviewEndByEventId[session.eventId] = nextEnd;
    });
  }

  Future<void> _commitClassResize() async {
    final session = _classResizeSession;
    if (session == null) return;
    final previewEnd = _classResizePreviewEndByEventId[session.eventId];
    _classResizeSession = null;
    if (previewEnd == null || previewEnd == session.initialEndsAt) {
      setState(() {
        _classResizePreviewEndByEventId.remove(session.eventId);
      });
      return;
    }
    try {
      await _updateClassEventTiming(
        classEventId: session.eventId,
        newStart: session.startsAt,
        newEnd: previewEnd,
        staffId: session.staffId,
      );
    } catch (_) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.classEventsCreateErrorMessage,
      );
    } finally {
      if (mounted) {
        setState(() {
          _classResizePreviewEndByEventId.remove(session.eventId);
        });
      }
    }
  }

  void _cancelClassResize() {
    final session = _classResizeSession;
    _classResizeSession = null;
    if (session == null) return;
    setState(() {
      _classResizePreviewEndByEventId.remove(session.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allAppointments = ref.watch(appointmentsForCurrentLocationProvider);
    final staffAppointments = allAppointments
        .where((a) => a.staffId == widget.staff.id)
        .toList();
    final classEventsAsync = ref.watch(classEventsForCurrentLocationDayProvider);
    final allClassEvents = (classEventsAsync.isLoading && !classEventsAsync.hasValue)
        ? const <ClassEvent>[]
        : (classEventsAsync.value ?? const <ClassEvent>[]);
    final classTypes = ref.watch(classTypesProvider).value ?? const [];
    final classTypeById = <int, ClassType>{
      for (final classType in classTypes) classType.id: classType,
    };
    final staffClassEvents = allClassEvents
        .where(
          (event) =>
              event.staffId == widget.staff.id &&
              event.status.toUpperCase() != 'CANCELLED',
        )
        .toList();

    // 6. RIMOSSO il blocco addPostFrameCallback da qui

    final layoutConfig = ref.watch(layoutConfigProvider);
    final expandColumnsOnOverlap = ref.watch(
      agendaExpandStaffColumnsOnOverlapProvider,
    );
    final staffBlocks = ref.watch(timeBlocksForStaffProvider(widget.staff.id));

    // Geometria unificata: tutti i tipi di card (appuntamenti, classi, blocchi)
    // vengono messi in un unico pool prima di computeLayoutGeometry, così gli
    // overlap cross-tipo vengono rilevati e le card si affiancano correttamente.
    final allDayEntries = <LayoutEntry>[
      ...staffAppointments.map(
        (a) => LayoutEntry(id: a.id, start: a.startTime, end: a.endTime),
      ),
      ...staffClassEvents.map(
        (e) => LayoutEntry(
          id: _classEventLayoutId(e.id),
          start: e.startsAtLocal ?? e.startsAtUtc.toLocal(),
          end: e.endsAtLocal ?? e.endsAtUtc.toLocal(),
        ),
      ),
      ...staffBlocks.map(
        (b) => LayoutEntry(
          id: _blockLayoutId(b.id),
          start: b.startTime,
          end: b.endTime,
        ),
      ),
    ];
    final int maxDayConcurrency = expandColumnsOnOverlap
        ? computeMaxConcurrency(allDayEntries)
        : 1;
    final unifiedGeometry = computeLayoutGeometry(
      allDayEntries,
      useClusterMaxConcurrency: expandColumnsOnOverlap
          ? false
          : layoutConfig.useClusterMaxConcurrency,
      minTotalColumns: maxDayConcurrency,
    );

    final slotHeight = layoutConfig.slotHeight;
    final totalSlots = layoutConfig.totalSlots;
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final agendaDate = ref.watch(agendaDateProvider);
    final canManageBookings = ref.watch(currentUserCanManageBookingsProvider);
    final showPrices = ref.watch(effectiveShowAppointmentPriceInCardProvider);

    // Interaction lock propagated from parent (evaluated once per visible group)
    final isInteractionLocked = widget.isInteractionLocked;
    final rescheduleSession = ref.watch(bookingRescheduleSessionProvider);

    // 🔹 Calcola slot pieni PRIMA del layout (solo desktop e se abilitato)
    final formFactor = ref.watch(formFactorProvider);
    final bool showAddButtonStrip =
        layoutConfig.enableOccupiedSlotStrip &&
        formFactor == AppFormFactor.desktop &&
        !isInteractionLocked &&
        canManageBookings;
    final fullyOccupied = showAddButtonStrip
        ? ref.watch(fullyOccupiedSlotsProvider(widget.staff.id))
        : const <int>{};
    final hasFullyOccupiedSlots = fullyOccupied.isNotEmpty;

    // Larghezza disponibile per le card (ridotta se ci sono slot pieni)
    final addButtonWidth = hasFullyOccupiedSlots
        ? LayoutConfig.addButtonStripWidth
        : 0.0;
    final rightBorderCompensation = widget.showRightBorder ? 1.0 : 0.0;
    final effectiveColumnWidth =
        (widget.columnWidth - addButtonWidth - rightBorderCompensation)
            .clamp(0.0, double.infinity)
            .toDouble();

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

    // 🔹 Layer slot non disponibili (texture pattern)
    final unavailableRanges = ref.watch(
      unavailableSlotRangesProvider(widget.staff.id),
    );
    if (unavailableRanges.isNotEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      final totalHeight = layoutConfig.totalHeight;
      stackChildren.add(
        IgnorePointer(
          child: SizedBox(
            height: totalHeight,
            width: double.infinity,
            child: Stack(
              children: [
                for (final range in unavailableRanges)
                  Positioned(
                    top: layoutConfig.heightForMinutes(
                      range.startIndex * layoutConfig.minutesPerSlot,
                    ),
                    left: 0,
                    right: 0,
                    child: UnavailableSlotRange(
                      slotCount: range.count,
                      slotHeight: slotHeight,
                      patternColor: AgendaTheme.unavailablePatternColor(
                        colorScheme,
                      ),
                      backgroundColor: AgendaTheme.unavailableBackgroundColor(
                        colorScheme,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // 🔹 Layer interattivo HoverSlot (effetto all'hover del mouse)
    stackChildren.add(
      IgnorePointer(
        ignoring: false, // permette l'hover
        child: Column(
          children: List.generate(totalSlots, (index) {
            final slotTime = agendaDate.add(
              Duration(minutes: index * layoutConfig.minutesPerSlot),
            );
            if (!isInteractionLocked && canManageBookings) {
              return LazyHoverSlot(
                slotTime: slotTime,
                height: slotHeight,
                colorPrimary1: Theme.of(context).colorScheme.primary,
                onVisibilityChanged: (isVisible) {
                  if (isVisible) {
                    if (_hoveredSlotIndex == index) return;
                    setState(() {
                      _hoveredSlotIndex = index;
                    });
                    return;
                  }
                  if (_hoveredSlotIndex != index) return;
                  setState(() {
                    _hoveredSlotIndex = null;
                  });
                },
                onTap: (dt) => _handleSlotTap(
                  dt: dt,
                  rescheduleSession: rescheduleSession,
                ),
                onSecondaryTapDown: (dt, details) => _handleSlotSecondaryTap(
                  dt: dt,
                  details: details,
                  appointments: staffAppointments,
                  classEvents: staffClassEvents,
                  blocks: staffBlocks,
                  minutesPerSlot: layoutConfig.minutesPerSlot,
                ),
                onLongPressStart: (dt, details) => _handleSlotLongPress(
                  dt: dt,
                  details: details,
                ),
              );
            }

            // Mantieni lo spazio vuoto per evitare salti nel layout.
            return SizedBox(height: slotHeight, width: double.infinity);
          }),
        ),
      ),
    );

    final staffDailyTotal = _computeStaffDailyTotal(
      staffAppointments: staffAppointments,
      classEvents: staffClassEvents,
    );
    final staffDailyServicesCount = _computeStaffDailyServicesCount(
      staffAppointments: staffAppointments,
      classEvents: staffClassEvents,
    );
    if (showPrices && staffDailyTotal > 0) {
      final availableSlots = ref.watch(
        staffSlotAvailabilityProvider(widget.staff.id),
      );
      final totalSlotIndex = _resolveDailyTotalSlotIndex(
        agendaDate: agendaDate,
        totalSlots: totalSlots,
        minutesPerSlot: layoutConfig.minutesPerSlot,
        availableSlots: availableSlots,
        appointments: staffAppointments,
        classEvents: staffClassEvents,
        blocks: staffBlocks,
      );

      if (totalSlotIndex != null && _hoveredSlotIndex != totalSlotIndex) {
        final currencyCode = PriceFormatter.effectiveCurrency(ref);
        final formattedTotal = PriceFormatter.format(
          context: context,
          amount: staffDailyTotal,
          currencyCode: currencyCode,
        );
        stackChildren.add(
          _buildDailyTotalTrademark(
            slotIndex: totalSlotIndex,
            slotHeight: slotHeight,
            minutesPerSlot: layoutConfig.minutesPerSlot,
            servicesCount: staffDailyServicesCount,
            formattedTotal: formattedTotal,
          ),
        );
      }
    }

    // 🔹 Blocchi di non disponibilità
    stackChildren.addAll(
      _buildTimeBlocks(
        slotHeight,
        effectiveColumnWidth,
        unifiedGeometry,
        expandColumnsOnOverlap,
      ),
    );

    // 🔹 Appuntamenti + classi (con larghezza ridotta se ci sono slot pieni)
    stackChildren.addAll(
      _buildScheduledEntries(
        slotHeight,
        staffAppointments,
        staffClassEvents,
        effectiveColumnWidth,
        classTypeById,
        unifiedGeometry,
        expandColumnsOnOverlap,
      ),
    );

    // La fascia laterale è già riservata riducendo effectiveColumnWidth,
    // quindi le card si restringono automaticamente lasciando spazio a destra.

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        if (!canManageBookings) return false;
        final data = details.data;
        if (data is! Appointment && data is! _ClassEventDragData && data is! TimeBlock) {
          return false;
        }
        setState(() => _isHighlighted = true);
        ref.read(highlightedStaffIdProvider.notifier).set(widget.staff.id);
        return true;
      },
      onLeave: (_) {
        setState(() => _isHighlighted = false);
        ref.read(highlightedStaffIdProvider.notifier).clear();
      },
      onAcceptWithDetails: (details) async {
        if (!canManageBookings) {
          return;
        }
        final dragged = details.data;
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

        if (dragged is _ClassEventDragData) {
          final duration = dragged.originalEnd.difference(
            dragged.originalStart,
          );
          final durationMinutes = math.max(
            duration.inMinutes,
            layoutConfig.minutesPerSlot,
          );
          final slotStepMinutes = layoutConfig.minutesPerSlot;
          final totalMinutes = LayoutConfig.hoursInDay * 60;
          final rawMinutes = layoutConfig.minutesFromHeight(localPointer.dy);
          final roundedMinutes =
              (((rawMinutes / slotStepMinutes).round() * slotStepMinutes).clamp(
                0,
                math.max(totalMinutes - durationMinutes, 0),
              )).toInt();
          final dayStart = DateTime(
            agendaDate.year,
            agendaDate.month,
            agendaDate.day,
          );
          final newStart = dayStart.add(Duration(minutes: roundedMinutes));
          final newEnd = newStart.add(Duration(minutes: durationMinutes));
          final hasStaffChanged = dragged.originalStaffId != widget.staff.id;
          final hasTimeChanged =
              dragged.originalStart != newStart ||
              dragged.originalEnd != newEnd;
          if (!hasStaffChanged && !hasTimeChanged) return;
          final classMutationErrorTitle = context.l10n.errorTitle;
          final classMutationErrorMessage =
              context.l10n.classEventsCreateErrorMessage;
          try {
            await _updateClassEventTiming(
              classEventId: dragged.eventId,
              newStart: newStart,
              newEnd: newEnd,
              staffId: widget.staff.id,
            );
          } catch (_) {
            if (!context.mounted) return;
            await FeedbackDialog.showError(
              context,
              title: classMutationErrorTitle,
              message: classMutationErrorMessage,
            );
          }
          return;
        }

        if (dragged is TimeBlock) {
          final block = dragged;
          if (block.isAllDay) return;
          final duration = block.endTime.difference(block.startTime);
          final durationMinutes = math.max(
            duration.inMinutes,
            layoutConfig.minutesPerSlot,
          );
          final slotStepMinutes = layoutConfig.minutesPerSlot;
          final totalMinutes = LayoutConfig.hoursInDay * 60;
          final rawMinutes = layoutConfig.minutesFromHeight(
            (localPointer.dy - dragOffsetY).clamp(0.0, double.infinity),
          );
          final roundedMinutes = (((rawMinutes / slotStepMinutes).round() *
                      slotStepMinutes)
                  .clamp(0, math.max(totalMinutes - durationMinutes, 0)))
              .toInt();
          final dayStart = DateTime(
            agendaDate.year,
            agendaDate.month,
            agendaDate.day,
          );
          final newStart = dayStart.add(Duration(minutes: roundedMinutes));
          final newEnd = newStart.add(Duration(minutes: durationMinutes));

          if (block.startTime == newStart && block.endTime == newEnd) return;

          ref.read(dragSessionProvider.notifier).markHandled();

          try {
            await ref.read(timeBlocksProvider.notifier).moveBlock(
              blockId: block.id,
              newStart: newStart,
              newEnd: newEnd,
            );
          } catch (_) {
            if (!context.mounted) return;
            await FeedbackDialog.showError(
              context,
              title: context.l10n.errorTitle,
              message: context.l10n.classEventsCreateErrorMessage,
            );
          }
          return;
        }

        if (dragged is! Appointment) return;
        final appointment = dragged;
        final draggedCardHeightPx =
            ref.read(draggedCardSizeProvider)?.height ?? 50.0;

        final dropResult = computeDropResult(
          DropComputationParams(
            appointment: appointment,
            layoutConfig: layoutConfig,
            columnHeight: box.size.height,
            localPointer: localPointer,
            dragOffsetY: dragOffsetY,
            draggedCardHeightPx: draggedCardHeightPx,
            previewTimes: previewTimes,
          ),
        );

        ref.read(dragSessionProvider.notifier).markHandled();

        // Verifica se l'appuntamento è stato effettivamente spostato
        final hasStaffChanged = appointment.staffId != widget.staff.id;
        final hasTimeChanged =
            appointment.startTime != dropResult.newStart ||
            appointment.endTime != dropResult.newEnd;

        // Se non c'è stato alcun cambiamento, non mostrare il dialog
        if (!hasStaffChanged && !hasTimeChanged) {
          return;
        }

        // Salva i dati del drop pendente per mostrare la preview
        final pendingData = PendingDropData(
          appointmentId: appointment.id,
          originalStaffId: appointment.staffId,
          originalStart: appointment.startTime,
          originalEnd: appointment.endTime,
          newStaffId: widget.staff.id,
          newStart: dropResult.newStart,
          newEnd: dropResult.newEnd,
        );
        ref.read(pendingDropProvider.notifier).setPending(pendingData);

        // Mostra dialog di conferma prima di applicare lo spostamento
        if (!mounted) {
          ref.read(pendingDropProvider.notifier).clear();
          return;
        }
        final l10n = context.l10n;
        final newTimeStr = DtFmt.hm(
          context,
          dropResult.newStart.hour,
          dropResult.newStart.minute,
        );
        final staffName = widget.staff.displayName;

        final bookingAppointments = appointmentsNotifier.getByBookingId(
          appointment.bookingId,
        );
        final notificationRequired =
            willBookingFirstStartChangeOnSingleMove(
              movingAppointment: appointment,
              newStart: dropResult.newStart,
              bookingAppointments: bookingAppointments,
            ) &&
            _hasReachableClientContact(bookingAppointments);
        final isSameDayMove = DateUtils.isSameDay(
          appointment.startTime,
          dropResult.newStart,
        );
        final shouldSkipConfirmation = isSameDayMove && !notificationRequired;
        final confirmResult = shouldSkipConfirmation
            ? const MoveConfirmResult(
                confirmed: true,
                notifyClient: true,
                notifyClientDecisionByOperator: false,
              )
            : await showMoveConfirmDialog(
                context: context,
                title: Text(l10n.moveAppointmentConfirmTitle),
                content: Text(
                  l10n.moveAppointmentConfirmMessage(newTimeStr, staffName),
                ),
                confirmLabel: l10n.actionConfirm,
                cancelLabel: l10n.actionCancel,
                showNotifyOption: notificationRequired,
              );

        // Pulisci sempre lo stato pendente dopo la decisione
        ref.read(pendingDropProvider.notifier).clear();

        if (!confirmResult.confirmed || !context.mounted) return;

        final recurringScope = await resolveRecurringRescheduleScope(
          context: context,
          appointment: appointment,
          targetStart: dropResult.newStart,
          targetStaffId: widget.staff.id,
        );
        if (recurringScope == null || !context.mounted) return;

        await appointmentsNotifier.moveAppointment(
          appointmentId: appointment.id,
          newStaffId: widget.staff.id,
          newStart: dropResult.newStart,
          newEnd: dropResult.newEnd,
          notifyClient: confirmResult.notifyClient,
          notifyClientDecisionByOperator:
              confirmResult.notifyClientDecisionByOperator,
        );

        try {
          await propagateRecurringReschedule(
            ref: ref,
            appointment: appointment,
            targetStart: dropResult.newStart,
            targetStaffId: widget.staff.id,
            scope: recurringScope,
          );
        } catch (_) {
          if (context.mounted) {
            await FeedbackDialog.showError(
              context,
              title: l10n.errorTitle,
              message: l10n.bookingRescheduleMoveFailed,
            );
          }
        }
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

  List<Widget> _buildScheduledEntries(
    double slotHeight,
    List<Appointment> appointments,
    List<ClassEvent> classEvents,
    double columnWidth,
    Map<int, ClassType> classTypeById,
    Map<int, EventGeometry> unifiedGeometry,
    bool expandColumnsOnOverlap,
  ) {
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);
    final cardColorSource = ref.watch(effectiveAgendaCardColorSourceProvider);
    final useServiceColors = cardColorSource == AgendaCardColorSource.services;
    final canManageBookings = ref.watch(currentUserCanManageBookingsProvider);
    final clientsById = ref.watch(clientsByIdProvider);
    // 🔹 Watch fuori dal loop per evitare rebuild multipli
    final pendingDrop = ref.watch(pendingDropProvider);
    final selectedAppts = ref.watch(selectedAppointmentProvider);
    final variantsAsync = useServiceColors
        ? ref.watch(serviceVariantsProvider)
        : const AsyncData(<ServiceVariant>[]);
    final variants = variantsAsync.value ?? const <ServiceVariant>[];
    final isInitialVariantsLoading =
        useServiceColors && variantsAsync.isLoading && !variantsAsync.hasValue;
    final neutralServiceColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    // Pre-calcola la mappa dei colori dei servizi (da varianti)
    final serviceColorMap = <int, Color>{};
    for (final variant in variants) {
      if (variant.colorHex != null) {
        serviceColorMap[variant.serviceId] = ColorUtils.fromHex(
          variant.colorHex!,
        );
      }
    }

    final layoutAppointments = appointments.map((appt) {
      final resizingEntry = ref.watch(resizingEntryProvider(appt.id));
      if (resizingEntry != null &&
          resizingEntry.provisionalEndTime != appt.endTime) {
        return appt.copyWith(endTime: resizingEntry.provisionalEndTime);
      }
      return appt;
    }).toList();

    final positionedEntries = <Widget>[];
    final expandedEntries = <Widget>[];
    final expandedClassEntries = <Widget>[];
    final focusedExpandedEntries = <Widget>[];

    final originalAppointmentsMap = {for (var a in appointments) a.id: a};

    for (final layoutAppt in layoutAppointments) {
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
      final double top = layoutConfig.offsetForMinuteOfDay(startMinutes);
      double height = layoutConfig.heightForMinutes(endMinutes - startMinutes);

      final entry = ref.watch(resizingEntryProvider(originalAppt.id));
      if (entry != null) {
        height = entry.currentPreviewHeightPx;
      }
      final visualTop = top + (LayoutConfig.cardVerticalGap / 2);
      final visualHeight = math.max(height - LayoutConfig.cardVerticalGap, 0.0);
      if (visualHeight <= 0) {
        continue;
      }

      final geometry =
          unifiedGeometry[originalAppt.id] ??
          const EventGeometry(leftFraction: 0, widthFraction: 1);
      final hasPendingDrop = pendingDrop?.appointmentId == originalAppt.id;
      final isOriginalPosition =
          hasPendingDrop && pendingDrop!.originalStaffId == widget.staff.id;

      double opacity = isDragged ? AgendaTheme.ghostOpacity : 1.0;
      if (isOriginalPosition) {
        opacity = AgendaTheme.ghostOpacity;
      }

      final padding = LayoutConfig.columnInnerPadding;
      final fullColumnWidth = math.max(columnWidth - padding * 2, 0.0);
      final shouldForceFullWidth =
          !expandColumnsOnOverlap && geometry.widthFraction >= 1.0 - 1e-9;
      final cardLeft = shouldForceFullWidth
          ? padding
          : columnWidth * geometry.leftFraction + padding;
      final cardWidth = shouldForceFullWidth
          ? fullColumnWidth
          : math.max(columnWidth * geometry.widthFraction - padding * 2, 0.0);

      Color cardColor;
      switch (cardColorSource) {
        case AgendaCardColorSource.services:
          if (isInitialVariantsLoading) {
            cardColor = neutralServiceColor;
          } else {
            final serviceColor = serviceColorMap[originalAppt.serviceId];
            if (serviceColor != null) {
              cardColor = serviceColor;
            } else {
              final snapshotColor = _parseClassTypeColor(
                originalAppt.serviceColorHex,
              );
              if (snapshotColor != null) {
                cardColor = snapshotColor;
                break;
              }
              final variant = ref.watch(
                serviceVariantByIdProvider(originalAppt.serviceVariantId),
              );
              if (variant != null && variant.colorHex != null) {
                cardColor = ColorUtils.fromHex(variant.colorHex!);
              } else {
                cardColor = neutralServiceColor;
              }
            }
          }
          break;
        case AgendaCardColorSource.team:
          cardColor = widget.staff.color;
          break;
        case AgendaCardColorSource.clients:
          cardColor = resolveClientColorForAppointment(
            context,
            originalAppt,
            clientColorHex: clientsById[originalAppt.clientId]?.colorHex,
          );
          break;
      }

      const narrowOverlapRatioThreshold = 0.65;
      const narrowOverlapMaxWidthPx = 320.0;
      final isNarrowOverlappedCard =
          !expandColumnsOnOverlap &&
          fullColumnWidth > 0 &&
          (cardWidth / fullColumnWidth) <= narrowOverlapRatioThreshold &&
          cardWidth <= narrowOverlapMaxWidthPx &&
          cardWidth < fullColumnWidth - 1.0;
      final isExpanded =
          selectedAppts.focusAppointmentId == originalAppt.id &&
          !isDragged &&
          isNarrowOverlappedCard;

      final effectiveLeft = isExpanded ? padding : cardLeft;
      final effectiveWidth = isExpanded ? fullColumnWidth : cardWidth;

      final cardWidget = AnimatedPositioned(
        key: ValueKey(originalAppt.id),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        top: visualTop,
        left: effectiveLeft,
        width: effectiveWidth,
        height: visualHeight,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onSecondaryTapDown: canManageBookings
                ? (details) => _handleAppointmentSecondaryTap(
                    appointment: originalAppt,
                    details: details,
                    cardTop: visualTop,
                    cardHeight: visualHeight,
                  )
                : null,
            child: AppointmentCard(
              appointment: originalAppt,
              color: cardColor,
              columnWidth: effectiveWidth,
              columnOffset: effectiveLeft,
              dragTargetWidth: fullColumnWidth,
            ),
          ),
        ),
      );

      if (isExpanded) {
        if (selectedAppts.focusAppointmentId == originalAppt.id) {
          focusedExpandedEntries.add(cardWidget);
        } else {
          expandedEntries.add(cardWidget);
        }
      } else {
        positionedEntries.add(cardWidget);
      }
    }

    for (final classEvent in classEvents) {
      final startsAt =
          classEvent.startsAtLocal ?? classEvent.startsAtUtc.toLocal();
      final endsAt =
          _classResizePreviewEndByEventId[classEvent.id] ??
          classEvent.endsAtLocal ??
          classEvent.endsAtUtc.toLocal();
      final dayStart = DateTime(startsAt.year, startsAt.month, startsAt.day);
      final startMinutes = startsAt.difference(dayStart).inMinutes;
      final endMinutes = endsAt.difference(dayStart).inMinutes;
      final geometry =
          unifiedGeometry[_classEventLayoutId(classEvent.id)] ??
          const EventGeometry(leftFraction: 0, widthFraction: 1);
      final padding = LayoutConfig.columnInnerPadding;
      final fullColumnWidth = math.max(columnWidth - padding * 2, 0.0);
      final cardLeft = columnWidth * geometry.leftFraction + padding;
      final cardWidth = math.max(
        columnWidth * geometry.widthFraction - padding * 2,
        0.0,
      );
      final isNarrowOverlappedCard =
          !expandColumnsOnOverlap &&
          fullColumnWidth > 0 &&
          (cardWidth / fullColumnWidth) <= 0.65 &&
          cardWidth <= 320.0 &&
          cardWidth < fullColumnWidth - 1.0;
      final isExpanded =
          _hoveredClassEventId == classEvent.id &&
          _draggingClassEventId != classEvent.id &&
          _classResizeSession?.eventId != classEvent.id &&
          isNarrowOverlappedCard;
      final effectiveLeft = isExpanded ? padding : cardLeft;
      final effectiveWidth = isExpanded ? fullColumnWidth : cardWidth;
      final effectiveHeight = layoutConfig.heightForMinutes(
        endMinutes - startMinutes,
      );
      final visualTop =
          layoutConfig.offsetForMinuteOfDay(startMinutes) +
          (LayoutConfig.cardVerticalGap / 2);
      final visualHeight = math.max(
        effectiveHeight - LayoutConfig.cardVerticalGap,
        0.0,
      );
      if (visualHeight <= 0) {
        continue;
      }
      final classType = classTypeById[classEvent.classTypeId];
      final classEventTitle = (classType?.name.trim().isNotEmpty ?? false)
          ? classType!.name.trim()
          : (classEvent.classTypeName?.trim().isNotEmpty ?? false)
          ? classEvent.classTypeName!.trim()
          : context.l10n.classEventsUntitled;
      final classEventColor =
          _parseClassTypeColor(classType?.colorHex) ??
          _parseClassTypeColor(classEvent.classTypeColorHex) ??
          Theme.of(context).colorScheme.tertiaryContainer;

      final classCardWidget = AnimatedPositioned(
        key: ValueKey('class_event_${classEvent.id}'),
        top: visualTop,
        left: effectiveLeft,
        width: effectiveWidth,
        height: visualHeight,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: MouseRegion(
          opaque: true,
          cursor: _resizeHoveredClassEventId == classEvent.id
              ? SystemMouseCursors.resizeUpDown
              : (canManageBookings
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic),
          onEnter: (_) {
            ref.read(selectedAppointmentProvider.notifier).clear();
            if (_hoveredClassEventId != classEvent.id) {
              setState(() => _hoveredClassEventId = classEvent.id);
            }
          },
          onExit: (_) {
            if (_hoveredClassEventId == classEvent.id) {
              setState(() => _hoveredClassEventId = null);
            }
            if (_resizeHoveredClassEventId == classEvent.id) {
              setState(() => _resizeHoveredClassEventId = null);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart:
                canManageBookings && endsAt.isAfter(DateTime.now())
                ? (details) => _startClassResize(
                    event: classEvent,
                    startsAt: startsAt,
                    initialEndsAt: endsAt,
                    details: details,
                    cardHeight: visualHeight,
                  )
                : null,
            onVerticalDragUpdate:
                canManageBookings &&
                    _classResizeSession?.eventId == classEvent.id
                ? _updateClassResize
                : null,
            onVerticalDragEnd:
                canManageBookings &&
                    _classResizeSession?.eventId == classEvent.id
                ? (_) => _commitClassResize()
                : null,
            onVerticalDragCancel:
                canManageBookings &&
                    _classResizeSession?.eventId == classEvent.id
                ? _cancelClassResize
                : null,
            onSecondaryTapDown: canManageBookings
                ? (details) => _handleCardSecondaryTap(
                    details: details,
                    cardTop: visualTop,
                    cardHeight: visualHeight,
                    dayStart: dayStart,
                  )
                : null,
            onTap: canManageBookings
                ? () => showCreateClassEventDialog(
                    context,
                    ref,
                    initialEvent: classEvent,
                  )
                : null,
            child: Builder(
              builder: (cardContext) {
                void clearClassDragState() {
                  ref.read(dragOffsetProvider.notifier).clear();
                  ref.read(dragOffsetXProvider.notifier).clear();
                  ref.read(draggedCardSizeProvider.notifier).clear();
                  ref.read(dragPositionProvider.notifier).clear();
                  ref.read(tempDragTimeProvider.notifier).clear();
                }

                return Listener(
                  onPointerDown: (event) {
                    final cardBox =
                        cardContext.findRenderObject() as RenderBox?;
                    final bodyBox = ref.read(dragBodyBoxProvider);
                    if (cardBox == null || bodyBox == null) return;
                    final cardTopLeftGlobal = cardBox.localToGlobal(
                      Offset.zero,
                    );
                    ref
                        .read(dragOffsetProvider.notifier)
                        .set(event.position.dy - cardTopLeftGlobal.dy);
                    ref
                        .read(dragOffsetXProvider.notifier)
                        .set(event.position.dx - cardTopLeftGlobal.dx);
                    ref
                        .read(draggedCardSizeProvider.notifier)
                        .set(cardBox.size);
                    final local = bodyBox.globalToLocal(event.position);
                    ref.read(dragPositionProvider.notifier).set(local);
                  },
                  onPointerUp: (_) => clearClassDragState(),
                  onPointerCancel: (_) => clearClassDragState(),
                  onPointerHover: (event) {
                    if (!canManageBookings) return;
                    final cardBox =
                        cardContext.findRenderObject() as RenderBox?;
                    if (cardBox == null) return;
                    final localPos = cardBox.globalToLocal(event.position);
                    final h = cardBox.size.height;
                    final resizeHitHeight = (h * 0.35).clamp(8.0, 24.0);
                    final inZone =
                        localPos.dx >= 0 &&
                        localPos.dy >= 0 &&
                        localPos.dx <= cardBox.size.width &&
                        localPos.dy <= h &&
                        localPos.dy >= (h - resizeHitHeight);
                    final newId = inZone ? classEvent.id : null;
                    if (_resizeHoveredClassEventId != newId) {
                      setState(() => _resizeHoveredClassEventId = newId);
                    }
                  },
                  child: LongPressDraggable<_ClassEventDragData>(
                    data: _ClassEventDragData(
                      eventId: classEvent.id,
                      originalStaffId: classEvent.staffId,
                      originalStart: startsAt,
                      originalEnd: endsAt,
                    ),
                    maxSimultaneousDrags: canManageBookings ? 1 : 0,
                    onDragStarted: () => setState(() {
                      _draggingClassEventId = classEvent.id;
                      _hoveredClassEventId = null;
                    }),
                    onDragEnd: (_) => setState(() {
                      _draggingClassEventId = null;
                      clearClassDragState();
                    }),
                    onDraggableCanceled: (_, __) => setState(() {
                      _draggingClassEventId = null;
                      clearClassDragState();
                    }),
                    onDragCompleted: () => setState(() {
                      _draggingClassEventId = null;
                      clearClassDragState();
                    }),
                    feedback: Material(
                      type: MaterialType.transparency,
                      child: SizedBox(
                        width: effectiveWidth,
                        height: visualHeight,
                        child: Opacity(
                          opacity: AgendaTheme.ghostOpacity,
                          child: _ClassEventCard(
                            event: classEvent,
                            width: effectiveWidth,
                            displayStart: startsAt,
                            displayEnd: endsAt,
                            title: classEventTitle,
                            color: classEventColor,
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: AgendaTheme.ghostOpacity,
                      child: _ClassEventCard(
                        event: classEvent,
                        width: effectiveWidth,
                        displayStart: startsAt,
                        displayEnd: endsAt,
                        title: classEventTitle,
                        color: classEventColor,
                      ),
                    ),
                    child: _ClassEventCard(
                      event: classEvent,
                      width: effectiveWidth,
                      displayStart: startsAt,
                      displayEnd: endsAt,
                      title: classEventTitle,
                      color: classEventColor,
                      showResizeHandle:
                          _resizeHoveredClassEventId == classEvent.id,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      if (isExpanded) {
        expandedClassEntries.add(classCardWidget);
      } else {
        positionedEntries.add(classCardWidget);
      }
    }

    // 🔹 Aggiungi preview per drop pendente se questa è la colonna di destinazione
    // (usa la variabile pendingDrop già calcolata all'inizio del metodo)
    if (pendingDrop != null && pendingDrop.newStaffId == widget.staff.id) {
      // Trova l'appuntamento originale nel provider globale
      final allAppointments = ref.watch(appointmentsProvider).value ?? [];
      final originalAppt = allAppointments.cast<Appointment?>().firstWhere(
        (a) => a?.id == pendingDrop.appointmentId,
        orElse: () => null,
      );

      if (originalAppt != null) {
        final dayStart = DateTime(
          pendingDrop.newStart.year,
          pendingDrop.newStart.month,
          pendingDrop.newStart.day,
        );

        final startMinutes = pendingDrop.newStart
            .difference(dayStart)
            .inMinutes;
        final endMinutes = pendingDrop.newEnd.difference(dayStart).inMinutes;

        final double top = layoutConfig.offsetForMinuteOfDay(startMinutes);
        final double height = layoutConfig.heightForMinutes(
          endMinutes - startMinutes,
        );

        final padding = LayoutConfig.columnInnerPadding;
        final cardWidth = math.max(columnWidth - padding * 2, 0.0);

        Color cardColor;
        switch (cardColorSource) {
          case AgendaCardColorSource.services:
            if (isInitialVariantsLoading) {
              cardColor = neutralServiceColor;
            } else {
              // Priorità: colore del servizio (configurabile dall'operatore).
              final serviceColor = serviceColorMap[originalAppt.serviceId];
              if (serviceColor != null) {
                cardColor = serviceColor;
              } else {
                final snapshotColor = _parseClassTypeColor(
                  originalAppt.serviceColorHex,
                );
                if (snapshotColor != null) {
                  cardColor = snapshotColor;
                  break;
                }
                final variant = ref.watch(
                  serviceVariantByIdProvider(originalAppt.serviceVariantId),
                );
                if (variant != null && variant.colorHex != null) {
                  cardColor = ColorUtils.fromHex(variant.colorHex!);
                } else {
                  // Fallback: colore neutro se servizio senza colore
                  cardColor = neutralServiceColor;
                }
              }
            }
            break;
          case AgendaCardColorSource.team:
            cardColor = widget.staff.color;
            break;
          case AgendaCardColorSource.clients:
            cardColor = resolveClientColorForAppointment(
              context,
              originalAppt,
              clientColorHex: clientsById[originalAppt.clientId]?.colorHex,
            );
            break;
        }

        // Preview card con bordo tratteggiato per indicare la posizione proposta
        positionedEntries.add(
          Positioned(
            key: const ValueKey('pending_drop_preview'),
            top: top,
            left: padding,
            width: cardWidth,
            height: height,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.3),
                  borderRadius: ref.watch(agendaUseRoundedCardCornersProvider)
                      ? BorderRadius.circular(
                          LayoutConfig.cardBorderRadiusNormal,
                        )
                      : BorderRadius.zero,
                  border: Border.all(
                    color: cardColor,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.arrow_downward, color: cardColor, size: 24),
                ),
              ),
            ),
          ),
        );
      }
    }

    double topOf(Widget w) {
      if (w is Positioned) return w.top ?? 0;
      if (w is AnimatedPositioned) return w.top ?? 0;
      return 0;
    }

    positionedEntries.sort((a, b) => topOf(a).compareTo(topOf(b)));
    positionedEntries.addAll(expandedEntries);
    positionedEntries.addAll(expandedClassEntries);
    positionedEntries.addAll(focusedExpandedEntries);
    return positionedEntries;
  }

  /// Costruisce i widget per i blocchi di non disponibilità dello staff.
  List<Widget> _buildTimeBlocks(
    double slotHeight,
    double columnWidth,
    Map<int, EventGeometry> unifiedGeometry,
    bool expandColumnsOnOverlap,
  ) {
    final blocks = ref.watch(timeBlocksForStaffProvider(widget.staff.id));
    if (blocks.isEmpty) return [];

    final layoutConfig = ref.watch(layoutConfigProvider);
    final agendaDate = ref.watch(agendaDateProvider);
    final dayStart = DateTime(
      agendaDate.year,
      agendaDate.month,
      agendaDate.day,
    );

    final positionedBlocks = <Widget>[];
    final expandedBlocks = <Widget>[];
    final padding = LayoutConfig.columnInnerPadding;

    final effectiveBlocks = <TimeBlock>[];
    for (final block in blocks) {
      final resizeSessionKey = blockResizeSessionKey(
        blockId: block.id,
        staffId: widget.staff.id,
        day: agendaDate,
      );
      final previewEnd = ref.watch(
        blockResizingEndTimeProvider(resizeSessionKey),
      );
      effectiveBlocks.add(
        previewEnd == null ? block : block.copyWith(endTime: previewEnd),
      );
    }

    for (final effectiveBlock in effectiveBlocks) {
      final block = effectiveBlock;

      // Calcola posizione verticale
      final startMinutes = effectiveBlock.startTime
          .difference(dayStart)
          .inMinutes;
      final endMinutes = effectiveBlock.endTime.difference(dayStart).inMinutes;

      // Clamp ai limiti della giornata visualizzata
      final clampedStartMinutes = startMinutes.clamp(
        0,
        LayoutConfig.hoursInDay * 60,
      );
      final clampedEndMinutes = endMinutes.clamp(
        0,
        LayoutConfig.hoursInDay * 60,
      );

      if (clampedEndMinutes <= clampedStartMinutes) continue;

      final double top = layoutConfig.offsetForMinuteOfDay(clampedStartMinutes);
      final double height = layoutConfig.heightForMinutes(
        clampedEndMinutes - clampedStartMinutes,
      );
      final visualTop = top + (LayoutConfig.cardVerticalGap / 2);
      final visualHeight = math.max(height - LayoutConfig.cardVerticalGap, 0.0);
      if (visualHeight <= 0) continue;
      final geometry =
          unifiedGeometry[_blockLayoutId(block.id)] ??
          const EventGeometry(leftFraction: 0, widthFraction: 1);
      final fullColumnWidth = math.max(columnWidth - padding * 2, 0.0);
      final cardLeft = columnWidth * geometry.leftFraction + padding;
      final cardWidth = math.max(
        columnWidth * geometry.widthFraction - padding * 2,
        0.0,
      );
      const narrowOverlapRatioThreshold = 0.65;
      const narrowOverlapMaxWidthPx = 320.0;
      final isNarrowOverlappedCard =
          !expandColumnsOnOverlap &&
          fullColumnWidth > 0 &&
          (cardWidth / fullColumnWidth) <= narrowOverlapRatioThreshold &&
          cardWidth <= narrowOverlapMaxWidthPx &&
          cardWidth < fullColumnWidth - 1.0;
      final isExpanded =
          _hoveredTimeBlockId == block.id && isNarrowOverlappedCard;
      final effectiveLeft = isExpanded ? padding : cardLeft;
      final effectiveWidth = isExpanded ? fullColumnWidth : cardWidth;

      final blockWidget = AnimatedPositioned(
        key: ValueKey('block_${block.id}'),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        top: visualTop,
        left: effectiveLeft,
        width: effectiveWidth,
        height: visualHeight,
        child: MouseRegion(
          onEnter: (_) {
            ref.read(selectedAppointmentProvider.notifier).clear();
            if (_hoveredClassEventId != null ||
                _hoveredTimeBlockId != block.id) {
              setState(() {
                _hoveredClassEventId = null;
                _hoveredTimeBlockId = block.id;
              });
            }
          },
          onExit: (_) {
            if (_hoveredTimeBlockId == block.id) {
              setState(() => _hoveredTimeBlockId = null);
            }
          },
          child: TimeBlockWidget(
            block: effectiveBlock,
            height: visualHeight,
            width: effectiveWidth,
            resizeSessionKey: blockResizeSessionKey(
              blockId: block.id,
              staffId: widget.staff.id,
              day: agendaDate,
            ),
            staffId: widget.staff.id,
            onSecondaryCreate: _openDefaultComposerAt,
          ),
        ),
      );

      if (isExpanded) {
        expandedBlocks.add(blockWidget);
      } else {
        positionedBlocks.add(blockWidget);
      }
    }

    double topOf(Widget w) {
      if (w is Positioned) return w.top ?? 0;
      if (w is AnimatedPositioned) return w.top ?? 0;
      return 0;
    }

    positionedBlocks.sort((a, b) => topOf(a).compareTo(topOf(b)));
    positionedBlocks.addAll(expandedBlocks);
    return positionedBlocks;
  }

  double _computeStaffDailyTotal({
    required List<Appointment> staffAppointments,
    required List<ClassEvent> classEvents,
  }) {
    final appointmentsTotal = staffAppointments
        .where((a) => !a.isCancelled && !a.isReplaced)
        .fold<double>(0, (sum, a) => sum + (a.price ?? 0));
    final classEventsTotal = classEvents
        .where((event) => event.status.toUpperCase() != 'CANCELLED')
        .fold<double>(0, (sum, event) {
          final priceCents = event.priceCents ?? 0;
          final confirmedCount = event.confirmedCount;
          if (priceCents <= 0 || confirmedCount <= 0) return sum;
          return sum + ((priceCents * confirmedCount) / 100.0);
        });
    return appointmentsTotal + classEventsTotal;
  }

  int _computeStaffDailyServicesCount({
    required List<Appointment> staffAppointments,
    required List<ClassEvent> classEvents,
  }) {
    final appointmentsCount = staffAppointments
        .where((a) => !a.isCancelled && !a.isReplaced)
        .length;
    return appointmentsCount + classEvents.length;
  }

  int? _resolveDailyTotalSlotIndex({
    required DateTime agendaDate,
    required int totalSlots,
    required int minutesPerSlot,
    required Set<int> availableSlots,
    required List<Appointment> appointments,
    required List<ClassEvent> classEvents,
    required List<TimeBlock> blocks,
  }) {
    bool isSlotOccupiedByAppointmentsOrClasses(int slotIndex) {
      final slotStart = agendaDate.add(
        Duration(minutes: slotIndex * minutesPerSlot),
      );
      final slotEnd = slotStart.add(Duration(minutes: minutesPerSlot));

      final occupiedByAppointment = appointments.any(
        (a) =>
            !a.isCancelled &&
            !a.isReplaced &&
            a.startTime.isBefore(slotEnd) &&
            a.endTime.isAfter(slotStart),
      );
      if (occupiedByAppointment) return true;

      final occupiedByClass = classEvents.any((event) {
        if (event.status.toUpperCase() == 'CANCELLED') return false;
        final startsAt = event.startsAtLocal ?? event.startsAtUtc.toLocal();
        final endsAt = event.endsAtLocal ?? event.endsAtUtc.toLocal();
        return startsAt.isBefore(slotEnd) && endsAt.isAfter(slotStart);
      });
      return occupiedByClass;
    }

    bool isSlotOccupiedByBlock(int slotIndex) {
      final slotStart = agendaDate.add(
        Duration(minutes: slotIndex * minutesPerSlot),
      );
      final slotEnd = slotStart.add(Duration(minutes: minutesPerSlot));
      return blocks.any(
        (block) =>
            block.startTime.isBefore(slotEnd) &&
            block.endTime.isAfter(slotStart),
      );
    }

    bool isSlotOccupied(int slotIndex) {
      return isSlotOccupiedByAppointmentsOrClasses(slotIndex) ||
          isSlotOccupiedByBlock(slotIndex);
    }

    int? resolveLastBookingOrClassSlot() {
      for (int slotIndex = totalSlots - 1; slotIndex >= 0; slotIndex--) {
        if (isSlotOccupiedByAppointmentsOrClasses(slotIndex)) {
          return slotIndex;
        }
      }
      return null;
    }

    // Regola prioritaria: dopo l'ultima prenotazione/classe, usa il primo
    // slot NON disponibile (fine turno), se presente.
    final lastBookingOrClassSlot = resolveLastBookingOrClassSlot();
    if (lastBookingOrClassSlot != null) {
      for (int i = lastBookingOrClassSlot + 1; i < totalSlots; i++) {
        final isAvailable = availableSlots.contains(i);
        if (!isAvailable && !isSlotOccupiedByAppointmentsOrClasses(i)) {
          return i;
        }
      }

      // Fallback: primo slot libero dopo l'ultima prenotazione/classe.
      final candidate = lastBookingOrClassSlot + 1;
      if (candidate < totalSlots && !isSlotOccupied(candidate)) {
        return candidate;
      }
      for (int i = candidate + 1; i < totalSlots; i++) {
        if (!isSlotOccupied(i)) return i;
      }
    }

    int? preferredSlot;
    if (availableSlots.isNotEmpty) {
      final lastAvailable = availableSlots.reduce(math.max);
      final candidate = lastAvailable + 1;
      if (candidate < totalSlots) {
        preferredSlot = candidate;
      }
    }

    if (preferredSlot != null && !isSlotOccupied(preferredSlot)) {
      return preferredSlot;
    }

    if (preferredSlot != null) {
      for (int i = preferredSlot + 1; i < totalSlots; i++) {
        if (!isSlotOccupied(i)) return i;
      }
    }

    final lastSlot = totalSlots - 1;
    if (lastSlot >= 0 && !isSlotOccupied(lastSlot)) {
      return lastSlot;
    }

    if (lastSlot >= 0 &&
        !isSlotOccupiedByAppointmentsOrClasses(lastSlot) &&
        isSlotOccupiedByBlock(lastSlot)) {
      return lastSlot;
    }

    return null;
  }

  Widget _buildDailyTotalTrademark({
    required int slotIndex,
    required double slotHeight,
    required int minutesPerSlot,
    required int servicesCount,
    required String formattedTotal,
  }) {
    final layoutConfig = ref.watch(layoutConfigProvider);
    final top = layoutConfig.heightForMinutes(slotIndex * minutesPerSlot);
    final rightPadding = LayoutConfig.columnInnerPadding + 4;
    final chipBackgroundColor = Colors.grey.shade200;
    final chipTextColor = Colors.black.withOpacity(0.42);
    final countStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: chipTextColor,
    );
    final totalStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: chipTextColor,
    );
    final countChipColor = chipBackgroundColor;
    final totalChipColor = chipBackgroundColor;

    return Positioned(
      top: top,
      left: 0,
      right: rightPadding,
      height: slotHeight,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: countChipColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1.5,
                  ),
                  child: Text('$servicesCount', maxLines: 1, style: countStyle),
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: totalChipColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1.5,
                  ),
                  child: Text(
                    formattedTotal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: totalStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSlotTap({
    required DateTime dt,
    required BookingRescheduleSession? rescheduleSession,
  }) async {
    if (rescheduleSession == null) {
      await _openDefaultComposerAt(dt);
      return;
    }

    if (_isApplyingBookingReschedule) return;

    if (rescheduleSession.items.isEmpty) {
      ref.read(bookingRescheduleSessionProvider.notifier).clear();
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.bookingRescheduleMissingBooking,
        );
      }
      return;
    }

    final anchorId = rescheduleSession.anchorAppointmentId;
    final targetStart = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);

    final l10n = context.l10n;
    final targetDateStr = DtFmt.longDate(context, targetStart);
    final targetTimeStr = DtFmt.hm(
      context,
      targetStart.hour,
      targetStart.minute,
    );

    final bookingAppointments = ref
        .read(appointmentsProvider.notifier)
        .getByBookingId(rescheduleSession.bookingId);
    if (bookingAppointments.isEmpty) {
      ref.read(bookingRescheduleSessionProvider.notifier).clear();
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: l10n.bookingRescheduleMissingBooking,
        );
      }
      return;
    }
    final notificationRequired =
        willBookingFirstStartChangeForRescheduleSession(
          session: rescheduleSession,
          targetStart: targetStart,
        ) &&
        _hasReachableClientContact(bookingAppointments);
    final isSameDayMove = DateUtils.isSameDay(
      rescheduleSession.originDate,
      targetStart,
    );
    final shouldSkipConfirmation = isSameDayMove && !notificationRequired;
    final confirmResult = shouldSkipConfirmation
        ? const MoveConfirmResult(
            confirmed: true,
            notifyClient: true,
            notifyClientDecisionByOperator: false,
          )
        : await showMoveConfirmDialog(
            context: context,
            title: Text(l10n.bookingRescheduleConfirmTitle),
            content: Text(
              l10n.bookingRescheduleConfirmMessage(
                targetDateStr,
                targetTimeStr,
                widget.staff.displayName,
              ),
            ),
            confirmLabel: l10n.actionConfirm,
            cancelLabel: l10n.actionCancel,
            showNotifyOption: notificationRequired,
          );
    if (!confirmResult.confirmed || !mounted) return;

    final anchorAppointment = bookingAppointments.firstWhere(
      (appointment) => appointment.id == anchorId,
      orElse: () => bookingAppointments.first,
    );
    final recurringScope = await resolveRecurringRescheduleScope(
      context: context,
      appointment: anchorAppointment,
      targetStart: targetStart,
      targetStaffId: widget.staff.id,
    );
    if (recurringScope == null || !mounted) return;

    setState(() => _isApplyingBookingReschedule = true);
    try {
      final result = await ref
          .read(appointmentsProvider.notifier)
          .moveBookingByAnchor(
            session: rescheduleSession,
            targetStart: targetStart,
            targetStaffId: widget.staff.id,
            notifyClient: confirmResult.notifyClient,
            notifyClientDecisionByOperator:
                confirmResult.notifyClientDecisionByOperator,
          );

      if (!mounted) return;

      if (result != MoveBookingByAnchorResult.success) {
        final message = result == MoveBookingByAnchorResult.outOfTargetDay
            ? l10n.bookingRescheduleOutOfDayBlocked
            : l10n.bookingRescheduleMoveFailed;
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: message,
        );
        return;
      }

      ref.read(bookingRescheduleSessionProvider.notifier).clear();
      final refreshedAppointments = ref.read(appointmentsProvider).value ?? [];
      Appointment? movedAnchor;
      for (final appointment in refreshedAppointments) {
        if (appointment.id == anchorId) {
          movedAnchor = appointment;
          break;
        }
      }
      if (movedAnchor != null) {
        ref.read(agendaScrollRequestProvider.notifier).request(movedAnchor);
      }

      try {
        await propagateRecurringReschedule(
          ref: ref,
          appointment: anchorAppointment,
          targetStart: targetStart,
          targetStaffId: widget.staff.id,
          scope: recurringScope,
        );
      } catch (_) {
        if (!mounted) return;
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: l10n.bookingRescheduleMoveFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplyingBookingReschedule = false);
      } else {
        _isApplyingBookingReschedule = false;
      }
    }
  }

  Future<void> _handleSlotSecondaryTap({
    required DateTime dt,
    required TapDownDetails details,
    required List<Appointment> appointments,
    required List<ClassEvent> classEvents,
    required List<TimeBlock> blocks,
    required int minutesPerSlot,
  }) async {
    final slotEnd = dt.add(Duration(minutes: minutesPerSlot));
    final isSlotOccupiedByAppointment = appointments.any(
      (appointment) =>
          !appointment.isCancelled &&
          !appointment.isReplaced &&
          appointment.startTime.isBefore(slotEnd) &&
          appointment.endTime.isAfter(dt),
    );
    final isSlotOccupiedByClassEvent = classEvents.any((event) {
      final startsAt = event.startsAtLocal ?? event.startsAtUtc.toLocal();
      final endsAt = event.endsAtLocal ?? event.endsAtUtc.toLocal();
      return startsAt.isBefore(slotEnd) && endsAt.isAfter(dt);
    });
    final isSlotOccupiedByBlock = blocks.any(
      (block) => block.startTime.isBefore(slotEnd) && block.endTime.isAfter(dt),
    );
    final isSlotOccupied =
        isSlotOccupiedByAppointment ||
        isSlotOccupiedByClassEvent ||
        isSlotOccupiedByBlock;

    if (isSlotOccupied) return;

    await showAddBlockDialog(
      context,
      ref,
      date: DateUtils.dateOnly(dt),
      time: TimeOfDay(hour: dt.hour, minute: dt.minute),
      initialStaffId: widget.staff.id,
    );
  }

  Future<void> _handleSlotLongPress({
    required DateTime dt,
    required LongPressStartDetails details,
  }) async {

    final location = ref.read(currentLocationProvider);
    final services = ref.read(servicesProvider).value ?? const [];
    final classTypes = ref.read(classTypesProvider).value ?? const [];
    final hasService = services.any((s) {
      if (!s.isActive) return false;
      return s.locationId == null ||
          location.id <= 0 ||
          s.locationId == location.id;
    });
    final hasClassType = classTypes.any((ct) {
      return ct.isActive && ct.locationIds.contains(location.id);
    });

    final l10n = context.l10n;

    final selected = await showAdaptiveMenuAtPosition<String>(
      context: context,
      globalPosition: details.globalPosition,
      title: l10n.agendaAddTitle,
      items: [
        if (hasService)
          AdaptiveDropdownItem(
            value: 'appointment',
            child: Text(l10n.agendaAddAppointment),
          ),
        if (hasClassType)
          AdaptiveDropdownItem(
            value: 'class_schedule',
            child: Text(l10n.classEventsNewScheduleButton),
          ),
        AdaptiveDropdownItem(
          value: 'block',
          child: Text(l10n.agendaAddBlock),
        ),
      ],
    );

    if (!mounted || selected == null) return;

    final date = DateUtils.dateOnly(dt);
    final time = TimeOfDay(hour: dt.hour, minute: dt.minute);

    if (selected == 'appointment') {
      await showBookingDialog(
        context,
        ref,
        date: date,
        time: time,
        initialStaffId: widget.staff.id,
      );
    } else if (selected == 'class_schedule') {
      await showCreateClassEventDialog(
        context,
        ref,
        initialDate: date,
        initialStartTime: time,
        initialStaffId: widget.staff.id,
        lockLocation: true,
      );
    } else if (selected == 'block') {
      await showAddBlockDialog(
        context,
        ref,
        date: date,
        time: time,
        initialStaffId: widget.staff.id,
      );
    }
  }

  Future<void> _handleAppointmentSecondaryTap({
    required Appointment appointment,
    required TapDownDetails details,
    required double cardTop,
    required double cardHeight,
  }) async {
    final dayStart = DateTime(
      appointment.startTime.year,
      appointment.startTime.month,
      appointment.startTime.day,
    );
    final targetStart = _resolveCardSecondaryTapStartTime(
      details: details,
      cardTop: cardTop,
      cardHeight: cardHeight,
      dayStart: dayStart,
    );

    await _openDefaultComposerAt(targetStart);
  }

  Future<void> _handleCardSecondaryTap({
    required TapDownDetails details,
    required double cardTop,
    required double cardHeight,
    required DateTime dayStart,
  }) async {
    final targetStart = _resolveCardSecondaryTapStartTime(
      details: details,
      cardTop: cardTop,
      cardHeight: cardHeight,
      dayStart: dayStart,
    );

    await _openDefaultComposerAt(targetStart);
  }

  DateTime _resolveCardSecondaryTapStartTime({
    required TapDownDetails details,
    required double cardTop,
    required double cardHeight,
    required DateTime dayStart,
  }) {
    final layoutConfig = ref.read(layoutConfigProvider);
    final maxAgendaHeight = layoutConfig.heightForMinutes(
      LayoutConfig.hoursInDay * 60,
    );
    final slotStepMinutes = layoutConfig.minutesPerSlot;
    final totalMinutes = LayoutConfig.hoursInDay * 60;
    final localY = details.localPosition.dy.clamp(0.0, cardHeight).toDouble();
    final absoluteY = (cardTop + localY).clamp(0.0, maxAgendaHeight);
    final rawMinutes = layoutConfig.minutesFromHeight(absoluteY);
    final roundedMinutes =
        (((rawMinutes / slotStepMinutes).round() * slotStepMinutes).clamp(
          0,
          math.max(totalMinutes - slotStepMinutes, 0),
        )).toInt();
    return dayStart.add(Duration(minutes: roundedMinutes));
  }

  Future<void> _openDefaultComposerAt(DateTime targetStart) async {
    if (_shouldOpenClassEventComposerByDefault()) {
      await showCreateClassEventDialog(
        context,
        ref,
        initialDate: DateUtils.dateOnly(targetStart),
        initialStartTime: TimeOfDay(
          hour: targetStart.hour,
          minute: targetStart.minute,
        ),
        initialStaffId: widget.staff.id,
        lockLocation: true,
      );
      return;
    }

    await showBookingDialog(
      context,
      ref,
      date: DateUtils.dateOnly(targetStart),
      time: TimeOfDay(hour: targetStart.hour, minute: targetStart.minute),
      initialStaffId: widget.staff.id,
    );
  }

  bool _shouldOpenClassEventComposerByDefault() {
    final location = ref.read(currentLocationProvider);
    final services = ref.read(servicesProvider).value ?? const [];
    final classTypes = ref.read(classTypesProvider).value ?? const [];
    final serviceCount = services.where((service) {
      if (!service.isActive) return false;
      final serviceLocationId = service.locationId;
      return serviceLocationId == null ||
          location.id <= 0 ||
          serviceLocationId == location.id;
    }).length;
    final classTypeCount = classTypes.where((classType) {
      return classType.isActive &&
          location.id > 0 &&
          classType.locationIds.contains(location.id);
    }).length;

    return classTypeCount > serviceCount;
  }

  bool _hasReachableClientContact(List<Appointment> bookingAppointments) {
    if (bookingAppointments.isEmpty) return false;
    final clientId = bookingAppointments.first.clientId;
    if (clientId == null) return false;
    final client = ref.read(clientsByIdProvider)[clientId];
    if (client == null) {
      // Se il cliente non è in cache locale, non possiamo verificare i contatti:
      // mostriamo comunque il flag per lasciare decisione all'operatore.
      return true;
    }
    final hasEmail = (client.email ?? '').trim().isNotEmpty;
    final hasPhone = (client.phone ?? '').trim().isNotEmpty;
    return hasEmail || hasPhone;
  }
}

int _classEventLayoutId(int classEventId) => -1000000 - classEventId;
int _blockLayoutId(int blockId) => -2000000 - blockId;

class _ClassEventDragData {
  const _ClassEventDragData({
    required this.eventId,
    required this.originalStaffId,
    required this.originalStart,
    required this.originalEnd,
  });

  final int eventId;
  final int originalStaffId;
  final DateTime originalStart;
  final DateTime originalEnd;
}

class _ClassEventResizeSession {
  const _ClassEventResizeSession({
    required this.eventId,
    required this.staffId,
    required this.startsAt,
    required this.initialEndsAt,
    required this.initialGlobalDy,
  });

  final int eventId;
  final int staffId;
  final DateTime startsAt;
  final DateTime initialEndsAt;
  final double initialGlobalDy;
}

class _ClassEventCard extends ConsumerWidget {
  const _ClassEventCard({
    required this.event,
    required this.width,
    required this.displayStart,
    required this.displayEnd,
    required this.title,
    required this.color,
    this.showResizeHandle = false,
  });

  final ClassEvent event;
  final double width;
  final DateTime displayStart;
  final DateTime displayEnd;
  final String title;
  final Color color;
  final bool showResizeHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final showPriceInCard = ref.watch(
      effectiveShowAppointmentPriceInCardProvider,
    );
    final timeLabel =
        '${DtFmt.hm(context, displayStart.hour, displayStart.minute)} - ${DtFmt.hm(context, displayEnd.hour, displayEnd.minute)}';
    String? currencyCode;
    String? priceLabel;
    if (showPriceInCard) {
      if (event.priceCents != null && event.priceCents! > 0) {
        final eventCurrency = event.currency?.trim();
        currencyCode = (eventCurrency != null && eventCurrency.isNotEmpty)
            ? eventCurrency
            : PriceFormatter.effectiveCurrency(ref);
        priceLabel = PriceFormatter.format(
          context: context,
          amount: event.priceCents! / 100.0,
          currencyCode: currencyCode,
        );
      } else if (event.priceCents != null && event.priceCents == 0) {
        priceLabel = l10n.appointmentPriceFree;
      }
    }
    String? totalPriceLabel;
    if (priceLabel != null && event.confirmedCount > 0) {
      totalPriceLabel = PriceFormatter.format(
        context: context,
        amount: (event.priceCents! * event.confirmedCount) / 100.0,
        currencyCode: currencyCode ?? PriceFormatter.effectiveCurrency(ref),
      );
    }
    final metaLabel = priceLabel == null
        ? timeLabel
        : '$timeLabel • $priceLabel';
    final cardColorIntensity = ref.watch(agendaCardColorOpacityProvider);
    final baseCardOpacity = cardColorIntensity.clamp(0.3, 1.0);
    final renderedCardColor = Color.alphaBlend(
      color.withOpacity(baseCardOpacity),
      Colors.white,
    );
    final borderColor = showResizeHandle
        ? Color.alphaBlend(Colors.black.withOpacity(0.05), color)
        : color;
    final isDarkBackground =
        ThemeData.estimateBrightnessForColor(renderedCardColor) ==
        Brightness.dark;
    final primaryTextColor = isDarkBackground ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkBackground
        ? Colors.white70
        : Colors.black54;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final ultraCompact = maxHeight <= 20;
        final centerVerticallyForShort = maxHeight <= 24;
        final compact = maxHeight <= 30;
        final showMeta = maxHeight > 24;
        final showCapacity = maxHeight > 46;
        final showBottomTotal = totalPriceLabel != null && maxHeight > 30;
        final horizontalPadding = ultraCompact ? 6.0 : 8.0;
        final verticalPadding = centerVerticallyForShort
            ? 0.0
            : ultraCompact
            ? 1.0
            : compact
            ? 2.0
            : 6.0;

        final titleStyle =
            (ultraCompact
                    ? theme.textTheme.labelSmall?.copyWith(fontSize: 10)
                    : theme.textTheme.labelSmall)
                ?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                );

        final metaStyle =
            (ultraCompact
                    ? theme.textTheme.bodySmall?.copyWith(fontSize: 10)
                    : theme.textTheme.bodySmall)
                ?.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                );

        final capacityStyle = metaStyle?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.0,
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: renderedCardColor,
            borderRadius: ref.watch(agendaUseRoundedCardCornersProvider)
                ? BorderRadius.circular(LayoutConfig.cardBorderRadiusNormal)
                : BorderRadius.zero,
            border: Border.all(color: borderColor),
          ),
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                centerVerticallyForShort
                    ? SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showMeta) ...[
                                  Text(
                                    metaLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: metaStyle,
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                if (showCapacity) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    (event.waitlistEnabled ||
                                            event.waitlistCount > 0)
                                        ? l10n.classEventsCapacitySummary(
                                            event.confirmedCount,
                                            event.capacityTotal,
                                            event.waitlistCount,
                                          )
                                        : l10n.classEventsCapacitySummaryNoWaitlist(
                                            event.confirmedCount,
                                            event.capacityTotal,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: capacityStyle,
                                  ),
                                ],
                                if (showBottomTotal) const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showMeta) ...[
                              Text(
                                metaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: metaStyle,
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            if (showCapacity) ...[
                              const SizedBox(height: 2),
                              Text(
                                (event.waitlistEnabled ||
                                        event.waitlistCount > 0)
                                    ? l10n.classEventsCapacitySummary(
                                        event.confirmedCount,
                                        event.capacityTotal,
                                        event.waitlistCount,
                                      )
                                    : l10n.classEventsCapacitySummaryNoWaitlist(
                                        event.confirmedCount,
                                        event.capacityTotal,
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: capacityStyle,
                              ),
                            ],
                            if (showBottomTotal) const SizedBox(height: 12),
                          ],
                        ),
                      ),
                if (showBottomTotal)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      totalPriceLabel,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (showResizeHandle)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 22,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

