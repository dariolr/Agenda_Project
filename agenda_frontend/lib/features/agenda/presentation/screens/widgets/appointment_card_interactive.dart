import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '/core/models/staff.dart';
import '/core/l10n/l10_extension.dart';
import '/core/widgets/app_bottom_sheet.dart';
import '/core/widgets/app_buttons.dart';
import '../../../../../../app/providers/form_factor_provider.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/appointment_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/dragged_base_range_provider.dart';
import '../../../providers/dragged_last_staff_provider.dart';
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/is_resizing_provider.dart';
import '../../../providers/resizing_provider.dart';
import '../../../providers/selected_appointment_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/staff_providers.dart';

/// 🔹 Versione unificata per DESKTOP e MOBILE.
/// Mantiene drag, resize, ghost, select, ma cambia il comportamento del tap:
/// - Desktop → seleziona la card.
/// - Mobile → apre un bottom sheet con i dettagli.
class AppointmentCardInteractive extends ConsumerStatefulWidget {
  final Appointment appointment;
  final Color color;
  final double? columnWidth;
  final bool expandToLeft;

  const AppointmentCardInteractive({
    super.key,
    required this.appointment,
    required this.color,
    this.columnWidth,
    this.expandToLeft = false,
  });

  @override
  ConsumerState<AppointmentCardInteractive> createState() =>
      _AppointmentCardInteractiveState();
}

enum _AppointmentQuickAction { resize, move }

