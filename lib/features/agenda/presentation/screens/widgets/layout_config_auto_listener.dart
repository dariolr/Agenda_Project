import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout_config_provider.dart';

/// Widget che osserva i cambiamenti di dimensione finestra o orientamento
/// e aggiorna automaticamente il layoutConfigProvider.
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

    // Aggiorno subito la configurazione iniziale
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
    ref.read(layoutConfigProvider.notifier).updateFromContext(context);
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
