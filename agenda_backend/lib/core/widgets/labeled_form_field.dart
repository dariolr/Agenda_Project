import 'package:flutter/material.dart';

/// Widget che mostra una label sopra un campo form.
/// Usato per uniformare il layout dei form in tutta l'app.
class LabeledFormField extends StatelessWidget {
  const LabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.labelSpacing = 6.0,
  });

  /// Label del campo.
  final String label;

  /// Widget figlio (es. TextFormField, DropdownButtonFormField, ecc.).
  final Widget child;

  /// Spacing tra label e campo. Default 6.0.
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: labelSpacing),
        child,
      ],
    );
  }
}
