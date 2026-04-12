import 'package:flutter/material.dart';

import '../../app/theme/extensions.dart';

/// Wrapper riusabile per sfondo righe alternate (zebra).
///
/// Con [startFromSecond] = true colora dall'indice 1 (secondo elemento).
class AppAlternatingRow extends StatelessWidget {
  const AppAlternatingRow({
    super.key,
    required this.index,
    required this.child,
    this.startFromSecond = false,
    this.backgroundColor,
  });

  final int index;
  final Widget child;
  final bool startFromSecond;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final defaultFill =
        Theme.of(context).extension<AppInteractionColors>()?.alternatingRowFill ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.04);
    final fill = backgroundColor ?? defaultFill;
    final shouldFill = startFromSecond ? index.isOdd : index.isEven;

    return ColoredBox(
      color: shouldFill ? fill : Colors.transparent,
      child: child,
    );
  }
}
