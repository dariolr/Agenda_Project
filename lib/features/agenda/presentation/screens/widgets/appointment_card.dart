import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../providers/agenda_providers.dart';
import '../../../providers/drag_offset_provider.dart';
import '../../../providers/dragged_appointment_provider.dart';
import '../../../providers/temp_drag_time_provider.dart';

class AppointmentCard extends ConsumerStatefulWidget {
  final Appointment appointment;
  final Color color;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.color,
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
        // 🔹 Registra la dimensione effettiva (serve per larghezza del feedback)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (mounted && (_lastSize == null || _lastSize != newSize)) {
            setState(() => _lastSize = newSize);
          }
        });

        return Listener(
          onPointerDown: (event) {
            // 🔹 Registra la posizione di impuntatura del mouse/touch
            final local = event.localPosition.dy;
            ref.read(dragOffsetProvider.notifier).set(local);
          },
          child: LongPressDraggable<Appointment>(
            data: widget.appointment,

            // 🔸 Feedback con orario live
            feedback: Consumer(
              builder: (context, ref, _) => Transform.scale(
                scale: 1.0, // evita scaling overlay
                child: _buildFeedback(context, ref),
              ),
            ),

            feedbackOffset: Offset.zero,
            dragAnchorStrategy: childDragAnchorStrategy,
            childWhenDragging: _buildCard(isDragging: false, isGhost: true),

            // 🔹 Inizio e fine drag
            onDragStarted: () {
              ref
                  .read(draggedAppointmentIdProvider.notifier)
                  .set(widget.appointment.id);
            },
            onDragEnd: (_) => _handleDragEnd(ref),
            onDragCompleted: () => _handleDragEnd(ref),
            onDraggableCanceled: (_, __) => _handleDragEnd(ref),

            // 🔹 Tracciamento continuo del cursore
            onDragUpdate: (details) {
              ref
                  .read(dragPositionProvider.notifier)
                  .update(details.globalPosition);
            },

            // 🔹 Card normale
            child: _buildCard(isDragging: false),
          ),
        );
      },
    );
  }

  void _handleDragEnd(WidgetRef ref) {
    ref.read(draggedAppointmentIdProvider.notifier).clear();
    ref.read(dragOffsetProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
    ref.read(tempDragTimeProvider.notifier).clear();
  }

  /// 🔹 Card base (usata sia nel layout che nel feedback)
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
        // 🔸 Riga 1 → orario + cliente (ora dinamico)
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$start - $end  ',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: client,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // 🔸 Riga 2 → servizi + prezzo
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
                ? content // feedback → no FittedBox
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

  /// 🔹 Feedback (card in movimento con orario aggiornato live)
  Widget _buildFeedback(BuildContext context, WidgetRef ref) {
    final size = _lastSize ?? const Size(180, 60);
    final times = ref.watch(tempDragTimeProvider);

    final liveStart = times?.$1;
    final liveEnd = times?.$2;

    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
        child: _buildCard(
          isDragging: true,
          forFeedback: true,
          overrideStart: liveStart,
          overrideEnd: liveEnd,
        ),
      ),
    );
  }
}
