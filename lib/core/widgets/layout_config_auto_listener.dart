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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // 2. Aggiorna il provider originale (per l'agenda)
    ref.read(layoutConfigProvider.notifier).updateFromContext(context);

    // 3. Aggiorna il NUOVO provider globale (per la Shell)
    final screenWidth = MediaQuery.of(context).size.width;
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
