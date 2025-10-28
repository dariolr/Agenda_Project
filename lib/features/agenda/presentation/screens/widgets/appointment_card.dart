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
        // salviamo la dimensione reale per calcolare il delta di resize
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

                // offset verticale del puntatore dentro la card
                ref
                    .read(dragOffsetProvider.notifier)
                    .set(e.position.dy - cardTopLeftGlobal.dy);

                // offset orizzontale del puntatore dentro la card
                ref
                    .read(dragOffsetXProvider.notifier)
                    .set(e.position.dx - cardTopLeftGlobal.dx);

                // posizione iniziale del drag nel sistema di coordinate del body
                final localStart = bodyBox.globalToLocal(e.position);
                ref.read(dragPositionProvider.notifier).set(localStart);
              }
            }
          },

          child: GestureDetector(
            onTap: () {
              // Evita di selezionare mentre stai ridimensionando
              final resizingNow = ref.read(isResizingProvider);
              if (!resizingNow) {
                final sel = ref.read(selectedAppointmentProvider.notifier);
                sel.clear();
                sel.toggle(widget.appointment.id);

                // pulizia stato drag
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

              // Ghost lasciato al posto originale durante il drag
              childWhenDragging: _buildCard(
                isGhost: true,
                showThickBorder: showThickBorder,
              ),

              onDragStarted: () {
                // seleziona la card che sto trascinando
                final selected = ref.read(selectedAppointmentProvider.notifier);
                selected.clear();
                selected.toggle(widget.appointment.id);

                // segna quale appointment è in drag
                ref
                    .read(draggedAppointmentIdProvider.notifier)
                    .set(widget.appointment.id);

                // aggiorna posizione iniziale nel body
                final bodyBox = ref.read(dragBodyBoxProvider);
                if (bodyBox != null && _lastPointerGlobalPosition != null) {
                  final local = bodyBox.globalToLocal(
                    _lastPointerGlobalPosition!,
                  );
                  ref.read(dragPositionProvider.notifier).set(local);
                }
              },

              onDragUpdate: (details) {
                // follower che segue il cursore ma con smoothing
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

              // Card reale (interattiva, ridimensionabile)
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
    // Stato di resize live da resizingProvider
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
    final end = _formatTime(endTime);

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

    // animazioni morbide solo quando NON sto trascinando il bordo
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

              // Handle di resize in basso (se non è ghost e non è la versione follower)
              if (!forFeedback && !isResizingDisabled) _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Se è 23:59 / 23:59:59 → mostra "24:00"
    if (time.hour == 23 && time.minute >= 59) return '24:00';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  // ==========================
  // NUOVA LOGICA RESIZE HANDLE
  // ==========================
  //
  // Qui entra in gioco il nuovo resizing_provider:
  // - startResize() viene chiamato a inizio drag,
  //   e PULISCE qualsiasi sessione precedente.
  // - updateDuringResize() ricalcola altezza preview + fine provvisoria.
  //   (usa delta relativo all'altezza iniziale salvata in startResize,
  //   quindi niente accumulo sporco tra tentativi).
  // - commitResizeAndEnd() restituisce l'endTime finale da salvare
  //   nell'appointmentsProvider e poi FA CLEANUP TOTALE.
  // - cancelResize() pulisce se abortisci.
  //
  // Questo è il fix del bug in release (range di resize che si riduce sempre).
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

            // 🔹 Posizione globale attuale del puntatore
            final currentGlobal = details.globalPosition;

            // 🔹 Calcola spostamento verticale rispetto al frame precedente
            final deltaY = currentGlobal.dy - _lastPointerGlobalPosition!.dy;

            // 🔹 Aggiorna la posizione di riferimento per il prossimo frame
            _lastPointerGlobalPosition = currentGlobal;

            final minutesPerPixel =
                LayoutConfig.minutesPerSlot / LayoutConfig.slotHeight;
            final pixelsPerMinute = 1 / minutesPerPixel;

            final dayEnd = DateTime(
              widget.appointment.startTime.year,
              widget.appointment.startTime.month,
              widget.appointment.startTime.day,
              23,
              59,
            );

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
            // 🔹 chiude la sessione di resize e ottiene il nuovo endTime
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

            // 🔹 attende un frame per permettere il rebuild del layout
            await Future.delayed(const Duration(milliseconds: 100));

            // 🔹 forza la ricostruzione del layout aggiornato
            if (mounted) {
              setState(() {
                _isDraggingResize = false;
              });
            }

            // 🔹 ri-inizializza la posizione iniziale per il prossimo resize
            _lastPointerGlobalPosition = null;
            ref.read(isResizingProvider.notifier).stop();
            ref.invalidate(resizingProvider);
          },

          onVerticalDragCancel: () {
            ref
                .read(resizingProvider.notifier)
                .cancelResize(appointmentId: widget.appointment.id);
            ref.read(isResizingProvider.notifier).stop();
            setState(() => _isDraggingResize = false);
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

    // posizione Y proposta del follower
    double top = dragPos.dy - offY;
    if (top < 0) top = 0;

    // Limita il follower a non uscire sotto dalla zona scrollabile
    final bodyBox = ref.read(dragBodyBoxProvider);
    final totalHeight = bodyBox?.size.height ?? LayoutConfig.totalHeight;
    final cardHeight = h;

    if (top + cardHeight > totalHeight) {
      top = totalHeight - cardHeight;
    }
    if (top < 0) top = 0;

    // posizione X proposta del follower
    double left;
    final rect = highlightedId != null ? columnsRects[highlightedId] : null;

    if (rect != null) {
      // Se stai evidenziando una staff column specifica,
      // centra la card su quella colonna
      left = rect.left + (rect.width - w) / 2;
      if (left < hourW) left = hourW;
    } else {
      // altrimenti segui il puntatore
      left = dragPos.dx - offX;
      if (widget.expandToLeft) {
        left -= (w / 2);
      }
      if (left < hourW) left = hourW;
    }

    // pixel perfect con DPR
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
