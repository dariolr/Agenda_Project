import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '../../../../../../app/providers/form_factor_provider.dart';
import '../../../../../../core/l10n/l10_extension.dart';
import '../../../../../../core/widgets/app_dialogs.dart';
import '../../../../clients/providers/clients_providers.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_interaction_lock_provider.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/bookings_provider.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/drag_session_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/dragged_base_range_provider.dart';
import '../../../providers/dragged_last_staff_provider.dart';
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/is_resizing_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/resizing_provider.dart';
import '../../../providers/selected_appointment_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../../widgets/appointment_dialog.dart';

/// 🔹 Versione unificata per DESKTOP e MOBILE.
/// Mantiene drag, resize, ghost, select, ma cambia il comportamento del tap:
/// - Desktop → seleziona la card.
/// - Mobile → apre un bottom sheet con i dettagli.
class AppointmentCardInteractive extends ConsumerStatefulWidget {
  final Appointment appointment;
  final Color color;
  final double? columnWidth;
  final double? columnOffset;
  final double? dragTargetWidth;
  final bool expandToLeft;

  const AppointmentCardInteractive({
    super.key,
    required this.appointment,
    required this.color,
    this.columnWidth,
    this.columnOffset,
    this.dragTargetWidth,
    this.expandToLeft = false,
  });

  @override
  ConsumerState<AppointmentCardInteractive> createState() =>
      _AppointmentCardInteractiveState();
}

