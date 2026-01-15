import 'dart:async';
import 'dart:math' as math;

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/service_variant.dart';
import 'package:agenda_backend/core/widgets/app_dialogs.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/hover_slot.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/unavailable_slot_pattern.dart';
import 'package:agenda_backend/features/agenda/providers/dragged_card_size_provider.dart';
import 'package:agenda_backend/features/agenda/providers/pending_drop_provider.dart';
import 'package:agenda_backend/features/agenda/providers/staff_slot_availability_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '/core/models/staff.dart';
import '/core/utils/color_utils.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
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
import '../../../providers/time_blocks_provider.dart';
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
    final agendaDate = ref.watch(agendaDateProvider);

    // Interaction lock propagated from parent (evaluated once per visible group)
    final isInteractionLocked = widget.isInteractionLocked;

    // 🔹 Calcola slot pieni PRIMA del layout (solo desktop e se abilitato)
    final formFactor = ref.watch(formFactorProvider);
    final bool showAddButtonStrip =
        layoutConfig.enableOccupiedSlotStrip &&
        formFactor == AppFormFactor.desktop &&
        !isInteractionLocked;
    final fullyOccupied = showAddButtonStrip
        ? ref.watch(fullyOccupiedSlotsProvider(widget.staff.id))
        : const <int>{};
    final hasFullyOccupiedSlots = fullyOccupied.isNotEmpty;

    // Larghezza disponibile per le card (ridotta se ci sono slot pieni)
    final addButtonWidth = hasFullyOccupiedSlots
        ? LayoutConfig.addButtonStripWidth
        : 0.0;
    final effectiveColumnWidth = widget.columnWidth - addButtonWidth;

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
      final totalHeight = totalSlots * slotHeight;
      stackChildren.add(
        IgnorePointer(
          child: SizedBox(
            height: totalHeight,
            width: double.infinity,
            child: Stack(
              children: [
                for (final range in unavailableRanges)
                  Positioned(
                    top: range.startIndex * slotHeight,
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
            if (!isInteractionLocked) {
              return LazyHoverSlot(
                slotTime: slotTime,
                height: slotHeight,
                colorPrimary1: Theme.of(context).colorScheme.primary,
                onTap: (dt) {
                  showBookingDialog(
                    context,
                    ref,
                    date: DateUtils.dateOnly(dt),
                    time: TimeOfDay(hour: dt.hour, minute: dt.minute),
                    initialStaffId: widget.staff.id,
                  );
                },
              );
            }

            // Mantieni lo spazio vuoto per evitare salti nel layout.
            return SizedBox(height: slotHeight, width: double.infinity);
          }),
        ),
      ),
    );

    // 🔹 Appuntamenti (con larghezza ridotta se ci sono slot pieni)
    stackChildren.addAll(
      _buildAppointments(slotHeight, staffAppointments, effectiveColumnWidth),
    );

    // 🔹 Blocchi di non disponibilità
    stackChildren.addAll(_buildTimeBlocks(slotHeight));

    // La fascia laterale è già riservata riducendo effectiveColumnWidth,
    // quindi le card si restringono automaticamente lasciando spazio a destra.

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
      onAcceptWithDetails: (details) async {
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

        final confirmed = await showConfirmDialog(
          context,
          title: Text(l10n.moveAppointmentConfirmTitle),
          content: Text(
            l10n.moveAppointmentConfirmMessage(newTimeStr, staffName),
          ),
          confirmLabel: l10n.actionConfirm,
          cancelLabel: l10n.actionCancel,
        );

        // Pulisci sempre lo stato pendente dopo la decisione
        ref.read(pendingDropProvider.notifier).clear();

        if (confirmed && mounted) {
          appointmentsNotifier.moveAppointment(
            appointmentId: details.data.id,
            newStaffId: widget.staff.id,
            newStart: dropResult.newStart,
            newEnd: dropResult.newEnd,
          );
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

  List<Widget> _buildAppointments(
    double slotHeight,
    List<Appointment> appointments,
    double columnWidth,
  ) {
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);
    final useServiceColors = layoutConfig.useServiceColorsForAppointments;
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

        // Controlla se questo appuntamento ha un drop pendente (usa variabile pre-calcolata)
        final hasPendingDrop = pendingDrop?.appointmentId == originalAppt.id;
        final isOriginalPosition =
            hasPendingDrop && pendingDrop!.originalStaffId == widget.staff.id;

        double opacity = isDragged ? AgendaTheme.ghostOpacity : 1.0;
        // Se è la posizione originale durante un drop pendente, mostra semi-trasparente
        if (isOriginalPosition) {
          opacity = AgendaTheme.ghostOpacity;
        }

        // 🔹 Costruisci la card (usa columnWidth passato, che è già ridotto se ci sono slot pieni)
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

        final double top =
            (startMinutes / layoutConfig.minutesPerSlot) * slotHeight;
        final double height =
            ((endMinutes - startMinutes) / layoutConfig.minutesPerSlot) *
            slotHeight;

        final padding = LayoutConfig.columnInnerPadding;
        final cardWidth = math.max(widget.columnWidth - padding * 2, 0.0);

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
        positionedAppointments.add(
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

    return positionedAppointments;
  }

  /// Costruisce i widget per i blocchi di non disponibilità dello staff.
  List<Widget> _buildTimeBlocks(double slotHeight) {
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
    final cardWidth = math.max(widget.columnWidth - padding * 2, 0.0);

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

      final double top =
          (clampedStartMinutes / layoutConfig.minutesPerSlot) * slotHeight;
      final double height =
          ((clampedEndMinutes - clampedStartMinutes) /
              layoutConfig.minutesPerSlot) *
          slotHeight;

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
}
