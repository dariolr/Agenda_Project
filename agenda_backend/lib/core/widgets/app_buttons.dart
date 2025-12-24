import 'package:flutter/material.dart';

/// Centralizes button styling so we can reuse consistent widgets across the app.
class AppButtonStyles {
  static const BorderRadiusGeometry defaultBorderRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const EdgeInsetsGeometry defaultPadding = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 16,
  );

  /// Larghezza standard per i pulsanti nei dialog (es. Annulla, Salva).
  static const double dialogButtonWidth = 120.0;

  /// Padding standard per i pulsanti nei dialog.
  static const EdgeInsetsGeometry dialogButtonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  static ButtonStyle filled(
    BuildContext context, {
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      padding: padding ?? defaultPadding,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? defaultBorderRadius,
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle outlined(
    BuildContext context, {
    Color? borderColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBorderColor = borderColor ?? colorScheme.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? resolvedBorderColor,
      side: BorderSide(color: resolvedBorderColor, width: 1.4),
      padding: padding ?? defaultPadding,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? defaultBorderRadius,
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

class AppFilledButton extends StatelessWidget {
  const AppFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: AppButtonStyles.filled(
        context,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.expand = false,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool expand;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppFilledButton(
      onPressed: onPressed,
      expand: expand,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor ?? colorScheme.error,
      foregroundColor: colorScheme.onError,
      child: child,
    );
  }
}

class AppOutlinedActionButton extends StatelessWidget {
  const AppOutlinedActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: AppButtonStyles.outlined(
        context,
        borderColor: borderColor,
        foregroundColor: foregroundColor,
        padding: padding,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
