import 'package:flutter/material.dart';

/// Divider verticale sottile tra la colonna oraria e le colonne staff
class AgendaVerticalDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double thickness;

  /// Altezza della porzione superiore con sfumatura (es. headerHeight)
  final double? fadeTopHeight;

  const AgendaVerticalDivider({
    super.key,
    required this.height,
    this.color = const Color(0xFFBDBDBD),
    this.thickness = 0.5,
    this.fadeTopHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Se fadeTopHeight è specificato, usa una Column con gradiente in alto
    if (fadeTopHeight != null && fadeTopHeight! > 0) {
      return SizedBox(
        height: height,
        width: thickness,
        child: Column(
          children: [
            // Parte superiore con gradiente sfumato
            Container(
              height: fadeTopHeight,
              width: thickness,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.0), color],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
            // Parte inferiore con colore pieno
            Expanded(
              child: Container(width: thickness, color: color),
            ),
          ],
        ),
      );
    }

    // Comportamento originale senza sfumatura
    return SizedBox(
      height: height,
      width: thickness,
      child: DecoratedBox(decoration: BoxDecoration(color: color)),
    );
  }
}

/// Divider orizzontale usato per le righe orarie
class AgendaHorizontalDivider extends StatelessWidget {
  final double thickness;
  final Color color;

  const AgendaHorizontalDivider({
    super.key,
    this.thickness = 0.5,
    this.color = const Color(0xFFBDBDBD),
  });

  @override
  Widget build(BuildContext context) {
    return Divider(height: thickness, thickness: thickness, color: color);
  }
}
