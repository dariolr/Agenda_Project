import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../providers/agenda_providers.dart'; // dragPositionProvider

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (mounted && (_lastSize == null || _lastSize != newSize)) {
            setState(() => _lastSize = newSize);
          }
        });

        return LongPressDraggable<Appointment>(
          data: widget.appointment,
          feedback: _buildFeedback(),
          childWhenDragging: _buildPlaceholder(),
          dragAnchorStrategy: childDragAnchorStrategy,

          // 🔵 aggiorna la posizione globale durante il drag
          onDragStarted: () {},
          onDragUpdate: (details) {
            ref
                .read(dragPositionProvider.notifier)
                .update(details.globalPosition);
          },
          onDragEnd: (_) {
            ref.read(dragPositionProvider.notifier).clear();
          },
          onDragCompleted: () {
            ref.read(dragPositionProvider.notifier).clear();
          },
          onDraggableCanceled: (_, __) {
            ref.read(dragPositionProvider.notifier).clear();
          },

          child: _buildCard(isDragging: false),
        );
      },
    );
  }

  Widget _buildCard({required bool isDragging}) {
    final baseColor = widget.color.withOpacity(0.15);
    const borderRadius = BorderRadius.all(Radius.circular(6));

    final start =
        '${widget.appointment.startTime.hour.toString().padLeft(2, '0')}:${widget.appointment.startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${widget.appointment.endTime.hour.toString().padLeft(2, '0')}:${widget.appointment.endTime.minute.toString().padLeft(2, '0')}';
    final client = widget.appointment.clientName;

    final servicesText = widget.appointment.formattedServices;
    final priceText = widget.appointment.formattedPrice;

    String infoLine = servicesText;
    if (priceText.isNotEmpty) {
      infoLine = infoLine.isEmpty ? priceText : '$servicesText – $priceText';
    }

    return Material(
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
          child: FittedBox(
            alignment: Alignment.topLeft,
            fit: BoxFit.scaleDown, // ✅ ridimensiona automaticamente
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔸 Riga 1 → orario + cliente
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final size = _lastSize;
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size?.width,
        height: size?.height,
        child: _buildCard(isDragging: true),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final size = _lastSize;
    return SizedBox(
      width: size?.width ?? double.infinity,
      height: size?.height ?? 0,
    );
  }
}
