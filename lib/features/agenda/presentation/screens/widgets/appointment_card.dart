import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../core/models/appointment.dart';
import '../../../domain/config/agenda_theme.dart';
import '../../../providers/agenda_providers.dart'; // dragPositionProvider
import '../../../providers/dragged_appointment_provider.dart'; // gestione fantasma

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
          // 👻 Durante il drag la card originale resta semitrasparente
          childWhenDragging: _buildCard(isDragging: false, isGhost: true),
          dragAnchorStrategy: childDragAnchorStrategy,

          // 🔵 Inizio drag → segna l'appuntamento trascinato
          onDragStarted: () {
            ref
                .read(draggedAppointmentIdProvider.notifier)
                .set(widget.appointment.id);
          },

          // 🔴 Fine drag o rilascio → rimuove subito il fantasma
          onDragEnd: (_) => _handleDragEnd(ref),
          onDragCompleted: () => _handleDragEnd(ref),
          onDraggableCanceled: (_, __) => _handleDragEnd(ref),

          // 🔁 Aggiorna posizione globale del cursore
          onDragUpdate: (details) {
            ref
                .read(dragPositionProvider.notifier)
                .update(details.globalPosition);
          },

          // ✅ Card normale (non in drag)
          child: _buildCard(isDragging: false),
        );
      },
    );
  }

  void _handleDragEnd(WidgetRef ref) {
    ref.read(draggedAppointmentIdProvider.notifier).clear();
    ref.read(dragPositionProvider.notifier).clear();
  }

  Widget _buildCard({required bool isDragging, bool isGhost = false}) {
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

    // 👻 Opacità fantasma regolabile da AgendaTheme
    final double opacity = isGhost ? AgendaTheme.ghostOpacity : 1.0;

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
            child: FittedBox(
              alignment: Alignment.topLeft,
              fit: BoxFit.scaleDown,
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
}
