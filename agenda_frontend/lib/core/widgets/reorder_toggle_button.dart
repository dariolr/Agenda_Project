import 'package:flutter/material.dart';

/// Pulsante testuale con icona che riflette uno stato (attivo/inattivo).
class ReorderToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final String activeLabel;
  final String inactiveLabel;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const ReorderToggleButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isActive ? activeIcon : inactiveIcon;
    final label = isActive ? activeLabel : inactiveLabel;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
