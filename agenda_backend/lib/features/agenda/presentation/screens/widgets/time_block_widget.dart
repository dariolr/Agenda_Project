import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/date_time_formats.dart';
import '../../../../../core/l10n/l10_extension.dart';
import '../../../../../core/models/time_block.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/agenda_display_settings_provider.dart';
import '../../../providers/block_resizing_provider.dart';
import '../../../providers/is_resizing_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/time_blocks_provider.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import '../../dialogs/add_block_dialog.dart';
import '../../widgets/booking_dialog.dart';

/// Widget per visualizzare un blocco di non disponibilità nell'agenda.
class TimeBlockWidget extends ConsumerStatefulWidget {
  final TimeBlock block;
  final double height;
  final double width;
  final String resizeSessionKey;
  final int staffId;
  final Future<void> Function(DateTime startTime)? onSecondaryCreate;

  const TimeBlockWidget({
    super.key,
    required this.block,
    required this.height,
    required this.width,
    required this.resizeSessionKey,
    required this.staffId,
    this.onSecondaryCreate,
  });

  @override
  ConsumerState<TimeBlockWidget> createState() => _TimeBlockWidgetState();
}

class _TimeBlockWidgetState extends ConsumerState<TimeBlockWidget> {
  static const double _bottomResizeHandleHitHeightDesktop = 20.0;
  static const double _bottomResizeHandleHitHeightTouch = 14.0;

  bool _isResizing = false;
  bool _suppressTapAfterResize = false;
  Offset? _lastPointerGlobalPosition;

  bool _isPointerInResizeHotzone(RenderBox cardBox, Offset globalPosition) {
    final localPos = cardBox.globalToLocal(globalPosition);
    final width = cardBox.size.width;
    final height = cardBox.size.height;
    final configuredHitHeight =
        ref.read(formFactorProvider) == AppFormFactor.desktop
        ? _bottomResizeHandleHitHeightDesktop
        : _bottomResizeHandleHitHeightTouch;
    final bottomResizeHandleHitHeight = (height * 0.35).clamp(
      8.0,
      configuredHitHeight,
    );
    if (localPos.dx < 0 ||
        localPos.dy < 0 ||
        localPos.dx > width ||
        localPos.dy > height) {
      return false;
    }
    return localPos.dy >= (height - bottomResizeHandleHitHeight);
  }