class _AppointmentCardInteractiveState
    extends ConsumerState<AppointmentCardInteractive> {
  Size? _lastSize;
  Offset? _lastPointerGlobalPosition;
  bool _isDraggingResize = false;
  bool _blockDragDuringResize = false;

  static const double _dragBlockZoneHeight = 28.0;
  static const int _minSlotsForDragBlock = 3;

  LayoutConfig get _layoutConfig => ref.read(layoutConfigProvider);

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedAppointmentProvider);
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final formFactor = ref.watch(formFactorProvider);

    final isSelected = selectedId == widget.appointment.id;
    final isDragging = draggedId == widget.appointment.id;
    final showThickBorder = isSelected || isDragging;

    return MouseRegion(
      onEnter: (_) => _selectAppointment(ref),
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
              onLongPress: () => _selectAppointment(ref),
              child: Draggable<Appointment>(
                data: widget.appointment,
                feedback: Consumer(
                  builder: (c, r, _) =>
                      _buildFollowerFeedback(c, r, isSelected, formFactor),
                ),
                feedbackOffset: Offset.zero,
                dragAnchorStrategy: childDragAnchorStrategy,
                maxSimultaneousDrags: _blockDragDuringResize ? 0 : 1,
                childWhenDragging: _buildCard(
                  isGhost: true,
                  showThickBorder: showThickBorder,
                  isSelected: isSelected,
                  formFactor: formFactor,
                ),

                onDragStarted: () {
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
                  formFactor: formFactor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleEnd(WidgetRef ref, {bool keepSelection = false}) {
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

  void _selectAppointment(WidgetRef ref) {
    final sel = ref.read(selectedAppointmentProvider.notifier);
    sel.clear();
    sel.toggle(widget.appointment.id);
  }

  void _handleDragEnd(WidgetRef ref, DraggableDetails details) {
    if (details.wasAccepted) {
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

    ref.read(appointmentsProvider.notifier).moveAppointment(
          appointmentId: widget.appointment.id,
          newStaffId: dropStaffId,
          newStart: newStart,
          newEnd: newEnd,
        );

    _handleEnd(ref, keepSelection: true);
  }

  void _evaluateDragBlock(RenderBox cardBox, Offset globalPosition) {
    final formFactor = ref.read(formFactorProvider);
    if (formFactor != AppFormFactor.tabletOrDesktop) {
      _updateDragBlock(false);
      return;
    }

    final selectedId = ref.read(selectedAppointmentProvider);
    if (selectedId != widget.appointment.id) {
      _updateDragBlock(false);
      return;
    }

    final localPos = cardBox.globalToLocal(globalPosition);
    final cardHeight = cardBox.size.height;
    final distanceFromBottom = cardHeight - localPos.dy;

    final minHeightForBlocking =
        _layoutConfig.slotHeight * _minSlotsForDragBlock;

    final shouldBlock = distanceFromBottom >= 0 &&
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

  // 🔹 Logica per il tap su DESKTOP
  void _handleDesktopTap() {
    final resizingNow = ref.read(isResizingProvider);
    if (resizingNow) return;

    _selectAppointment(ref);

    ref.read(dragOffsetProvider.notifier).clear();
    ref.read(dragOffsetXProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(highlightedStaffIdProvider.notifier).clear();
  }

  // 🔹 Logica per il tap su MOBILE
  void _handleMobileTap() async {
    final resizingNow = ref.read(isResizingProvider);
    if (resizingNow) return;

    _selectAppointment(ref);

    final action = await _openSmartBottomSheet();

    if (!mounted) return;

    if (action == null) {
      ref.read(selectedAppointmentProvider.notifier).clear();
      return;
    }

    bool executed = false;
    switch (action) {
      case _AppointmentQuickAction.resize:
        executed = await _handleQuickResize();
        break;
      case _AppointmentQuickAction.move:
        executed = await _handleQuickMove();
        break;
    }

    if (!mounted) return;

    if (!executed) {
      ref.read(selectedAppointmentProvider.notifier).clear();
    } else {
      _selectAppointment(ref);
    }
  }

  Future<_AppointmentQuickAction?> _openSmartBottomSheet() {
    return AppBottomSheet.show<_AppointmentQuickAction>(
      context: context,
      builder: (_) => _AppointmentActionSheet(appointment: widget.appointment),
    );
  }

  Future<bool> _handleQuickResize() async {
    final appointment = widget.appointment;
    final start = appointment.startTime;
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayBoundary = dayStart.add(const Duration(days: 1));

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.endTime),
      helpText: context.l10n.actionResize,
    );

    if (picked == null || !mounted) return false;

    int minutes = picked.hour * 60 + picked.minute;
    minutes = _snapMinutes(minutes);
    minutes = minutes.clamp(0, LayoutConfig.hoursInDay * 60);

    var newEnd = dayStart.add(Duration(minutes: minutes));
    final minEnd = start.add(const Duration(minutes: 5));
    if (newEnd.isBefore(minEnd)) newEnd = minEnd;
    if (newEnd.isAfter(dayBoundary)) newEnd = dayBoundary;

    if (newEnd == appointment.endTime) return false;

    ref.read(appointmentsProvider.notifier).moveAppointment(
          appointmentId: appointment.id,
          newStaffId: appointment.staffId,
          newStart: start,
          newEnd: newEnd,
        );

    if (!mounted) return true;

    _selectAppointment(ref);
    final message = '${_formatTime(start)} – ${_formatTime(newEnd)}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.l10n.actionResize}: $message')),
    );

    return true;
  }

  Future<bool> _handleQuickMove() async {
    final appointment = widget.appointment;
    final duration = appointment.endTime.difference(appointment.startTime);
    final dayStart = DateTime(
      appointment.startTime.year,
      appointment.startTime.month,
      appointment.startTime.day,
    );
    final dayBoundary = dayStart.add(const Duration(days: 1));

    final staffList = ref.read(staffProvider);
    int targetStaffId = appointment.staffId;
    if (staffList.length > 1) {
      final chosen = await AppBottomSheet.show<int>(
        context: context,
        builder: (_) => _StaffPickerSheet(
          staff: staffList,
          selectedStaffId: targetStaffId,
        ),
      );
      if (!mounted) return false;
      if (chosen == null) return false;
      targetStaffId = chosen;
    }

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.startTime),
      helpText: context.l10n.actionMove,
    );

    if (pickedStart == null || !mounted) return false;

    int minutes = pickedStart.hour * 60 + pickedStart.minute;
    minutes = _snapMinutes(minutes);
    minutes = minutes.clamp(0, LayoutConfig.hoursInDay * 60);

    var newStart = dayStart.add(Duration(minutes: minutes));
    var newEnd = newStart.add(duration);

    if (newEnd.isAfter(dayBoundary)) {
      newEnd = dayBoundary;
      newStart = newEnd.subtract(duration);
      if (newStart.isBefore(dayStart)) {
        newStart = dayStart;
        newEnd = newStart.add(duration);
      }
    }

    if (newStart == appointment.startTime && targetStaffId == appointment.staffId) {
      return false;
    }

    ref.read(appointmentsProvider.notifier).moveAppointment(
          appointmentId: appointment.id,
          newStaffId: targetStaffId,
          newStart: newStart,
          newEnd: newEnd,
        );

    if (!mounted) return true;

    _selectAppointment(ref);
    final message = '${_formatTime(newStart)} – ${_formatTime(newEnd)}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.l10n.actionMove}: $message')),
    );

    return true;
  }

  int _snapMinutes(int minutes, {int step = 5}) {
    if (step <= 1) return minutes;
    final snapped = (minutes / step).round() * step;
    return snapped.clamp(0, LayoutConfig.hoursInDay * 60);
  }

  Widget _buildCard({
    bool isGhost = false,
    bool forFeedback = false,
    bool showThickBorder = false,
    bool isResizingDisabled = false,
    required bool isSelected,
    required AppFormFactor formFactor,
    DateTime? overrideStart,
    DateTime? overrideEnd,
  }) {
    final resizingEntry = ref.watch(
      resizingEntryProvider(widget.appointment.id),
    );

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _buildContent(start, formattedEndTime, client, info),
                ),
              ),
              if (!forFeedback &&
                  !isResizingDisabled &&
                  isSelected &&
                  formFactor == AppFormFactor.tabletOrDesktop)
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

  Widget _buildContent(String start, String end, String client, String info) {
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
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

    ref.read(resizingProvider.notifier).updateDuringResize(
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
      ref.read(appointmentsProvider.notifier).moveAppointment(
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
    AppFormFactor formFactor,
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

    final w = widget.columnWidth ?? _lastSize?.width ?? 180.0;
    final h = _lastSize?.height ?? 50.0;
    final hourW = layoutConfig.hourColumnWidth;

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
      translateY = unconstrainedTop;
      top = 0;
    } else if (unconstrainedTop > maxTop) {
      translateY = unconstrainedTop - maxTop;
      top = maxTop;
    }

    double left;
    final rect = highlightedId != null ? columnsRects[highlightedId] : null;

    if (rect != null) {
      left = rect.left + (rect.width - w) / 2;
      if (left < hourW) left = hourW;
    } else {
      left = dragPos.dx - offX;
      if (widget.expandToLeft) left -= (w / 2);
      if (left < hourW) left = hourW;
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    left = (left * dpr).round() / dpr;
    top = (top * dpr).round() / dpr;
    translateY = (translateY * dpr).round() / dpr;

    return RepaintBoundary(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: Offset(left, top),
        child: SizedBox(
          width: w - 4,
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
                  formFactor: formFactor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} // Closing brace for _AppointmentCardInteractiveState

class _AppointmentActionSheet extends ConsumerStatefulWidget {
  final Appointment appointment;

  const _AppointmentActionSheet({required this.appointment});

  @override
  ConsumerState<_AppointmentActionSheet> createState() =>
      _AppointmentActionSheetState();
}

class _AppointmentActionSheetState
    extends ConsumerState<_AppointmentActionSheet> {
  bool _showDeleteConfirm = false;

  String _formatTime(DateTime time) {
    final appointment = widget.appointment;
    final dayStart = DateTime(
      appointment.startTime.year,
      appointment.startTime.month,
      appointment.startTime.day,
    );
    final dayBoundary = dayStart.add(const Duration(days: 1));
    if (time.isAtSameMomentAs(dayBoundary)) return '24:00';

    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showDeleteConfirm
          ? _buildConfirmContent(context, appointment)
          : _buildMainContent(context, appointment),
    );
  }

  Widget _buildMainContent(BuildContext context, Appointment appointment) {
    return Column(
      key: const ValueKey('main_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildAppointmentDetails(appointment),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: AppFilledButton(
                onPressed: () {
                  Navigator.pop(context, _AppointmentQuickAction.resize);
                },
                child: Text(context.l10n.actionResize),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppFilledButton(
                onPressed: () {
                  Navigator.pop(context, _AppointmentQuickAction.move);
                },
                child: Text(context.l10n.actionMove),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: AppDangerButton(
                onPressed: () {
                  setState(() => _showDeleteConfirm = true);
                },
                child: Text(context.l10n.actionDelete),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfirmContent(BuildContext context, Appointment appointment) {
    return Column(
      key: const ValueKey('confirm_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildAppointmentDetails(appointment),
        const SizedBox(height: 20),
        Text(
          context.l10n.deleteConfirmationTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppOutlinedActionButton(
                onPressed: () {
                  setState(() => _showDeleteConfirm = false);
                },
                child: Text(context.l10n.actionCancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDangerButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  ref
                      .read(appointmentsProvider.notifier)
                      .deleteAppointment(appointment.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.appointmentDeletedMessage),
                    ),
                  );
                },
                child: Text(context.l10n.actionConfirm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAppointmentDetails(Appointment appointment) {
    final hasPrice = appointment.price != null && appointment.price! > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appointment.clientName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatTime(appointment.startTime)} – ${_formatTime(appointment.endTime)}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        if (appointment.serviceName.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            appointment.serviceName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
        if (hasPrice) ...[
          const SizedBox(height: 4),
          Text(
            appointment.formattedPrice,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ],
    );
  }
}

class _StaffPickerSheet extends StatelessWidget {
  const _StaffPickerSheet({
    required this.staff,
    required this.selectedStaffId,
  });

  final List<Staff> staff;
  final int selectedStaffId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.staffTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...staff.map(
          (s) => ListTile(
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: s.color,
            ),
            title: Text(s.name),
            trailing:
                s.id == selectedStaffId ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, s.id),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
