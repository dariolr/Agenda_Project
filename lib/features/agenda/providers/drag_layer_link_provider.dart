// lib/features/agenda/providers/drag_layer_link_provider.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// LayerLink condiviso per ancorare il feedback del drag al body (sotto l'header)
final dragLayerLinkProvider = Provider<LayerLink>((ref) {
  return LayerLink();
});
