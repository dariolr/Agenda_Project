import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/l10_extension.dart';
import '../../../../../core/models/time_block.dart';
import '../../../domain/config/layout_config.dart';
import '../../dialogs/add_block_dialog.dart';

/// Widget per visualizzare un blocco di non disponibilità nell'agenda.
class TimeBlockWidget extends ConsumerWidget {
  final TimeBlock block;
  final double height;
  final double width;

  const TimeBlockWidget({
    super.key,
    required this.block,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final blockColor = colorScheme.error.withOpacity(0.15);
    final borderColor = colorScheme.error.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        showAddBlockDialog(context, ref, initial: block);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: blockColor,
          borderRadius: BorderRadius.circular(LayoutConfig.borderRadius),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LayoutConfig.borderRadius - 1),
          child: Stack(
            children: [
              // Pattern diagonale
              CustomPaint(
                size: Size(width, height),
                painter: _DiagonalPatternPainter(
                  color: colorScheme.error.withOpacity(0.1),
                ),
              ),
              // Contenuto adattivo: evita overflow quando il blocco e' molto basso.
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
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

                  final isCompact = maxHeight < 30;
                  final horizontalPadding = isCompact ? 6.0 : 8.0;
                  final verticalPadding = isCompact ? 2.0 : 4.0;

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
                            if (!isCompact) ...[
                              Icon(Icons.block, size: 14, color: colorScheme.error),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                block.reason ?? 'Blocco',
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (maxHeight > 40) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeRange(context, block),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.error.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(BuildContext context, TimeBlock block) {
    if (block.isAllDay) {
      return context.l10n.blockAllDay;
    }
    final start =
        '${block.startTime.hour.toString().padLeft(2, '0')}:${block.startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${block.endTime.hour.toString().padLeft(2, '0')}:${block.endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

/// Painter per il pattern diagonale del blocco.
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
