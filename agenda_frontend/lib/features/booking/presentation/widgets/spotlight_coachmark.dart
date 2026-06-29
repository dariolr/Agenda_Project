import 'package:flutter/material.dart';

/// Mostra uno spotlight a tutto schermo che oscura l'interfaccia e illumina
/// (ritaglia) l'elemento individuato da [targetKey], con un fumetto che spiega
/// dove si trova. Usato come tutorial one-shot per indicare l'icona profilo
/// dove l'utente trova le sue prenotazioni.
void showSpotlightCoachmark(
  BuildContext context, {
  required GlobalKey targetKey,
  required String title,
  required String message,
  required String dismissLabel,
}) {
  final overlay = Overlay.of(context);
  final targetContext = targetKey.currentContext;
  if (targetContext == null) return;
  final renderBox = targetContext.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.attached) return;

  final topLeft = renderBox.localToGlobal(Offset.zero);
  final targetRect = topLeft & renderBox.size;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _SpotlightOverlay(
      targetRect: targetRect,
      title: title,
      message: message,
      dismissLabel: dismissLabel,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _SpotlightOverlay extends StatelessWidget {
  const _SpotlightOverlay({
    required this.targetRect,
    required this.title,
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final Rect targetRect;
  final String title;
  final String message;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaSize = MediaQuery.of(context).size;
    final holeRadius = targetRect.longestSide / 2 + 8;

    // Il fumetto va sotto l'elemento evidenziato.
    final calloutTop = targetRect.bottom + 22;
    final cardColor = theme.colorScheme.primary;
    final onCardColor = theme.colorScheme.onPrimary;

    // Freccia centrata orizzontalmente sull'elemento (clampata allo schermo).
    final arrowCenterX = targetRect.center.dx.clamp(28.0, mediaSize.width - 28);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Stack(
        children: [
          // Velo scuro con foro sull'elemento; tap ovunque chiude.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  radius: holeRadius,
                  veilColor: Colors.black.withOpacity(0.72),
                  ringColor: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
          // Freccia verso l'elemento.
          Positioned(
            top: targetRect.bottom + 2,
            left: arrowCenterX - 18,
            child: Icon(
              Icons.arrow_drop_up,
              size: 44,
              color: cardColor,
            ),
          ),
          // Fumetto esplicativo.
          Positioned(
            top: calloutTop,
            left: 16,
            right: 16,
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onCardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onCardColor.withOpacity(0.92),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: onCardColor,
                        ),
                        child: Text(dismissLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.targetRect,
    required this.radius,
    required this.veilColor,
    required this.ringColor,
  });

  final Rect targetRect;
  final double radius;
  final Color veilColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = targetRect.center;
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final veil = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(veil, Paint()..color = veilColor);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.targetRect != targetRect ||
      old.radius != radius ||
      old.veilColor != veilColor ||
      old.ringColor != ringColor;
}
