import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'form_factor_provider.g.dart';

// Definiamo i tre layout che ci interessano
enum AppFormFactor { mobile, tablet, desktop }

AppFormFactor _formFactorForWidth(double width) {
  if (width >= 1024) return AppFormFactor.desktop;
  if (width >= 600) return AppFormFactor.tablet;
  return AppFormFactor.mobile;
}

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
      return _formFactorForWidth(logicalSize.width);
    }

    return AppFormFactor.mobile;
  }

  /// Aggiorna il form factor in base alla larghezza dello schermo.
  /// Usa lo stesso breakpoint di 600px che usi nel resto dell'app.
  void update(double screenWidth) {
    final newFactor = _formFactorForWidth(screenWidth);

    // Aggiorna lo stato solo se il form factor cambia
    if (state != newFactor) {
      state = newFactor;
    }
  }
}
