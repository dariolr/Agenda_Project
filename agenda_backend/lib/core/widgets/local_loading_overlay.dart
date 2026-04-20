import 'package:flutter/material.dart';

/// InheritedWidget che porta un [ValueNotifier<bool>] ai discendenti,
/// permettendo di segnalare lo stato di loading al livello del bottom sheet
/// (fuori dal padding del container) invece di mostrare un overlay locale.
class BottomSheetLoadingContext extends InheritedWidget {
  const BottomSheetLoadingContext({
    super.key,
    required this.notifier,
    required super.child,
  });

  final ValueNotifier<bool> notifier;

  // Non notifica i discendenti: è solo un carrier per il notifier.
  @override
  bool updateShouldNotify(BottomSheetLoadingContext old) => false;
}

class LocalLoadingOverlay extends StatefulWidget {
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
  State<LocalLoadingOverlay> createState() => _LocalLoadingOverlayState();
}

class _LocalLoadingOverlayState extends State<LocalLoadingOverlay> {
  void _scheduleSyncToScope() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncToScope();
    });
  }

  void _syncToScope() {
    final notifier = context
        .getInheritedWidgetOfExactType<BottomSheetLoadingContext>()
        ?.notifier;
    if (notifier == null) {
      return;
    }
    if (notifier.value == widget.isLoading) {
      return;
    }
    notifier.value = widget.isLoading;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Usa postFrameCallback per evitare notifiche durante la fase di build.
    _scheduleSyncToScope();
  }

  @override
  void didUpdateWidget(LocalLoadingOverlay old) {
    super.didUpdateWidget(old);
    if (widget.isLoading != old.isLoading) {
      // Evita notifyListeners durante la build corrente.
      _scheduleSyncToScope();
    }
  }

  @override
  Widget build(BuildContext context) {
    // In contesto bottom sheet: l'overlay visivo è gestito a livello sheet.
    if (context.getInheritedWidgetOfExactType<BottomSheetLoadingContext>() !=
        null) {
      return widget.child;
    }

    if (!widget.isLoading) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AbsorbPointer(
            child: Container(
              color: widget.barrierColor ?? const Color(0x33000000),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}
