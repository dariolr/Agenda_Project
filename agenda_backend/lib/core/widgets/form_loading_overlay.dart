import 'package:flutter/material.dart';

class FormLoadingOverlay extends StatelessWidget {
  const FormLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Stack(
      children: [
        AbsorbPointer(child: child),
        Positioned.fill(
          child: Container(
            color: const Color(0x33000000),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