class _AppointmentCardInteractiveState
    extends ConsumerState<AppointmentCardInteractive> {
  Size? _lastSize;
  Offset? _lastPointerGlobalPosition;
  bool _isDraggingResize = false;
  bool _blockDragDuringResize = false;
  bool _selectedFromHover = false;
  int? _currentDragSessionId;
  late final AgendaCardHoverNotifier _hoverNotifier;

  static const double _dragBlockZoneHeight = 28.0;
  static const int _minSlotsForDragBlock = 3;

  LayoutConfig get _layoutConfig => ref.read(layoutConfigProvider);

  @override
  void initState() {
    super.initState();
    _hoverNotifier = ref.read(agendaCardHoverProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedAppointmentProvider);
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final formFactor = ref.watch(formFactorProvider);

    final isSelected = selection.contains(widget.appointment.id);
    final isDragging = draggedId == widget.appointment.id;
    final showThickBorder = isSelected || isDragging;

    return MouseRegion(
      onEnter: (_) {
        _hoverNotifier.enter();
        _selectAppointment(ref, fromHover: true);
      },
      onExit: (_) {
        _hoverNotifier.exit();
        if (_selectedFromHover &&
            ref
                .read(selectedAppointmentProvider)
                .contains(widget.appointment.id) &&
            ref.read(draggedAppointmentIdProvider) != widget.appointment.id &&
            !ref.read(isResizingProvider)) {
          ref.read(selectedAppointmentProvider.notifier).clear();
          _selectedFromHover = false;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (mounted && (_lastSize == null || _lastSize != size)) {
              setState(() => _lastSize = size);
            }
          });

          return Listener(
            onPointerDown: (e) {
              final cardBox = context.findRenderObject() as RenderBox?;
              if (cardBox != null) {
                _lastPointerGlobalPosition = e.position;
                _evaluateDragBlock(cardBox, e.position);
                ref
                    .read(draggedBaseRangeProvider.notifier)
                    .set(
                      widget.appointment.startTime,
                      widget.appointment.endTime,
                    );
                ref
                    .read(draggedLastStaffIdProvider.notifier)
                    .set(widget.appointment.staffId);

                final bodyBox = ref.read(dragBodyBoxProvider);
                if (bodyBox != null) {
                  final cardTopLeftGlobal = cardBox.localToGlobal(Offset.zero);
                  ref
                      .read(dragOffsetProvider.notifier)
                      .set(e.position.dy - cardTopLeftGlobal.dy);
                  ref
                      .read(dragOffsetXProvider.notifier)
                      .set(e.position.dx - cardTopLeftGlobal.dx);
                  final localStart = bodyBox.globalToLocal(e.position);
                  ref.read(dragPositionProvider.notifier).set(localStart);
                }
              }
            },
            onPointerMove: (e) {
              if (_isDraggingResize) {
                _performResizeUpdate(e);
                return;
              }
              final cardBox = context.findRenderObject() as RenderBox?;
              if (cardBox != null) {
                _evaluateDragBlock(cardBox, e.position);
              }
            },
            onPointerUp: (e) {
              if (_isDraggingResize) {
                _performResizeEnd();
                return;
              }
              if (ref.read(dragPositionProvider) != null) {
                ref.read(dragPositionProvider.notifier).clear();
              }
              _updateDragBlock(false);
              ref.read(draggedBaseRangeProvider.notifier).clear();
              ref.read(draggedLastStaffIdProvider.notifier).clear();
            },
            onPointerCancel: (e) {
              if (_isDraggingResize) {
                _performResizeCancel();
                return;
              }
              if (ref.read(dragPositionProvider) != null) {
                ref.read(dragPositionProvider.notifier).clear();
              }
              _updateDragBlock(false);
              ref.read(draggedBaseRangeProvider.notifier).clear();
              ref.read(draggedLastStaffIdProvider.notifier).clear();
            },
            child: GestureDetector(
              onTap: () {
                if (formFactor == AppFormFactor.mobile) {
                  _handleMobileTap();
                } else {
                  _handleDesktopTap();
                }
              },
              child: LongPressDraggable<Appointment>(
                data: widget.appointment,
                feedback: Consumer(
                  builder: (c, r, _) =>
                      _buildFollowerFeedback(c, r, isSelected),
                ),
                feedbackOffset: Offset.zero,
                dragAnchorStrategy: childDragAnchorStrategy,
                maxSimultaneousDrags: _blockDragDuringResize ? 0 : 1,
                childWhenDragging: _buildCard(
                  isGhost: true,
                  showThickBorder: showThickBorder,
                  isSelected: isSelected,
                ),

                onDragStarted: () {
                  _currentDragSessionId = ref
                      .read(dragSessionProvider.notifier)
                      .start();
                  ref
                      .read(draggedBaseRangeProvider.notifier)
                      .set(
                        widget.appointment.startTime,
                        widget.appointment.endTime,
                      );
                  _selectAppointment(ref);
                  ref
                      .read(draggedAppointmentIdProvider.notifier)
                      .set(widget.appointment.id);

                  final bodyBox = ref.read(dragBodyBoxProvider);
                  if (bodyBox != null && _lastPointerGlobalPosition != null) {
                    final local = bodyBox.globalToLocal(
                      _lastPointerGlobalPosition!,
                    );
                    ref.read(dragPositionProvider.notifier).set(local);
                  }
                },

                onDragUpdate: (details) {
                  final prev = ref.read(dragPositionProvider);
                  final bodyBox = ref.read(dragBodyBoxProvider);
                  if (bodyBox != null) {
                    final local = bodyBox.globalToLocal(details.globalPosition);
                    ref
                        .read(dragPositionProvider.notifier)
                        .set(Offset.lerp(prev, local, 0.85)!);
                  }
                },

                onDragEnd: (details) => _handleDragEnd(ref, details),
                onDragCompleted: () => _handleEnd(ref, keepSelection: true),
                onDraggableCanceled: (_, __) =>
                    _handleEnd(ref, keepSelection: true),

                child: _buildCard(
                  showThickBorder: showThickBorder,
                  isResizingDisabled: isDragging,
                  isSelected: isSelected,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hoverNotifier.exit();
    });
    super.dispose();
  }

  void _handleEnd(WidgetRef ref, {bool keepSelection = false}) {
    ref.read(dragSessionProvider.notifier).clear();
    _currentDragSessionId = null;
    ref.read(draggedAppointmentIdProvider.notifier).clear();
    ref.read(dragOffsetProvider.notifier).clear();
    ref.read(dragOffsetXProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(tempDragTimeProvider.notifier).clear();
    if (keepSelection) {
      _selectAppointment(ref);
    } else {
      ref.read(selectedAppointmentProvider.notifier).clear();
    }
    ref.read(draggedBaseRangeProvider.notifier).clear();
    ref.read(draggedLastStaffIdProvider.notifier).clear();
  }

  void _selectAppointment(WidgetRef ref, {bool fromHover = false}) {
    _selectedFromHover = fromHover;
    final sel = ref.read(selectedAppointmentProvider.notifier);
    sel.toggleByAppointment(widget.appointment);
  }

  void _handleDragEnd(WidgetRef ref, DraggableDetails details) {
    if (details.wasAccepted) {
      _handleEnd(ref, keepSelection: true);
      return;
    }

    final session = ref.read(dragSessionProvider);
    final handledByTarget =
        session.dropHandled &&
        session.id != null &&
        session.id == _currentDragSessionId;
    if (handledByTarget) {
      _handleEnd(ref, keepSelection: true);
      return;
    }

    final bodyBox = ref.read(dragBodyBoxProvider);
    final columns = ref.read(staffColumnsGeometryProvider);
    if (bodyBox == null || columns.isEmpty) {
      _handleEnd(ref, keepSelection: true);
      return;
    }

    final dragPosLocal = ref.read(dragPositionProvider);
    final lastStaffId = ref.read(draggedLastStaffIdProvider);
    final offY = ref.read(dragOffsetProvider) ?? 0;
    final offX = ref.read(dragOffsetXProvider) ?? 0;
    final pointerGlobal = details.offset + Offset(offX, offY);
    final pointerLocal = bodyBox.globalToLocal(pointerGlobal);
    final releaseOffset = dragPosLocal ?? pointerLocal;
    final bodyOffset = pointerLocal;
    const tolerance = 4.0;

    int? targetStaffId;
    Rect? targetRect;
    for (final entry in columns.entries) {
      final rect = entry.value.inflate(tolerance);
      if (releaseOffset.dx >= rect.left && releaseOffset.dx <= rect.right) {
        targetStaffId = entry.key;
        targetRect = rect;
        break;
      }
    }

    if (targetStaffId == null || targetRect == null) {
      for (final entry in columns.entries) {
        final rect = entry.value.inflate(tolerance);
        if (bodyOffset.dx >= rect.left && bodyOffset.dx <= rect.right) {
          targetStaffId = entry.key;
          targetRect = rect;
          break;
        }
      }
    }

    final int dropStaffId =
        targetStaffId ?? lastStaffId ?? widget.appointment.staffId;
    targetRect ??= columns[dropStaffId];

    if (targetRect == null) {
      _handleEnd(ref, keepSelection: true);
      return;
    }

    double localY = releaseOffset.dy - targetRect.top;
    final slotHeight = _layoutConfig.slotHeight;
    final minutesPerSlot = _layoutConfig.minutesPerSlot;
    final totalMinutes = LayoutConfig.hoursInDay * 60;

    final baseDate = DateTime(
      widget.appointment.startTime.year,
      widget.appointment.startTime.month,
      widget.appointment.startTime.day,
    );

    final durationMinutes = widget.appointment.endTime
        .difference(widget.appointment.startTime)
        .inMinutes;

    final rawMaxStart = totalMinutes - durationMinutes;
    final maxStartMinutes = rawMaxStart < 0 ? 0 : rawMaxStart;

    double minutesFromTop = (localY / slotHeight) * minutesPerSlot;
    int roundedMinutes = ((minutesFromTop / 5).round() * 5).toInt();
    if (roundedMinutes < 0) {
      roundedMinutes = 0;
    } else if (roundedMinutes > maxStartMinutes) {
      roundedMinutes = maxStartMinutes;
    }

    final newStart = baseDate.add(Duration(minutes: roundedMinutes));
    var newEnd = newStart.add(Duration(minutes: durationMinutes));
    final dayBoundary = baseDate.add(const Duration(days: 1));
    if (newEnd.isAfter(dayBoundary)) newEnd = dayBoundary;

    ref
        .read(appointmentsProvider.notifier)
        .moveAppointment(
          appointmentId: widget.appointment.id,
          newStaffId: dropStaffId,
          newStart: newStart,
          newEnd: newEnd,
        );

    _handleEnd(ref, keepSelection: true);
  }

  void _evaluateDragBlock(RenderBox cardBox, Offset globalPosition) {
    final selection = ref.read(selectedAppointmentProvider);
    if (!selection.contains(widget.appointment.id)) {
      _updateDragBlock(false);
      return;
    }

    final localPos = cardBox.globalToLocal(globalPosition);
    final cardHeight = cardBox.size.height;
    final distanceFromBottom = cardHeight - localPos.dy;

    final minHeightForBlocking =
        _layoutConfig.slotHeight * _minSlotsForDragBlock;

    final shouldBlock =
        distanceFromBottom >= 0 &&
        distanceFromBottom <= _dragBlockZoneHeight &&
        cardHeight >= minHeightForBlocking;

    _updateDragBlock(shouldBlock);
  }

  void _updateDragBlock(bool value) {
    if (_blockDragDuringResize == value) return;
    if (!mounted) {
      _blockDragDuringResize = value;
      return;
    }
    setState(() => _blockDragDuringResize = value);
  }

  // 🔹 Logica per il tap su DESKTOP/TABLET
  void _handleDesktopTap() async {
    final resizingNow = ref.read(isResizingProvider);
    if (resizingNow) return;

    _selectAppointment(ref);

    ref.read(dragOffsetProvider.notifier).clear();
    ref.read(dragOffsetXProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(highlightedStaffIdProvider.notifier).clear();

    // Legge l'appuntamento aggiornato dal provider (potrebbe essere stato
    // modificato tramite resize o drag)
    final currentAppointment = ref
        .read(appointmentsProvider)
        .requireValue
        .firstWhere((a) => a.id == widget.appointment.id);

    // Apre direttamente la vista di modifica dell'appuntamento
    await showAppointmentDialog(context, ref, initial: currentAppointment);

    if (!mounted) return;
    ref.read(selectedAppointmentProvider.notifier).clear();
  }

  // 🔹 Logica per il tap su MOBILE (apre il dialogo di modifica come prima)
  void _handleMobileTap() async {
    final resizingNow = ref.read(isResizingProvider);
    if (resizingNow) return;

    _selectAppointment(ref);

    // Legge l'appuntamento aggiornato dal provider (potrebbe essere stato
    // modificato tramite resize o drag)
    final currentAppointment = ref
        .read(appointmentsProvider)
        .requireValue
        .firstWhere((a) => a.id == widget.appointment.id);

    // Apre direttamente la vista di modifica dell'appuntamento
    await showAppointmentDialog(context, ref, initial: currentAppointment);

    if (!mounted) return;
    ref.read(selectedAppointmentProvider.notifier).clear();
  }

  Widget _buildCard({
    bool isGhost = false,
    bool forFeedback = false,
    bool showThickBorder = false,
    bool isResizingDisabled = false,
    required bool isSelected,
    DateTime? overrideStart,
    DateTime? overrideEnd,
  }) {
    final resizingEntry = ref.watch(
      resizingEntryProvider(widget.appointment.id),
    );
    final booking = ref.watch(bookingsProvider)[widget.appointment.bookingId];
    final bookingNotes = booking?.notes?.trim();
    final clientNotes = widget.appointment.clientId != null
        ? ref
              .watch(clientsByIdProvider)[widget.appointment.clientId!]
              ?.notes
              ?.trim()
        : null;
    final hasBookingNotes = bookingNotes != null && bookingNotes.isNotEmpty;
    final hasClientNotes = clientNotes != null && clientNotes.isNotEmpty;
    final hasNotes = hasBookingNotes || hasClientNotes;

    final baseColor = widget.color.withOpacity(0.15);
    const r = BorderRadius.all(Radius.circular(6));

    final startTime = overrideStart ?? widget.appointment.startTime;
    final endTime =
        resizingEntry?.provisionalEndTime ??
        overrideEnd ??
        widget.appointment.endTime;

    final start = _formatTime(startTime);
    final formattedEndTime = _formatTime(endTime);
    final client = widget.appointment.clientName;

    final pieces = <String>[];
    if (widget.appointment.serviceName.isNotEmpty) {
      pieces.add(widget.appointment.serviceName);
    }
    if (widget.appointment.formattedPrice.isNotEmpty) {
      pieces.add(widget.appointment.formattedPrice);
    }
    final info = pieces.join(' – ');
    final borderWidth = showThickBorder ? 2.5 : 1.0;

    final animationDuration = _isDraggingResize || forFeedback
        ? Duration.zero
        : const Duration(milliseconds: 80);
    final animationCurve = _isDraggingResize || forFeedback
        ? Curves.linear
        : Curves.easeOutQuad;

    return Opacity(
      opacity: isGhost ? AgendaTheme.ghostOpacity : 1,
      child: Material(
        borderRadius: r,
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          decoration: BoxDecoration(
            color: Color.alphaBlend(baseColor, Colors.white),
            borderRadius: r,
            border: Border.all(color: widget.color, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(showThickBorder ? 0.25 : 0.1),
                blurRadius: showThickBorder ? 8 : 4,
                offset: showThickBorder
                    ? const Offset(2, 3)
                    : const Offset(1, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              _ExtraMinutesBand(
                ratio: _extraMinutesRatio(startTime, endTime),
                color: widget.color,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _buildContent(
                    start,
                    formattedEndTime,
                    client,
                    info,
                    showNotes: hasNotes && !forFeedback,
                    onNotesTap: hasNotes && !forFeedback
                        ? () => _showNotesDialog(
                            bookingNotes: hasBookingNotes ? bookingNotes : null,
                            clientNotes: hasClientNotes ? clientNotes : null,
                          )
                        : null,
                  ),
                ),
              ),
              if (!forFeedback && !isResizingDisabled && isSelected)
                _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final dayStart = DateTime(
      widget.appointment.startTime.year,
      widget.appointment.startTime.month,
      widget.appointment.startTime.day,
    );

    final dayBoundary = dayStart.add(const Duration(days: 1));
    if (time.isAtSameMomentAs(dayBoundary)) return '24:00';

    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  // Menu contestuale disabilitato su desktop: rimosso

  Widget _buildContent(
    String start,
    String end,
    String client,
    String info, {
    required bool showNotes,
    VoidCallback? onNotesTap,
  }) {
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$start - $end  ',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: client,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showNotes)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: context.l10n.appointmentNotesTitle,
                      child: InkWell(
                        onTap: onNotesTap,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (info.isNotEmpty)
            Flexible(
              child: Text(
                info,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotesDialog({String? bookingNotes, String? clientNotes}) {
    if ((bookingNotes == null || bookingNotes.trim().isEmpty) &&
        (clientNotes == null || clientNotes.trim().isEmpty)) {
      return;
    }
    final l10n = context.l10n;
    final sections = <Widget>[];
    if (clientNotes != null && clientNotes.trim().isNotEmpty) {
      sections.add(
        Text(
          l10n.clientNoteLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
      sections.add(const SizedBox(height: 4));
      sections.add(Text(clientNotes.trim()));
    }
    if (bookingNotes != null && bookingNotes.trim().isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 12));
      }
      sections.add(
        Text(
          l10n.appointmentNoteLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
      sections.add(const SizedBox(height: 4));
      sections.add(Text(bookingNotes.trim()));
    }
    showAppInfoDialog(
      context,
      title: Text(l10n.appointmentNotesTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      ),
      closeLabel: l10n.actionClose,
    );
  }

  double _extraMinutesRatio(DateTime start, DateTime end) {
    final totalMinutes = end.difference(start).inMinutes;
    if (totalMinutes <= 0) return 0;
    final extra = _extraMinutesForAppointment();
    if (extra <= 0) return 0;
    final ratio = extra / totalMinutes;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  int _extraMinutesForAppointment() {
    return widget.appointment.blockedExtraMinutes;
  }

  void _performResizeUpdate(PointerEvent details) {
    if (_lastPointerGlobalPosition == null) return;
    final currentGlobal = details.position;
    final deltaY = currentGlobal.dy - _lastPointerGlobalPosition!.dy;
    _lastPointerGlobalPosition = currentGlobal;

    final minutesPerPixel =
        _layoutConfig.minutesPerSlot / _layoutConfig.slotHeight;
    final pixelsPerMinute = 1 / minutesPerPixel;
    final dayEnd = DateTime(
      widget.appointment.startTime.year,
      widget.appointment.startTime.month,
      widget.appointment.startTime.day,
    ).add(const Duration(days: 1));

    ref
        .read(resizingProvider.notifier)
        .updateDuringResize(
          appointmentId: widget.appointment.id,
          deltaDy: deltaY,
          pixelsPerMinute: pixelsPerMinute,
          dayEnd: dayEnd,
          minDurationMinutes: 5,
          snapMinutes: 5,
        );
  }

  void _performResizeEnd() async {
    final newEnd = ref
        .read(resizingProvider.notifier)
        .commitResizeAndEnd(appointmentId: widget.appointment.id);

    if (newEnd != null) {
      final appt = widget.appointment;
      final minEnd = appt.startTime.add(const Duration(minutes: 5));
      ref
          .read(appointmentsProvider.notifier)
          .moveAppointment(
            appointmentId: appt.id,
            newStaffId: appt.staffId,
            newStart: appt.startTime,
            newEnd: newEnd.isAfter(minEnd) ? newEnd : minEnd,
          );
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _isDraggingResize = false);
    _lastPointerGlobalPosition = null;
    _updateDragBlock(false);
    ref.read(isResizingProvider.notifier).stop();
    ref.invalidate(resizingProvider);
    if (ref.read(dragPositionProvider) != null) {
      ref.read(dragPositionProvider.notifier).clear();
    }
  }

  void _performResizeCancel() {
    ref
        .read(resizingProvider.notifier)
        .cancelResize(appointmentId: widget.appointment.id);
    ref.read(isResizingProvider.notifier).stop();

    if (mounted) {
      setState(() => _isDraggingResize = false);
    }
    _updateDragBlock(false);
    if (ref.read(dragPositionProvider) != null) {
      ref.read(dragPositionProvider.notifier).clear();
    }
  }

  // 🔹 Resize identico all’originale
  Widget _buildResizeHandle() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            final currentHeightPx = renderBox?.size.height ?? 0;
            _lastPointerGlobalPosition = details.globalPosition;
            _updateDragBlock(true);

            ref
                .read(resizingProvider.notifier)
                .startResize(
                  appointmentId: widget.appointment.id,
                  currentHeightPx: currentHeightPx,
                  startTime: widget.appointment.startTime,
                  endTime: widget.appointment.endTime,
                );
            ref.read(isResizingProvider.notifier).start();
            setState(() => _isDraggingResize = true);
          },
          onVerticalDragUpdate: (details) {
            // Gestito da onPointerMove
          },
          onVerticalDragEnd: (_) {
            // Gestito da onPointerUp
          },
          onVerticalDragCancel: () {
            // Gestito da onPointerCancel
          },
          child: Container(
            height: 20,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 1),
              child: Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerFeedback(
    BuildContext context,
    WidgetRef ref,
    bool isSelected,
  ) {
    final layoutConfig = ref.watch(layoutConfigProvider);
    final times = ref.watch(tempDragTimeProvider);
    final start = times?.$1;
    final end = times?.$2;

    final dragPos = ref.watch(dragPositionProvider);
    final offY = ref.watch(dragOffsetProvider) ?? 0;
    final offX = ref.watch(dragOffsetXProvider) ?? 0;
    final link = ref.watch(dragLayerLinkProvider);

    final highlightedId = ref.watch(highlightedStaffIdProvider);
    final columnsRects = ref.watch(staffColumnsGeometryProvider);

    final padding = LayoutConfig.columnInnerPadding;
    final fallbackWidth = widget.columnWidth ?? _lastSize?.width ?? 180.0;
    double effectiveWidth = widget.dragTargetWidth ?? fallbackWidth;
    if (effectiveWidth <= 0) {
      effectiveWidth = fallbackWidth > 0 ? fallbackWidth : 180.0;
    }
    final h = _lastSize?.height ?? 50.0;

    if (dragPos == null) return const SizedBox.shrink();

    final bodyBox = ref.read(dragBodyBoxProvider);
    final totalHeight = bodyBox?.size.height ?? layoutConfig.totalHeight;
    final cardHeight = h;

    final double unconstrainedTop = dragPos.dy - offY;
    double top = unconstrainedTop;
    double translateY = 0;

    double maxTop = totalHeight - cardHeight;
    if (maxTop < 0) maxTop = 0;

    if (unconstrainedTop < 0) {
      translateY = 0;
      top = 0;
    } else if (unconstrainedTop > maxTop) {
      translateY = 0;
      top = maxTop;
    }

    double left;
    final rect = highlightedId != null ? columnsRects[highlightedId] : null;

    // Limitiamo sempre la X minima all'inizio del body (0 + padding),
    // così il feedback non entra mai nell'area della colonna oraria.
    final double globalMinLeft = padding;
    double minLeft = rect != null ? rect.left + padding : padding;
    if (minLeft < globalMinLeft) minLeft = globalMinLeft;

    if (rect != null) {
      left = rect.left + padding;
      final availableWidth = rect.width - padding * 2;
      if (availableWidth > 0 && availableWidth < effectiveWidth) {
        effectiveWidth = availableWidth;
      } else if (availableWidth > 0 && widget.dragTargetWidth == null) {
        effectiveWidth = availableWidth;
      }
      if (left < minLeft) left = minLeft;
    } else {
      left = dragPos.dx - offX - padding;
      if (widget.expandToLeft) left -= (effectiveWidth / 2);
      if (left < minLeft) left = minLeft;
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    left = (left * dpr).round() / dpr;
    top = (top * dpr).round() / dpr;
    translateY = (translateY * dpr).round() / dpr;

    // 🔹 Se non abbiamo ancora il bodyBox, evitiamo di disegnare il feedback
    if (bodyBox == null) {
      return const SizedBox.shrink();
    }

    // 🔹 Clip minimo solo verticalmente, manteniamo la larghezza della card.
    return RepaintBoundary(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: Offset(left, top),
        child: SizedBox(
          width: effectiveWidth,
          height: h,
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Material(
                color: Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                clipBehavior: Clip.antiAlias,
                child: _buildCard(
                  forFeedback: true,
                  showThickBorder: true,
                  overrideStart: start,
                  overrideEnd: end,
                  isSelected: isSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} // Closing brace for _AppointmentCardInteractiveState

class _ExtraMinutesBand extends StatelessWidget {
  const _ExtraMinutesBand({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (ratio <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: ratio,
          widthFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
