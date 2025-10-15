import 'package:flutter/material.dart';

/// Divider verticale sottile tra la colonna oraria e le colonne staff
class AgendaVerticalDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double thickness;

  const AgendaVerticalDivider({
    super.key,
    required this.height,
    this.color = const Color(0xFFBDBDBD),
    this.thickness = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: thickness,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color.withValues(alpha: 0.4)),
      ),
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
