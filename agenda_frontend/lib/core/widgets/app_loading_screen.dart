import 'package:flutter/material.dart';

import '../l10n/l10_extension.dart';

/// Loading screen identico a quello in index.html per transizione seamless.
/// Usato durante il caricamento iniziale dell'app.
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFEFEFE),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LoadingSpinner(),
            const SizedBox(height: 20),
            Text(
              context.l10n.loadingGeneric,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                letterSpacing: 0.5,
                fontFamily: null, // usa system font
                decoration: TextDecoration.none,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSpinner extends StatefulWidget {
  const _LoadingSpinner();

  @override
  State<_LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<_LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Builder(
        builder: (context) {
          final primary = Theme.of(context).colorScheme.primary;
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Binario: tinta del colore primario a bassa opacità,
              // sempre visibile indipendentemente dallo sfondo
              border: Border.all(
                color: primary.withAlpha(38), // ~15% opacità
                width: 4,
              ),
            ),
            child: CustomPaint(
              painter: _SpinnerPainter(color: primary),
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Arco di 90 gradi in alto
    canvas.drawArc(rect, -1.5708, 1.5708, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
