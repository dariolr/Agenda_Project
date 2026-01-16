import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/global_loading_provider.dart';

class FormLoadingOverlay extends StatefulWidget {
  const FormLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  State<FormLoadingOverlay> createState() => _FormLoadingOverlayState();
}

class _FormLoadingOverlayState extends State<FormLoadingOverlay> {
  bool _wasLoading = false;
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _wasLoading = widget.isLoading;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureContainer();
    if (_wasLoading) {
      _setGlobalLoading(true);
    }
  }

  @override
  void didUpdateWidget(covariant FormLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading == widget.isLoading) return;

    _wasLoading = widget.isLoading;
    _setGlobalLoading(widget.isLoading);
  }

  @override
  void dispose() {
    if (_wasLoading) {
      _setGlobalLoading(false);
    }
    super.dispose();
  }

  void _ensureContainer() {
    if (_container != null) return;
    try {
      _container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      _container = null;
    }
  }

  void _setGlobalLoading(bool isLoading) {
    _ensureContainer();
    final container = _container;
    if (container == null) return;
    final notifier = container.read(globalLoadingProvider.notifier);
    if (isLoading) {
      notifier.show();
    } else {
      notifier.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
