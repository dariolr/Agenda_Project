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

// ============================================================================
// ASYNC BUTTONS - Pulsanti con gestione automatica dello stato di loading
// ============================================================================

/// Pulsante filled con gestione automatica del loading state.
/// Quando [onPressed] è in esecuzione, mostra uno spinner e disabilita il pulsante.
class AppAsyncFilledButton extends StatefulWidget {
  const AppAsyncFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.expand = false,
    this.isLoading = false,
    this.disabled = false,
  });

  /// Callback async che verrà eseguito al tap.
  /// Il pulsante si disabilita automaticamente durante l'esecuzione.
  final Future<void> Function()? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool expand;

  /// Se true, forza lo stato di loading dall'esterno.
  final bool isLoading;

  /// Se true, disabilita il pulsante.
  final bool disabled;

  @override
  State<AppAsyncFilledButton> createState() => _AppAsyncFilledButtonState();
}

class _AppAsyncFilledButtonState extends State<AppAsyncFilledButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => _isLoading || widget.isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        _effectiveLoading || widget.disabled || widget.onPressed == null;

    return AppFilledButton(
      onPressed: isDisabled ? null : _handlePress,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      padding: widget.padding,
      borderRadius: widget.borderRadius,
      expand: widget.expand,
      child: _effectiveLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.foregroundColor ??
                      Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : widget.child,
    );
  }
}

/// Pulsante danger con gestione automatica del loading state.
class AppAsyncDangerButton extends StatefulWidget {
  const AppAsyncDangerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.expand = false,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.isLoading = false,
    this.disabled = false,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final bool expand;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final bool isLoading;
  final bool disabled;

  @override
  State<AppAsyncDangerButton> createState() => _AppAsyncDangerButtonState();
}

class _AppAsyncDangerButtonState extends State<AppAsyncDangerButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => _isLoading || widget.isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled =
        _effectiveLoading || widget.disabled || widget.onPressed == null;

    return AppFilledButton(
      onPressed: isDisabled ? null : _handlePress,
      expand: widget.expand,
      padding: widget.padding,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor ?? colorScheme.error,
      foregroundColor: colorScheme.onError,
      child: _effectiveLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onError),
              ),
            )
          : widget.child,
    );
  }
}

/// Pulsante outlined con gestione automatica del loading state.
class AppAsyncOutlinedButton extends StatefulWidget {
  const AppAsyncOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.expand = false,
    this.isLoading = false,
    this.disabled = false,
  });

  final Future<void> Function()? onPressed;
  final Widget child;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool expand;
  final bool isLoading;
  final bool disabled;

  @override
  State<AppAsyncOutlinedButton> createState() => _AppAsyncOutlinedButtonState();
}

class _AppAsyncOutlinedButtonState extends State<AppAsyncOutlinedButton> {
  bool _isLoading = false;

  bool get _effectiveLoading => _isLoading || widget.isLoading;

  Future<void> _handlePress() async {
    if (_effectiveLoading || widget.disabled || widget.onPressed == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled =
        _effectiveLoading || widget.disabled || widget.onPressed == null;
    final spinnerColor =
        widget.foregroundColor ?? widget.borderColor ?? colorScheme.primary;

    return AppOutlinedActionButton(
      onPressed: isDisabled ? null : _handlePress,
      borderColor: widget.borderColor,
      foregroundColor: widget.foregroundColor,
      padding: widget.padding,
      borderRadius: widget.borderRadius,
      expand: widget.expand,
      child: _effectiveLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            )
          : widget.child,
    );
  }
}
