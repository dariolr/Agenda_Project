import 'package:flutter/material.dart';

/// Divider standard per bottom sheet (stile coerente con creazione appuntamento).
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.5, color: Color(0x1F000000));
  }
}
