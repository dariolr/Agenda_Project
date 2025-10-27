import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
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

class AppointmentCard extends ConsumerStatefulWidget {
  final Appointment appointment;
  final Color color;
  final double? columnWidth;
  final bool expandToLeft;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.color,
    this.columnWidth,
    this.expandToLeft = false,
  });

  @override
  ConsumerState<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<AppointmentCard> {
  Size? _lastSize;
  Offset? _lastPointerGlobalPosition;
  double? _tempHeight;
  double? _initialHeight;
  bool _isDraggingResize = false;

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedAppointmentProvider);
    final draggedId = ref.watch(draggedAppointmentIdProvider);
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

          child: GestureDetector(
            onTap: () {
              final resizing = ref.read(isResizingProvider);
              if (!resizing) {
                final notifier = ref.read(selectedAppointmentProvider.notifier);
                notifier.clear();
                notifier.toggle(widget.appointment.id);

                ref.read(dragOffsetProvider.notifier).clear();
                ref.read(dragOffsetXProvider.notifier).clear();
                ref.read(dragPositionProvider.notifier).clear();
                ref.read(highlightedStaffIdProvider.notifier).clear();
              }
            },

            child: LongPressDraggable<Appointment>(
              data: widget.appointment,
              feedback: Consumer(
                builder: (c, r, _) => _buildFollowerFeedback(c, r),
              ),
              feedbackOffset: Offset.zero,
              dragAnchorStrategy: childDragAnchorStrategy,
              hapticFeedbackOnStart: false,
              childWhenDragging: _buildCard(
                isGhost: true,
                showThickBorder: showThickBorder,
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

  Widget _buildCard({
    bool isGhost = false,
    bool forFeedback = false,
    bool showThickBorder = false,
    bool isResizingDisabled = false,
    DateTime? overrideStart,
    DateTime? overrideEnd,
  }) {
    final entry = ref.watch(resizingEntryProvider(widget.appointment.id));

    final baseColor = widget.color.withOpacity(0.15);
    const r = BorderRadius.all(Radius.circular(6));
    final startTime = overrideStart ?? widget.appointment.startTime;
    final endTime =
        entry?.provisionalEndTime ?? overrideEnd ?? widget.appointment.endTime;

    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
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
                  child: _buildContent(start, end, client, info),
                ),
              ),
              if (!forFeedback && !isResizingDisabled) _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildResizeHandle() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {
            final h = _lastSize?.height ?? 0;
            _initialHeight = h;
            ref.read(isResizingProvider.notifier).start();
            ref.read(resizingProvider.notifier).start(widget.appointment.id, h);
            setState(() {
              _isDraggingResize = true;
              _tempHeight = h;
            });
          },
          onVerticalDragUpdate: (details) {
            final previous = _tempHeight ?? _lastSize?.height ?? 0;
            final next = (previous + details.delta.dy)
                .clamp(20, double.infinity)
                .toDouble();

            setState(() => _tempHeight = next);
            ref
                .read(resizingProvider.notifier)
                .updateHeight(widget.appointment.id, next);

            final appt = widget.appointment;
            final minutesPerPixel =
                LayoutConfig.minutesPerSlot / LayoutConfig.slotHeight;
            final baseHeight = _initialHeight ?? _lastSize?.height ?? 0;
            final deltaPixels = next - baseHeight;

            final deltaMinutesRaw = (deltaPixels * minutesPerPixel);
            final deltaMinutes = ((deltaMinutesRaw / 5).round() * 5).toInt();

            final previewEnd = appt.endTime.add(
              Duration(minutes: deltaMinutes),
            );
            ref
                .read(resizingProvider.notifier)
                .updateProvisionalEndTime(widget.appointment.id, previewEnd);
          },
          onVerticalDragEnd: (_) {
            final appt = widget.appointment;
            final notifier = ref.read(appointmentsProvider.notifier);
            final minutesPerPixel =
                LayoutConfig.minutesPerSlot / LayoutConfig.slotHeight;
            final baseHeight = _initialHeight ?? _lastSize?.height ?? 0;
            final deltaPixels = (_tempHeight ?? baseHeight) - baseHeight;
            final deltaMinutes = (deltaPixels * minutesPerPixel).round();

            if (deltaMinutes.abs() >= 5) {
              final steps = (deltaMinutes ~/ 5);
              final newEnd = appt.endTime.add(Duration(minutes: steps * 5));
              final minEnd = appt.startTime.add(const Duration(minutes: 5));

              ref
                  .read(resizingProvider.notifier)
                  .updateProvisionalEndTime(widget.appointment.id, newEnd);

              notifier.moveAppointment(
                appointmentId: appt.id,
                newStaffId: appt.staffId,
                newStart: appt.startTime,
                newEnd: newEnd.isAfter(minEnd) ? newEnd : minEnd,
              );

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }

            setState(() {
              _isDraggingResize = false;
              _tempHeight = null;
            });

            ref.read(isResizingProvider.notifier).stop();
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

  Widget _buildFollowerFeedback(BuildContext context, WidgetRef ref) {
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

    // 🔹 Calcola l’altezza totale effettiva del body scrollabile
    final bodyBox = ref.read(dragBodyBoxProvider);
    final totalHeight = bodyBox?.size.height ?? LayoutConfig.totalHeight;
    final cardHeight = h;

    // 🔹 Impedisce di superare la fine dell’area visibile (ancora inferiore)
    if (top + cardHeight > totalHeight) {
      top = totalHeight - cardHeight;
    }

    // 🔹 Sicurezza extra nel caso di overflow negativo
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
            ),
          ),
        ),
      ),
    );
  }
}