  void _startResize() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final currentHeightPx = renderBox?.size.height ?? 0;
    final formFactor = ref.read(formFactorProvider);
    if (formFactor != AppFormFactor.desktop) {
      HapticFeedback.selectionClick();
    }
    ref
        .read(blockResizingProvider.notifier)
        .startResize(
          resizeSessionKey: widget.resizeSessionKey,
          currentHeightPx: currentHeightPx,
          startTime: widget.block.startTime,
          endTime: widget.block.endTime,
        );
    ref.read(isResizingProvider.notifier).start();
    if (mounted) setState(() => _isResizing = true);
  }

  void _performResizeUpdate(PointerEvent details) {
    if (_lastPointerGlobalPosition == null) return;
    final currentGlobal = details.position;
    final deltaY = currentGlobal.dy - _lastPointerGlobalPosition!.dy;
    _lastPointerGlobalPosition = currentGlobal;

    final dayEnd = DateTime(
      widget.block.startTime.year,
      widget.block.startTime.month,
      widget.block.startTime.day,
    ).add(const Duration(days: 1));

    ref
        .read(blockResizingProvider.notifier)
        .updateDuringResize(
          resizeSessionKey: widget.resizeSessionKey,
          deltaDy: deltaY,
          pixelsPerMinute: ref.read(layoutConfigProvider).pixelsPerMinute,
          dayEnd: dayEnd,
          minDurationMinutes: 5,
          snapMinutes: 5,
        );
  }

  Future<void> _performResizeEnd() async {
    final newEnd = ref
        .read(blockResizingProvider.notifier)
        .previewEndTimeFor(widget.resizeSessionKey);
    final minEnd = widget.block.startTime.add(const Duration(minutes: 5));
    final effectiveEnd = newEnd != null && newEnd.isAfter(minEnd)
        ? newEnd
        : minEnd;

    try {
      if (newEnd != null) {
        final notifier = ref.read(timeBlocksProvider.notifier);
        final isSharedAcrossStaff = widget.block.staffIds.length > 1;

        if (!isSharedAcrossStaff) {
          await notifier.updateBlock(
            blockId: widget.block.id,
            endTime: effectiveEnd,
          );
        } else {
          await notifier.splitBlockForSingleStaffResize(
            originalBlock: widget.block,
            staffId: widget.staffId,
            newEndTime: effectiveEnd,
          );
        }
      }
    } finally {
      // Rimuovi la preview solo dopo il commit, per evitare il flash
      // alla dimensione originale tra mouse-up e risposta API.
      ref
          .read(blockResizingProvider.notifier)
          .cancelResize(resizeSessionKey: widget.resizeSessionKey);
      if (mounted) {
        setState(() {
          _isResizing = false;
          _suppressTapAfterResize = true;
        });
      }
      _lastPointerGlobalPosition = null;
      ref.read(isResizingProvider.notifier).stop();
      final blockDate = DateUtils.dateOnly(widget.block.startTime);
      for (final staffId in widget.block.staffIds) {
        ref.invalidate(
          timeBlocksForStaffOnDateProvider((staffId: staffId, date: blockDate)),
        );
      }
    }
  }

  void _performResizeCancel() {
    ref
        .read(blockResizingProvider.notifier)
        .cancelResize(resizeSessionKey: widget.resizeSessionKey);
    ref.read(isResizingProvider.notifier).stop();
    if (mounted) {
      setState(() {
        _isResizing = false;
        _suppressTapAfterResize = true;
      });
    }
    _lastPointerGlobalPosition = null;
  }

  DateTime _resolveSecondaryTapStartTime({
    required TapDownDetails details,
    required DateTime blockStart,
    required DateTime blockEnd,
  }) {
    final durationMinutes = blockEnd.difference(blockStart).inMinutes;
    if (durationMinutes <= 0) return blockStart;

    final renderBox = context.findRenderObject() as RenderBox?;
    final cardHeightPx = (renderBox?.size.height ?? widget.height)
        .clamp(1.0, double.infinity)
        .toDouble();
    final localDy = details.localPosition.dy.clamp(0.0, cardHeightPx);
    final tapRatio = localDy / cardHeightPx;
    final rawOffsetMinutes = durationMinutes * tapRatio;
    final slotMinutes = ref.read(layoutConfigProvider).minutesPerSlot;
    final snappedOffsetMinutes =
        ((rawOffsetMinutes / slotMinutes).round() * slotMinutes).toInt();
    final candidate = blockStart.add(Duration(minutes: snappedOffsetMinutes));
    if (candidate.isAfter(blockEnd)) return blockEnd;
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final useRoundedCardCorners = ref.watch(
      agendaUseRoundedCardCornersProvider,
    );
    final blockBorderRadius = useRoundedCardCorners
        ? BorderRadius.circular(LayoutConfig.cardBorderRadiusNormal)
        : BorderRadius.zero;
    final blockInnerBorderRadius = useRoundedCardCorners
        ? BorderRadius.circular(LayoutConfig.cardBorderRadiusNormal - 1)
        : BorderRadius.zero;
    final effectiveEnd =
        ref.watch(blockResizingEndTimeProvider(widget.resizeSessionKey)) ??
        widget.block.endTime;
    final effectiveBlock = widget.block.copyWith(endTime: effectiveEnd);
    final accentColor = widget.block.allowOnlineBookingDuringBlock
        ? const Color(0xFF2E7D32)
        : colorScheme.error;
    final blockColor = accentColor.withOpacity(0.15);
    final borderColor = accentColor.withOpacity(0.5);
    final canManageBookings = ref.watch(currentUserCanManageBookingsProvider);
    final canResize = !widget.block.isAllDay && canManageBookings;

    return Listener(
      onPointerDown: (event) {
        _lastPointerGlobalPosition = event.position;
        if (!canResize) return;
        final cardBox = context.findRenderObject() as RenderBox?;
        if (cardBox == null) return;
        if (!_isPointerInResizeHotzone(cardBox, event.position)) return;
        _startResize();
      },
      onPointerMove: (event) {
        if (_isResizing) {
          _performResizeUpdate(event);
        }
      },
      onPointerUp: (_) async {
        if (_isResizing) {
          await _performResizeEnd();
        }
        _lastPointerGlobalPosition = null;
      },
      onPointerCancel: (_) {
        if (_isResizing) {
          _performResizeCancel();
        }
        _lastPointerGlobalPosition = null;
      },
      child: MouseRegion(
        cursor: canResize ? SystemMouseCursors.resizeUpDown : MouseCursor.defer,
        child: GestureDetector(
          onSecondaryTapDown: canManageBookings
              ? (details) {
                  final secondaryTapTime = _resolveSecondaryTapStartTime(
                    details: details,
                    blockStart: widget.block.startTime,
                    blockEnd: effectiveBlock.endTime,
                  );
                  final onSecondaryCreate = widget.onSecondaryCreate;
                  if (onSecondaryCreate != null) {
                    onSecondaryCreate(secondaryTapTime);
                    return;
                  }
                  showBookingDialog(
                    context,
                    ref,
                    date: DateUtils.dateOnly(secondaryTapTime),
                    time: TimeOfDay(
                      hour: secondaryTapTime.hour,
                      minute: secondaryTapTime.minute,
                    ),
                    initialStaffId: widget.staffId,
                  );
                }
              : null,
          onTap: canManageBookings
              ? () {
                  if (_suppressTapAfterResize) {
                    _suppressTapAfterResize = false;
                    return;
                  }
                  showAddBlockDialog(context, ref, initial: widget.block);
                }
              : null,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: blockBorderRadius,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: blockInnerBorderRadius,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _DiagonalPatternPainter(
                      color: accentColor.withOpacity(0.1),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final maxWidth = constraints.maxWidth;
                      if (maxHeight < 18) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 22,
                              height: 2,
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }
                      if (maxWidth < 24) {
                        final indicatorWidth = (maxWidth - 6).clamp(8.0, 22.0);
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              width: indicatorWidth,
                              height: 2,
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }

                      final isCompact = maxHeight < 30 || maxWidth < 90;
                      final horizontalPadding = isCompact ? 6.0 : 8.0;
                      final verticalPadding = isCompact ? 2.0 : 4.0;
                      final showLeadingIcon = !isCompact && maxWidth >= 84;
                      final showRecurringIcon =
                          !isCompact &&
                          effectiveBlock.isRecurring &&
                          maxWidth >= 110;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (showLeadingIcon) ...[
                                  Icon(
                                    effectiveBlock.allowOnlineBookingDuringBlock
                                        ? Icons.event_note
                                        : Icons.block,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    effectiveBlock.reason ??
                                        (effectiveBlock
                                                .allowOnlineBookingDuringBlock
                                            ? context.l10n.blockPromemoriaLabel
                                            : 'Blocco'),
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showRecurringIcon)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Tooltip(
                                      message:
                                          context.l10n.blockRecurringIndicator,
                                      child: Icon(
                                        Icons.repeat,
                                        size: 12,
                                        color: accentColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (maxHeight > 40) ...[
                              const SizedBox(height: 2),
                              Text(
                                _formatTimeRange(context, effectiveBlock),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accentColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  if (canResize)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Container(
                          width: 22,
                          height: 4,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
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

  String _formatTimeRange(BuildContext context, TimeBlock block) {
    if (block.isAllDay) {
      return context.l10n.blockAllDay;
    }
    final start = DtFmt.hm(
      context,
      block.startTime.hour,
      block.startTime.minute,
    );
    final end = DtFmt.hm(context, block.endTime.hour, block.endTime.minute);
    return '$start - $end';
  }
}

class _DiagonalPatternPainter extends CustomPainter {
  final Color color;

  _DiagonalPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 8.0;
    final diagonal = size.width + size.height;

    for (double i = -size.height; i < diagonal; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
