import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/appointment.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/drag_layer_link_provider.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
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

  @override
  Widget build(BuildContext context) {
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
            _lastPointerGlobalPosition = e.position;

            final bodyBox = ref.read(dragBodyBoxProvider);
            final cardBox = context.findRenderObject() as RenderBox?;

            if (bodyBox != null && cardBox != null) {
              final cardTopLeftGlobal = cardBox.localToGlobal(Offset.zero);
              final cardTopLeftLocalToBody = bodyBox.globalToLocal(
                cardTopLeftGlobal,
              );

              ref
                  .read(dragOffsetProvider.notifier)
                  .set(e.position.dy - cardTopLeftGlobal.dy);
              ref
                  .read(dragOffsetXProvider.notifier)
                  .set(e.position.dx - cardTopLeftGlobal.dx);

              // Sincronizza anche la posizione iniziale nel body
              final localStart = bodyBox.globalToLocal(e.position);
              ref.read(dragPositionProvider.notifier).set(localStart);
            }

            ref
                .read(draggedAppointmentIdProvider.notifier)
                .set(widget.appointment.id);
          },

          child: LongPressDraggable<Appointment>(
            data: widget.appointment,
            feedback: Consumer(
              builder: (c, r, _) => _buildFollowerFeedback(c, r),
            ),
            feedbackOffset: Offset.zero,
            dragAnchorStrategy: childDragAnchorStrategy,
            hapticFeedbackOnStart: false,
            childWhenDragging: _buildCard(isDragging: false, isGhost: true),

            // ✅ inizializza subito la posizione del feedback al long press
            onDragStarted: () {
              final bodyBox = ref.read(dragBodyBoxProvider);
              if (bodyBox != null && _lastPointerGlobalPosition != null) {
                // Converti subito in coordinate locali del body
                final local = bodyBox.globalToLocal(
                  _lastPointerGlobalPosition!,
                );

                // Sincronizza subito tutto
                ref.read(dragPositionProvider.notifier).set(local);
              }
            },

            // 🔁 smoothing + coordinate locali al body
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
            child: _buildCard(isDragging: false),
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
  }

  Widget _buildCard({
    required bool isDragging,
    bool isGhost = false,
    bool forFeedback = false,
    DateTime? overrideStart,
    DateTime? overrideEnd,
  }) {
    final baseColor = widget.color.withOpacity(0.15);
    const r = BorderRadius.all(Radius.circular(6));
    final startTime = overrideStart ?? widget.appointment.startTime;
    final endTime = overrideEnd ?? widget.appointment.endTime;

    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final client = widget.appointment.clientName;

    final pieces = <String>[];
    if (widget.appointment.formattedServices.isNotEmpty) {
      pieces.add(widget.appointment.formattedServices);
    }
    if (widget.appointment.formattedPrice.isNotEmpty) {
      pieces.add(widget.appointment.formattedPrice);
    }
    final info = pieces.join(' – ');

    return Opacity(
      opacity: isGhost ? AgendaTheme.ghostOpacity : 1,
      child: Material(
        borderRadius: r,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Color.alphaBlend(baseColor, Colors.white),
            borderRadius: r,
            border: Border.all(color: widget.color, width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(isDragging ? 0.3 : 0.1),
                blurRadius: isDragging ? 8 : 4,
                offset: isDragging ? const Offset(2, 3) : const Offset(1, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: DefaultTextStyle(
            style: AgendaTheme.appointmentTextStyle.copyWith(
              fontSize: 12.5,
              height: 1.15,
            ),
            child: forFeedback
                ? _buildContent(start, end, client, info)
                : FittedBox(
                    alignment: Alignment.topLeft,
                    fit: BoxFit.scaleDown,
                    child: _buildContent(start, end, client, info),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String start, String end, String client, String info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          maxLines: 1,
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
        if (info.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              info,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                height: 1.1,
              ),
            ),
          ),
      ],
    );
  }

  /// Feedback ancorato al body (coordinate locali, zero offset da header/rail)
  Widget _buildFollowerFeedback(BuildContext context, WidgetRef ref) {
    final times = ref.watch(tempDragTimeProvider);
    final start = times?.$1;
    final end = times?.$2;

    final dragPos = ref.watch(dragPositionProvider);
    final offY = ref.watch(dragOffsetProvider) ?? 0;
    final offX = ref.watch(dragOffsetXProvider) ?? 0;
    final link = ref.watch(dragLayerLinkProvider);

    final w = widget.columnWidth ?? _lastSize?.width ?? 180.0;
    final h = _lastSize?.height ?? 50.0;
    final hourW = LayoutConfig.hourColumnWidth;

    if (dragPos == null) return const SizedBox.shrink();

    double left = dragPos.dx - offX;
    double top = dragPos.dy - offY;

    if (widget.expandToLeft) left -= (w / 2);
    if (left < hourW) left = hourW;
    if (top < 0) top = 0;

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
              isDragging: true,
              forFeedback: true,
              overrideStart: start,
              overrideEnd: end,
            ),
          ),
        ),
      ),
    );
  }
}
