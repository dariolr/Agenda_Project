import 'package:flutter/material.dart';

import '../../../domain/config/layout_config.dart';

/// Painter leggero che disegna linee diagonali.
/// Usa `isComplex: true` e `willChange: false` per caching automatico.
class _DiagonalPatternPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final double spacing;

  const _DiagonalPatternPainter({
    required this.lineColor,
    required this.lineWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Disegna linee diagonali da sinistra-alto a destra-basso
    final double step = spacing;
    final double maxOffset = size.width + size.height;

    for (double offset = -size.height; offset < maxOffset; offset += step) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.spacing != spacing;
  }
}

/// Widget leggero che mostra un pattern a righe diagonali per indicare
/// uno slot non disponibile nell'agenda.
///
/// Ottimizzato per performance:
/// - Nessun state, nessun async
/// - CustomPaint con caching automatico (isComplex + willChange)
/// - RepaintBoundary per isolare i repaint
class UnavailableSlotPattern extends StatelessWidget {
  final double height;
  final Color? patternColor;
  final Color? backgroundColor;
  final double lineWidth;
  final double spacing;
  final BorderRadius? borderRadius;

  const UnavailableSlotPattern({
    super.key,
    required this.height,
    this.patternColor,
    this.backgroundColor,
    this.lineWidth = 1.5,
    this.spacing = 6.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectivePatternColor =
        patternColor ?? colorScheme.onSurface.withOpacity(0.25);
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.surfaceContainerHighest.withOpacity(0.6);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _DiagonalPatternPainter(
                lineColor: effectivePatternColor,
                lineWidth: lineWidth,
                spacing: spacing,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
        ),
      ),
    );
  }
}

/// Variante con margini coerenti con le AppointmentCard.
class UnavailableSlotOverlay extends StatelessWidget {
  final double height;
  final double margin;
  final Color? patternColor;
  final Color? backgroundColor;

  const UnavailableSlotOverlay({
    super.key,
    required this.height,
    this.margin = LayoutConfig.columnInnerPadding,
    this.patternColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(margin),
      child: UnavailableSlotPattern(
        height: height - (margin * 2),
        patternColor: patternColor,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

/// Widget ottimizzato per coprire un range di slot consecutivi.
class UnavailableSlotRange extends StatelessWidget {
  final int slotCount;
  final double slotHeight;
  final double margin;
  final Color? patternColor;
  final Color? backgroundColor;

  const UnavailableSlotRange({
    super.key,
    required this.slotCount,
    required this.slotHeight,
    this.margin = LayoutConfig.columnInnerPadding,
    this.patternColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final totalHeight = slotCount * slotHeight;
    return Padding(
      padding: EdgeInsets.all(margin),
      child: UnavailableSlotPattern(
        height: totalHeight - (margin * 2),
        patternColor: patternColor,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
