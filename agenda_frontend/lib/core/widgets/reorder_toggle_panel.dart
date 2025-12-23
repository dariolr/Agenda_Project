import 'package:flutter/material.dart';

/// Container che dispone una serie di widget con spacing orizzontale e wrap
/// automatico per evitare overflow su schermi stretti.
class ReorderTogglePanel extends StatelessWidget {
  final bool isWide;
  final List<Widget> children;

  const ReorderTogglePanel({
    super.key,
    required this.isWide,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}
