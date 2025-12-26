import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Helper to show a modal bottom sheet with the app's default styling.
class AppBottomSheet {
  AppBottomSheet._();

  /// Altezza predefinita di tutti i bottom sheet (80% dello schermo).
  static const double defaultHeightFactor = 0.95;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    EdgeInsetsGeometry? padding,

    /// Fraction of screen height (0.0 to 1.0). If provided, the bottom sheet
    /// will have a minimum height of this fraction of the screen.
    double? heightFactor = defaultHeightFactor,
  }) {
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.white,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AppBottomSheetContainer(
        padding: effectivePadding,
        heightFactor: heightFactor,
        child: builder(ctx),
      ),
    );
  }
}

/// Provides consistent padding, animation and handle for bottom sheet content.
class AppBottomSheetContainer extends StatelessWidget {
  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.showHandle = true,
    this.heightFactor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  /// If provided, the container will have a minimum height of this fraction
  /// of the screen height (0.0 to 1.0).
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    Widget content;

    // Apply height constraint if heightFactor is provided
    // Use SizedBox (not ConstrainedBox) to provide a finite height
    // so that Expanded children inside Column can work properly
    if (heightFactor != null) {
      // Ensure bottom padding is at least 50.0 to leave space above
      // system UI / controls and provide consistent spacing across sheets.
      final resolved = padding.resolve(Directionality.of(context));
      final effectivePadding = resolved.copyWith(
        bottom: math.max(resolved.bottom, 50.0),
      );
      final screenHeight = MediaQuery.of(context).size.height;
      final height = screenHeight * heightFactor!;
      content = SizedBox(
        height: height,
        child: Padding(padding: effectivePadding, child: child),
      );
    } else {
      // Quando heightFactor è null, il contenuto si adatta all'altezza naturale
      // Usa solo il padding fornito senza forzare altezza minima
      content = Padding(padding: padding, child: child);
    }

    final body = showHandle
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Flexible permette al contenuto di adattarsi senza forzare
              // l'altezza massima della bottom sheet.
              Flexible(child: content),
            ],
          )
        : content;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: body,
    );
  }
}
