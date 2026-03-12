import 'package:flutter/material.dart';

/// Divider standard per bottom sheet (stile coerente con creazione appuntamento).
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height = 1,
    this.thickness = 0.5,
    this.color = const Color(0x1F000000),
    this.indent,
    this.endIndent,
  });

  final double height;
  final double thickness;
  final Color color;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      color: color,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
