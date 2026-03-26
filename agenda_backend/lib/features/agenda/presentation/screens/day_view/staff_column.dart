import 'dart:async';
import 'dart:math' as math;

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/service_variant.dart';
import 'package:agenda_backend/core/widgets/feedback_dialog.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/hover_slot.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/unavailable_slot_pattern.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/agenda/providers/dragged_card_size_provider.dart';
import 'package:agenda_backend/features/agenda/providers/pending_drop_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_slot_availability_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/class_events/providers/class_events_providers.dart';
import 'package:agenda_backend/features/clients/providers/clients_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '/core/models/class_event.dart';
import '/core/models/staff.dart';
import '/core/models/time_block.dart';
import '/core/utils/color_utils.dart';
import '/core/utils/price_utils.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/agenda_display_settings_provider.dart';
import '../../../providers/agenda_scroll_request_provider.dart';
import '../../../providers/appointment_providers.dart';
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
import '../../../providers/resizing_provider.dart';
import '../../../providers/selected_appointment_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../../../providers/tenant_time_provider.dart';
import '../../../providers/time_blocks_provider.dart';
import '../../utils/multi_service_move_guard.dart';
import '../../widgets/booking_dialog.dart';
import '../helper/drag_drop_helper.dart';
import '../helper/layout_geometry_helper.dart';
import '../widgets/agenda_dividers.dart';
import '../widgets/appointment_card_base.dart';
import '../widgets/time_block_widget.dart';

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
  double? _hoverY;
  bool _isApplyingBookingReschedule = false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAppointments = ref.watch(appointmentsForCurrentLocationProvider);
    final staffAppointments = allAppointments
        .where((a) => a.staffId == widget.staff.id)
        .toList();
    final allClassEvents =
        ref.watch(classEventsForCurrentLocationDayProvider).value ?? const [];
    final staffClassEvents = allClassEvents
        .where(
          (event) =>
              event.staffId == widget.staff.id &&
              event.status.toUpperCase() != 'CANCELLED',
        )
        .toList();

    // 6. RIMOSSO il blocco addPostFrameCallback da qui

    final layoutConfig = ref.watch(layoutConfigProvider);
    final slotHeight = layoutConfig.slotHeight;
    final totalSlots = layoutConfig.totalSlots;
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final agendaDate = ref.watch(agendaDateProvider);
    final canManageBookings = ref.watch(currentUserCanManageBookingsProvider);
    final showPrices = ref.watch(effectiveShowAppointmentPriceInCardProvider);
    final staffBlocks = ref.watch(timeBlocksForStaffProvider(widget.staff.id));

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
                onTap: (dt) => _handleSlotTap(
                  dt: dt,
                  rescheduleSession: rescheduleSession,
                ),
              );
            }

            // Mantieni lo spazio vuoto per evitare salti nel layout.
            return SizedBox(height: slotHeight, width: double.infinity);
          }),
        ),
      ),
    );

    final staffDailyTotal = _computeStaffDailyTotal(staffAppointments);
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

      if (totalSlotIndex != null) {
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

    // 🔹 Appuntamenti + classi (con larghezza ridotta se ci sono slot pieni)
    stackChildren.addAll(
      _buildScheduledEntries(
        slotHeight,
        staffAppointments,
        staffClassEvents,
        effectiveColumnWidth,
      ),
    );

    // 🔹 Blocchi di non disponibilità
    stackChildren.addAll(_buildTimeBlocks(slotHeight, effectiveColumnWidth));

    // La fascia laterale è già riservata riducendo effectiveColumnWidth,
    // quindi le card si restringono automaticamente lasciando spazio a destra.

    return DragTarget<Appointment>(
      onWillAcceptWithDetails: (_) {
        if (!canManageBookings) return false;
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

        // Verifica se l'appuntamento è stato effettivamente spostato
        final hasStaffChanged = details.data.staffId != widget.staff.id;
        final hasTimeChanged =
            details.data.startTime != dropResult.newStart ||
            details.data.endTime != dropResult.newEnd;

        // Se non c'è stato alcun cambiamento, non mostrare il dialog
        if (!hasStaffChanged && !hasTimeChanged) {
          return;
        }

        // Salva i dati del drop pendente per mostrare la preview
        final pendingData = PendingDropData(
          appointmentId: details.data.id,
          originalStaffId: details.data.staffId,
          originalStart: details.data.startTime,
          originalEnd: details.data.endTime,
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
          details.data.bookingId,
        );
        final confirmResult = await showMoveConfirmDialog(
          context: context,
          title: Text(l10n.moveAppointmentConfirmTitle),
          content: Text(
            l10n.moveAppointmentConfirmMessage(newTimeStr, staffName),
          ),
          confirmLabel: l10n.actionConfirm,
          cancelLabel: l10n.actionCancel,
          showNotifyOption:
              willBookingFirstStartChangeOnSingleMove(
                movingAppointment: details.data,
                newStart: dropResult.newStart,
                bookingAppointments: bookingAppointments,
              ) &&
              _hasReachableClientContact(bookingAppointments),
        );

        // Pulisci sempre lo stato pendente dopo la decisione
        ref.read(pendingDropProvider.notifier).clear();

        if (!confirmResult.confirmed || !context.mounted) return;
        appointmentsNotifier.moveAppointment(
          appointmentId: details.data.id,
          newStaffId: widget.staff.id,
          newStart: dropResult.newStart,
          newEnd: dropResult.newEnd,
          notifyClient: confirmResult.notifyClient,
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

  List<Widget> _buildScheduledEntries(
    double slotHeight,
    List<Appointment> appointments,
    List<ClassEvent> classEvents,
    double columnWidth,
  ) {
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);
    final useServiceColors = ref.watch(
      effectiveUseServiceColorsForAppointmentsProvider,
    );
    // 🔹 Watch fuori dal loop per evitare rebuild multipli
    final pendingDrop = ref.watch(pendingDropProvider);
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

    final originalAppointmentsMap = {for (var a in appointments) a.id: a};
    final layoutEntries =
        layoutAppointments
            .map(
              (a) => LayoutEntry(id: a.id, start: a.startTime, end: a.endTime),
            )
            .toList()
          ..addAll(
            classEvents.map(
              (event) => LayoutEntry(
                id: _classEventLayoutId(event.id),
                start: event.startsAtLocal ?? event.startsAtUtc.toLocal(),
                end: event.endsAtLocal ?? event.endsAtUtc.toLocal(),
              ),
            ),
          );
    final layoutGeometry = computeLayoutGeometry(
      layoutEntries,
      useClusterMaxConcurrency: layoutConfig.useClusterMaxConcurrency,
    );

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

      final geometry =
          layoutGeometry[originalAppt.id] ??
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
      final cardLeft = columnWidth * geometry.leftFraction + padding;
      final cardWidth = math.max(
        columnWidth * geometry.widthFraction - padding * 2,
        0.0,
      );

      Color cardColor;
      if (useServiceColors) {
        if (isInitialVariantsLoading) {
          cardColor = neutralServiceColor;
        } else {
          final serviceColor = serviceColorMap[originalAppt.serviceId];
          if (serviceColor != null) {
            cardColor = serviceColor;
          } else {
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
      } else {
        cardColor = widget.staff.color;
      }

      positionedEntries.add(
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
            ),
          ),
        ),
      );
    }

    for (final classEvent in classEvents) {
      final startsAt =
          classEvent.startsAtLocal ?? classEvent.startsAtUtc.toLocal();
      final endsAt = classEvent.endsAtLocal ?? classEvent.endsAtUtc.toLocal();
      final dayStart = DateTime(startsAt.year, startsAt.month, startsAt.day);
      final startMinutes = startsAt.difference(dayStart).inMinutes;
      final endMinutes = endsAt.difference(dayStart).inMinutes;
      final geometry =
          layoutGeometry[_classEventLayoutId(classEvent.id)] ??
          const EventGeometry(leftFraction: 0, widthFraction: 1);
      final padding = LayoutConfig.columnInnerPadding;
      final cardLeft = columnWidth * geometry.leftFraction + padding;
      final cardWidth = math.max(
        columnWidth * geometry.widthFraction - padding * 2,
        0.0,
      );

      positionedEntries.add(
        Positioned(
          key: ValueKey('class_event_${classEvent.id}'),
          top: layoutConfig.offsetForMinuteOfDay(startMinutes),
          left: cardLeft,
          width: cardWidth,
          height: layoutConfig.heightForMinutes(endMinutes - startMinutes),
          child: IgnorePointer(
            child: _ClassEventCard(
              event: classEvent,
              width: cardWidth,
              color: Theme.of(context).colorScheme.tertiaryContainer,
            ),
          ),
        ),
      );
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
        if (useServiceColors) {
          if (isInitialVariantsLoading) {
            cardColor = neutralServiceColor;
          } else {
            // Priorità: colore del servizio (configurabile dall'operatore).
            final serviceColor = serviceColorMap[originalAppt.serviceId];
            if (serviceColor != null) {
              cardColor = serviceColor;
            } else {
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
        } else {
          // Se non uso colori servizio, usa colore staff
          cardColor = widget.staff.color;
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
                  borderRadius: BorderRadius.circular(
                    LayoutConfig.borderRadius,
                  ),
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

    positionedEntries.sort((a, b) {
      final aTop = (a as Positioned).top ?? 0;
      final bTop = (b as Positioned).top ?? 0;
      return aTop.compareTo(bTop);
    });
    return positionedEntries;
  }

  /// Costruisce i widget per i blocchi di non disponibilità dello staff.
  List<Widget> _buildTimeBlocks(double slotHeight, double columnWidth) {
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
    final padding = LayoutConfig.columnInnerPadding;
    final cardWidth = math.max(columnWidth - padding * 2, 0.0);

    for (final block in blocks) {
      // Calcola posizione verticale
      final startMinutes = block.startTime.difference(dayStart).inMinutes;
      final endMinutes = block.endTime.difference(dayStart).inMinutes;

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

      positionedBlocks.add(
        Positioned(
          key: ValueKey('block_${block.id}'),
          top: top,
          left: padding,
          width: cardWidth,
          height: height,
          child: TimeBlockWidget(
            block: block,
            height: height,
            width: cardWidth,
          ),
        ),
      );
    }

    return positionedBlocks;
  }

  double _computeStaffDailyTotal(List<Appointment> appointments) {
    return appointments
        .where((a) => !a.isCancelled && !a.isReplaced)
        .fold<double>(0, (sum, a) => sum + (a.price ?? 0));
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
    final trademarkStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.normal,
      height: 1.0,
      color: Colors.black.withOpacity(0.5),
      letterSpacing: 0,
    );

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
              Text('$servicesCount', maxLines: 1, style: trademarkStyle),
              const Spacer(),
              Text(
                formattedTotal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: trademarkStyle,
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
      showBookingDialog(
        context,
        ref,
        date: DateUtils.dateOnly(dt),
        time: TimeOfDay(hour: dt.hour, minute: dt.minute),
        initialStaffId: widget.staff.id,
      );
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
    final confirmResult = await showMoveConfirmDialog(
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
      showNotifyOption:
          willBookingFirstStartChangeForRescheduleSession(
            session: rescheduleSession,
            targetStart: targetStart,
          ) &&
          _hasReachableClientContact(bookingAppointments),
    );
    if (!confirmResult.confirmed || !mounted) return;
    setState(() => _isApplyingBookingReschedule = true);
    try {
      final result = await ref
          .read(appointmentsProvider.notifier)
          .moveBookingByAnchor(
            session: rescheduleSession,
            targetStart: targetStart,
            targetStaffId: widget.staff.id,
            notifyClient: confirmResult.notifyClient,
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
    } finally {
      if (mounted) {
        setState(() => _isApplyingBookingReschedule = false);
      } else {
        _isApplyingBookingReschedule = false;
      }
    }
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

class _ClassEventCard extends StatelessWidget {
  const _ClassEventCard({
    required this.event,
    required this.width,
    required this.color,
  });

  final ClassEvent event;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LayoutConfig.borderRadius),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.classEventsTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.classEventsCapacitySummary(
              event.confirmedCount,
              event.capacityTotal,
              event.waitlistCount,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
