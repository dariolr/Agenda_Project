import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (mounted && (_lastSize == null || _lastSize != newSize)) {
            setState(() => _lastSize = newSize);
          }
        });

        return Listener(
          onPointerDown: (event) {
            final localY = event.localPosition.dy;
            final localX = event.localPosition.dx;
            ref.read(dragOffsetProvider.notifier).set(localY);
            ref.read(dragOffsetXProvider.notifier).set(localX);
            ref
                .read(draggedAppointmentIdProvider.notifier)
                .set(widget.appointment.id);
          },
          child: LongPressDraggable<Appointment>(
            data: widget.appointment,
            feedback: Consumer(
              builder: (context, ref, _) =>
                  _buildFollowerFeedback(context, ref),
            ),
            feedbackOffset: Offset.zero,
            dragAnchorStrategy: childDragAnchorStrategy,
            childWhenDragging: _buildCard(isDragging: false, isGhost: true),
            onDragEnd: (_) => _handleDragEnd(ref),
            onDragCompleted: () => _handleDragEnd(ref),
            onDraggableCanceled: (_, __) => _handleDragEnd(ref),
            onDragUpdate: (details) {
              ref
                  .read(dragPositionProvider.notifier)
                  .update(details.globalPosition);
            },
            child: _buildCard(isDragging: false),
          ),
        );
      },
    );
  }

  void _handleDragEnd(WidgetRef ref) {
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
    const borderRadius = BorderRadius.all(Radius.circular(6));

    final startTime = overrideStart ?? widget.appointment.startTime;
    final endTime = overrideEnd ?? widget.appointment.endTime;

    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    final client = widget.appointment.clientName;
    final servicesText = widget.appointment.formattedServices;
    final priceText = widget.appointment.formattedPrice;
    String infoLine = servicesText;
    if (priceText.isNotEmpty) {
      infoLine = infoLine.isEmpty ? priceText : '$servicesText – $priceText';
    }

    final double opacity = isGhost ? AgendaTheme.ghostOpacity : 1.0;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$start - $end  ',
                style: TextStyle(
                  color: (isDragging || forFeedback)
                      ? Colors.black87
                      : Colors.grey,
                  fontWeight: (isDragging || forFeedback)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              TextSpan(
                text: client,
                style: TextStyle(
                  color: (isDragging || forFeedback)
                      ? Colors.grey
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (infoLine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              infoLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
                height: 1.1,
              ),
            ),
          ),
      ],
    );

    return Opacity(
      opacity: opacity,
      child: Material(
        borderRadius: borderRadius,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Color.alphaBlend(baseColor, Colors.white),
            borderRadius: borderRadius,
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
                ? content
                : FittedBox(
                    alignment: Alignment.topLeft,
                    fit: BoxFit.scaleDown,
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowerFeedback(BuildContext context, WidgetRef ref) {
    final times = ref.watch(tempDragTimeProvider);
    final liveStart = times?.$1;
    final liveEnd = times?.$2;

    final dragPos = ref.watch(dragPositionProvider);
    final dragOffsetY = ref.watch(dragOffsetProvider) ?? 0.0;
    final dragOffsetX = ref.watch(dragOffsetXProvider) ?? 0.0;
    final link = ref.watch(dragLayerLinkProvider);

    final double feedbackWidth =
        widget.columnWidth ?? _lastSize?.width ?? 180.0;
    final hourW = LayoutConfig.hourColumnWidth;

    if (dragPos == null) return const SizedBox.shrink();

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return const SizedBox.shrink();

    final bodyOriginGlobal = (link.leader != null && link.leader!.attached)
        ? link.leader!.offset
        : Offset.zero;

    final rel = dragPos - bodyOriginGlobal;

    double left = rel.dx - dragOffsetX;
    double top = rel.dy - dragOffsetY;

    if (widget.expandToLeft) {
      left -= (feedbackWidth / 2);
    }
    if (left < hourW) left = hourW;
    if (top < 0) top = 0;

    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: false,
      offset: Offset(left, top),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: feedbackWidth - 4,
            maxWidth: feedbackWidth - 4,
          ),
          child: _buildCard(
            isDragging: true,
            forFeedback: true,
            overrideStart: liveStart,
            overrideEnd: liveEnd,
          ),
        ),
      ),
    );
  }
}
