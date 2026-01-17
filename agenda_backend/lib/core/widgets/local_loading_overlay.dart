import 'package:flutter/material.dart';

class LocalLoadingOverlay extends StatelessWidget {
  const LocalLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.barrierColor,
  });

  final bool isLoading;
  final Widget child;
  final Color? barrierColor;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AbsorbPointer(
            child: Container(
              color: barrierColor ?? const Color(0x33000000),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}
