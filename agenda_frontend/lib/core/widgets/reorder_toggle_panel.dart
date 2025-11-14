import 'package:flutter/material.dart';

/// Container che dispone una serie di widget con spacing orizzontale su desktop/
/// tablet e verticale su mobile.
class ReorderTogglePanel extends StatelessWidget {
  final bool isWide;
  final List<Widget> children;

  const ReorderTogglePanel({
    super.key,
    required this.isWide,
    required this.children,
  });

  List<Widget> _withSpacing() {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(isWide
            ? const SizedBox(width: 8)
            : const SizedBox(height: 8));
      }
    }
    return spaced;
  }

  @override
  Widget build(BuildContext context) {
    final spacedChildren = _withSpacing();
    if (isWide) {
      return Row(children: spacedChildren);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spacedChildren,
    );
  }
}
