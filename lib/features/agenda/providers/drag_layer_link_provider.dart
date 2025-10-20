import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔹 Gestisce il LayerLink del body (ancora per i feedback)
class DragLayerLinkNotifier extends Notifier<LayerLink> {
  @override
  LayerLink build() => LayerLink();

  void reset() => state = LayerLink();
}

final dragLayerLinkProvider =
    NotifierProvider<DragLayerLinkNotifier, LayerLink>(
      DragLayerLinkNotifier.new,
    );

/// 🔹 Gestisce il RenderBox del body (area scrollabile dell’agenda)
class DragBodyBoxNotifier extends Notifier<RenderBox?> {
  @override
  RenderBox? build() => null;

  void set(RenderBox box) => state = box;
  void clear() => state = null;
}

final dragBodyBoxProvider = NotifierProvider<DragBodyBoxNotifier, RenderBox?>(
  DragBodyBoxNotifier.new,
);
