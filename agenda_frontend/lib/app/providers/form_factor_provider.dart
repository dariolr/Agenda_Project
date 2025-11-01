import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'form_factor_provider.g.dart';

// Definiamo i due layout che ci interessano
enum AppFormFactor { mobile, tabletOrDesktop }

@riverpod
class FormFactorNotifier extends _$FormFactorNotifier {
  @override
  AppFormFactor build() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    final dispatcher = binding.platformDispatcher;
    final ui.FlutterView? view = dispatcher.views.isNotEmpty
        ? dispatcher.views.first
        : dispatcher.implicitView;

    if (view != null) {
      final logicalSize = view.physicalSize / view.devicePixelRatio;
      return logicalSize.width >= 600
          ? AppFormFactor.tabletOrDesktop
          : AppFormFactor.mobile;
    }

    return AppFormFactor.mobile;
  }

  /// Aggiorna il form factor in base alla larghezza dello schermo.
  /// Usa lo stesso breakpoint di 600px che usi nel resto dell'app.
  void update(double screenWidth) {
    final newFactor = screenWidth >= 600
        ? AppFormFactor.tabletOrDesktop
        : AppFormFactor.mobile;

    // Aggiorna lo stato solo se il form factor cambia
    if (state != newFactor) {
      state = newFactor;
    }
  }
}
