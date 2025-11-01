import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Importa il nuovo provider globale
import '../../app/providers/form_factor_provider.dart';
import '../../features/agenda/providers/layout_config_provider.dart';

class LayoutConfigAutoListener extends ConsumerStatefulWidget {
  final Widget child;

  const LayoutConfigAutoListener({super.key, required this.child});

  @override
  ConsumerState<LayoutConfigAutoListener> createState() =>
      _LayoutConfigAutoListenerState();
}

class _LayoutConfigAutoListenerState
    extends ConsumerState<LayoutConfigAutoListener>
    with WidgetsBindingObserver {
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔹 FIX SAFARI DESKTOP: attendi un frame + piccolo delay
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      _updateLayoutConfig();
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newSize = MediaQuery.of(context).size;
      if (_lastSize == null || newSize != _lastSize) {
        _lastSize = newSize;
        _updateLayoutConfig();
      }
    });
  }

  void _updateLayoutConfig() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // 🧩 FIX: evita aggiornamenti con MediaQuery ancora non pronta
    if (screenWidth < 100 || screenHeight < 100) {
      return;
    }

    // 🔹 Aggiorna layout per l’agenda
    ref.read(layoutConfigProvider.notifier).updateFromContext(context);

    // 🔹 Aggiorna form factor globale (usato dalla shell)
    ref.read(formFactorProvider.notifier).update(screenWidth);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
