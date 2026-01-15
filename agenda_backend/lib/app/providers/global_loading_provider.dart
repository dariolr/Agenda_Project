import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalLoadingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void show() {
    state = state + 1;
  }

  void hide() {
    if (state > 0) {
      state = state - 1;
    }
  }
}

final globalLoadingProvider = NotifierProvider<GlobalLoadingNotifier, int>(
  GlobalLoadingNotifier.new,
);
