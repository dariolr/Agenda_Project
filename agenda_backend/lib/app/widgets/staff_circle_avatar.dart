// avatar_pin_glossy_letters.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/utils/initials_utils.dart';

String initialsFromName(String name, {int maxChars = 3}) {
  return InitialsUtils.fromName(name, maxChars: maxChars);
}

class StaffCircleAvatar extends StatelessWidget {
  final double height;
  final Color color;
  final bool isHighlighted;
  final String initials;
  final Widget? child;

  const StaffCircleAvatar({
    super.key,
    required this.height,
    required this.color,
    required this.isHighlighted,
    required this.initials,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasThreeLetterInitials = InitialsUtils.length(initials) == 3;
    final initialsFontSize = height * (hasThreeLetterInitials ? 0.30 : 0.35);
    return Container(
      width: height,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isHighlighted ? color : color.withOpacity(0.35),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.18),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(height * 0.06),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child:
                child ??
                Text(
                  initials,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: initialsFontSize,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

/// Avatar "stile 3": cerchio glossy con anello + puntina sotto + spark opzionale.
/// Input: letters, hexColor, size.
///
/// USO:
///   AvatarPinGlossyLetters(size: 160, letters: "VI", hexColor: "#D32F2F");
///
/// hexColor supporta: "#RRGGBB", "RRGGBB", "#AARRGGBB", "AARRGGBB"
class AvatarPinGlossyLetters extends StatelessWidget {
  final double size;
  final String letters;
  final Color avatarColor;

  /// Stellina in alto a destra
  final bool sparkle;

  /// Se true, anello esterno arancio/rosso come nel mock. Se false, tono-su-tono.
  final bool warmOuterGlow;

  const AvatarPinGlossyLetters({
    super.key,
    required this.size,
    required this.letters,
    required this.avatarColor,
    this.sparkle = true,
    this.warmOuterGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final base = avatarColor;

    final glowA = warmOuterGlow
        ? const Color(0xFFFF7043)
        : _mix(base, Colors.white, 0.20);
    final glowB = warmOuterGlow
        ? const Color(0xFFFF9800)
        : _mix(base, Colors.white, 0.35);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PinGlossyAvatarPainter(
          letters: letters,
          fillColor: base,
          ringColor: Colors.white,
          ringOuterGlowA: glowA,
          ringOuterGlowB: glowB,
          textColor: Colors.white,
          sparkle: sparkle,
        ),
      ),
    );
  }
}

class _PinGlossyAvatarPainter extends CustomPainter {
  final String letters;

  final Color fillColor;
  final Color ringColor;
  final Color ringOuterGlowA;
  final Color ringOuterGlowB;
  final Color textColor;

  final bool sparkle;

  _PinGlossyAvatarPainter({
    required this.letters,
    required this.fillColor,
    required this.ringColor,
    required this.ringOuterGlowA,
    required this.ringOuterGlowB,
    required this.textColor,
    required this.sparkle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final c = Offset(size.width / 2, size.height / 2);

    // Pin geometry (tarati per somigliare al mock)
    final circleR = s * 0.37;
    final pinTop = c.translate(0, -s * 0.05);
    final pinBottom = c.translate(0, s * 0.37);

    // Shadow sotto
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, s * 0.43),
        width: s * 0.55,
        height: s * 0.10,
      ),
      shadowPaint,
    );

    // Outer glow ring (stroke con gradiente)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(s, s), [
        ringOuterGlowA,
        ringOuterGlowB,
      ]);
    canvas.drawCircle(pinTop, circleR * 1.02, glowPaint);

    // Main circle glossy (radial)
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        pinTop.translate(-circleR * 0.35, -circleR * 0.35),
        circleR * 1.6,
        [
          _mix(fillColor, Colors.white, 0.18),
          fillColor,
          _mix(fillColor, Colors.black, 0.12),
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(pinTop, circleR * 0.92, fillPaint);

    // Inner white ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..color = ringColor.withOpacity(0.95);
    canvas.drawCircle(pinTop, circleR * 0.96, ringPaint);

    // Pin tip (goccia)
    final tipPath = Path();
    final tipW = s * 0.13;
    final tipH = s * 0.10;

    tipPath.moveTo(pinBottom.dx, pinBottom.dy + tipH * 0.35);
    tipPath.quadraticBezierTo(
      pinBottom.dx - tipW * 0.65,
      pinBottom.dy - tipH * 0.25,
      pinBottom.dx,
      pinBottom.dy - tipH * 0.75,
    );
    tipPath.quadraticBezierTo(
      pinBottom.dx + tipW * 0.65,
      pinBottom.dy - tipH * 0.25,
      pinBottom.dx,
      pinBottom.dy + tipH * 0.35,
    );
    tipPath.close();

    final tipPaint = Paint()
      ..shader = ui.Gradient.linear(
        pinBottom.translate(-tipW, -tipH),
        pinBottom.translate(tipW, tipH),
        [_mix(fillColor, Colors.white, 0.10), fillColor],
      );
    canvas.drawPath(tipPath, tipPaint);

    // Letters
    final tp = TextPainter(
      text: TextSpan(
        text: letters,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: s * 0.32,
          height: 1.0,
          letterSpacing: -1.0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: s);

    tp.paint(
      canvas,
      Offset(pinTop.dx - tp.width / 2, pinTop.dy - tp.height / 2),
    );

    // Sparkle (stellina)
    if (sparkle) {
      final sp = pinTop.translate(circleR * 0.62, -circleR * 0.55);
      _drawSparkle(canvas, sp, s * 0.07);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double r) {
    final p = Paint()..color = Colors.white.withOpacity(0.92);

    // 4-point star
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.22, center.dy - r * 0.22)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx + r * 0.22, center.dy + r * 0.22)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.22, center.dy + r * 0.22)
      ..lineTo(center.dx - r, center.dy)
      ..lineTo(center.dx - r * 0.22, center.dy - r * 0.22)
      ..close();

    // glow leggero
    canvas.saveLayer(Rect.fromCircle(center: center, radius: r * 1.6), Paint());
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
    );
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PinGlossyAvatarPainter oldDelegate) {
    return letters != oldDelegate.letters ||
        fillColor != oldDelegate.fillColor ||
        ringColor != oldDelegate.ringColor ||
        ringOuterGlowA != oldDelegate.ringOuterGlowA ||
        ringOuterGlowB != oldDelegate.ringOuterGlowB ||
        textColor != oldDelegate.textColor ||
        sparkle != oldDelegate.sparkle;
  }
}

/* =========================
   HELPERS
   ========================= */

Color parseHexColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);

  if (hex.length == 6) {
    // RRGGBB
    final v = int.parse(hex, radix: 16);
    return Color(0xFF000000 | v);
  }
  if (hex.length == 8) {
    // AARRGGBB
    final v = int.parse(hex, radix: 16);
    return Color(v);
  }
  throw FormatException(
    'hexColor non valido: $input (usa RRGGBB o AARRGGBB, con o senza #)',
  );
}

Color _mix(Color a, Color b, double t) {
  // t=0 -> a, t=1 -> b
  final clamped = t.clamp(0.0, 1.0);
  return Color.fromARGB(
    (a.alpha + (b.alpha - a.alpha) * clamped).round(),
    (a.red + (b.red - a.red) * clamped).round(),
    (a.green + (b.green - a.green) * clamped).round(),
    (a.blue + (b.blue - a.blue) * clamped).round(),
  );
}
