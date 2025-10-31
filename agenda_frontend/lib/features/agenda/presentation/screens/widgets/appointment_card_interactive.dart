import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
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
import '../../../providers/highlighted_staff_provider.dart';
import '../../../providers/is_resizing_provider.dart';
import '../../../providers/resizing_provider.dart';
import '../../../providers/selected_appointment_provider.dart';
import '../../../providers/staff_columns_geometry_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';

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

class _AppointmentCardInteractiveState
    extends ConsumerState<AppointmentCardInteractive> {
  Size? _lastSize;
  Offset? _lastPointerGlobalPosition;
  bool _isDraggingResize = false;
  bool _blockDragDuringResize = false;

  static const double _dragBlockZoneHeight = 28.0;
  static const int _minSlotsForDragBlock = 3;

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedAppointmentProvider);
    final draggedId = ref.watch(draggedAppointmentIdProvider);
    final formFactor = ref.watch(formFactorProvider);

    final isSelected = selectedId == widget.appointment.id;
    final isDragging = draggedId == widget.appointment.id;
    final showThickBorder = isSelected || isDragging;

    return LayoutBuilder(
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
            final cardBox = context.findRenderObject() as RenderBox?;
            if (cardBox != null) {
              _evaluateDragBlock(cardBox, e.position);
            }
          },
          onPointerUp: (e) {
            // Se dragPositionProvider è ancora attivo, resettalo. Questo gestisce i casi in cui onDragEnd potrebbe non attivarsi.
            if (ref.read(dragPositionProvider) != null) {
              ref.read(dragPositionProvider.notifier).clear();
            }
            _updateDragBlock(false);
          },
          onPointerCancel: (e) {
            // Resetta anche in caso di cancellazione del puntatore.
            if (ref.read(dragPositionProvider) != null) {
              ref.read(dragPositionProvider.notifier).clear();
            }
            _updateDragBlock(false);
          },

          // 🔹 Qui differenziamo tap (desktop vs mobile)
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
                    _buildFollowerFeedback(c, r, isSelected, formFactor),
              ),
              feedbackOffset: Offset.zero,
              dragAnchorStrategy: childDragAnchorStrategy,
              hapticFeedbackOnStart: false,
              maxSimultaneousDrags: _blockDragDuringResize ? 0 : 1,
              childWhenDragging: _buildCard(
                isGhost: true,
                showThickBorder: showThickBorder,
                isSelected: isSelected,
                formFactor: formFactor,
              ),

              onDragStarted: () {
                final selected = ref.read(selectedAppointmentProvider.notifier);
                selected.clear();
                selected.toggle(widget.appointment.id);
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

              onDragEnd: (_) => _handleEnd(ref),
              onDragCompleted: () => _handleEnd(ref),
              onDraggableCanceled: (_, __) => _handleEnd(ref),

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
    );
  }

  void _handleEnd(WidgetRef ref) {
    ref.read(draggedAppointmentIdProvider.notifier).clear();
    ref.read(dragOffsetProvider.notifier).clear();
    ref.read(dragOffsetXProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(tempDragTimeProvider.notifier).clear();
    ref.read(selectedAppointmentProvider.notifier).clear();
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
        LayoutConfig.slotHeight * _minSlotsForDragBlock;

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

    final sel = ref.read(selectedAppointmentProvider.notifier);
    sel.clear();
    sel.toggle(widget.appointment.id);

    ref.read(dragOffsetProvider.notifier).clear();
    ref.read(dragOffsetXProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(highlightedStaffIdProvider.notifier).clear();
  }

  // 🔹 Logica per il tap su MOBILE
  void _handleMobileTap() async {
    final resizingNow = ref.read(isResizingProvider);
    if (resizingNow) return;

    // Select the appointment when the bottom sheet is opened
    ref
        .read(selectedAppointmentProvider.notifier)
        .clear(); // Clear any previous selection
    ref
        .read(selectedAppointmentProvider.notifier)
        .toggle(widget.appointment.id);

    // Apre il nuovo "smart" bottom sheet
    await _openSmartBottomSheet(); // Await the dismissal

    // Clear selection when bottom sheet is dismissed
    ref.read(selectedAppointmentProvider.notifier).clear();
  }

  Future<void> _openSmartBottomSheet() async {
    await AppBottomSheet.show(
      context: context,
      builder: (_) => _AppointmentActionSheet(appointment: widget.appointment),
    );
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
            if (_lastPointerGlobalPosition == null) return;
            final currentGlobal = details.globalPosition;
            final deltaY = currentGlobal.dy - _lastPointerGlobalPosition!.dy;
            _lastPointerGlobalPosition = currentGlobal;

            final minutesPerPixel =
                LayoutConfig.minutesPerSlot / LayoutConfig.slotHeight;
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
          },
          onVerticalDragEnd: (_) async {
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
          },
          onVerticalDragCancel: () {
            ref
                .read(resizingProvider.notifier)
                .cancelResize(appointmentId: widget.appointment.id);
            ref.read(isResizingProvider.notifier).stop();
            setState(() => _isDraggingResize = false);
            _updateDragBlock(false);
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
    final hourW = LayoutConfig.hourColumnWidth;

    if (dragPos == null) return const SizedBox.shrink();

    double top = dragPos.dy - offY;
    if (top < 0) top = 0;

    final bodyBox = ref.read(dragBodyBoxProvider);
    final totalHeight = bodyBox?.size.height ?? LayoutConfig.totalHeight;
    final cardHeight = h;
    if (top + cardHeight > totalHeight) top = totalHeight - cardHeight;
    if (top < 0) top = 0;

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

    return RepaintBoundary(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: Offset(left, top),
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: w - 4,
              maxWidth: w - 4,
              minHeight: h,
              maxHeight: h,
            ),
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
                  Navigator.pop(context); // Close the bottom sheet
                  ref.read(selectedAppointmentProvider.notifier).clear();
                  ref
                      .read(selectedAppointmentProvider.notifier)
                      .toggle(appointment.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funzione Resize da implementare'),
                    ),
                  );
                },
                child: Text(context.l10n.actionResize),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppFilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  ref.read(selectedAppointmentProvider.notifier).clear();
                  ref
                      .read(selectedAppointmentProvider.notifier)
                      .toggle(appointment.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funzione Sposta da implementare'),
                    ),
                  );
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
