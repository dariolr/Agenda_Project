import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Buffer temporaneo di log del router GoRouter, visibile solo in kDebugMode.
/// Conserva al massimo 50 righe ordinate dal più recente al più vecchio.
class RouterDebugLogNotifier extends Notifier<List<String>> {
  static const int _maxEntries = 50;

  @override
  List<String> build() => const [];

  void addLine(String line) {
    if (!kDebugMode) return;
    debugPrint('[RouterDebug] $line');
    final updated = [line, ...state];
    state = updated.length > _maxEntries
        ? updated.sublist(0, _maxEntries)
        : updated;
  }

  void clear() => state = const [];
}

final routerDebugLogProvider =
    NotifierProvider<RouterDebugLogNotifier, List<String>>(
      RouterDebugLogNotifier.new,
    );
