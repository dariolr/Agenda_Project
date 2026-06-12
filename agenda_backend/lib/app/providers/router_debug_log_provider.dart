import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Buffer temporaneo di log del router GoRouter, visibile solo in kDebugMode.
/// Conserva al massimo 50 righe ordinate dal più recente al più vecchio.
class RouterDebugLogNotifier extends Notifier<List<String>> {
  static const int _maxEntries = 200;
  final List<String> _pendingLines = [];
  bool _flushScheduled = false;

  @override
  List<String> build() => const [];

  void addLine(String line) {
    debugPrint('[RouterDebug] $line');
    _pendingLines.add(line);
    if (_flushScheduled) return;

    _flushScheduled = true;
    Timer.run(_flushPendingLines);
  }

  void _flushPendingLines() {
    _flushScheduled = false;
    if (_pendingLines.isEmpty) return;

    final lines = List<String>.of(_pendingLines.reversed);
    _pendingLines.clear();
    final updated = [...lines, ...state];
    state = updated.length > _maxEntries
        ? updated.sublist(0, _maxEntries)
        : updated;
  }

  void clear() {
    _pendingLines.clear();
    state = const [];
  }
}

final routerDebugLogProvider =
    NotifierProvider<RouterDebugLogNotifier, List<String>>(
      RouterDebugLogNotifier.new,
    );
