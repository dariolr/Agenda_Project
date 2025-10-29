import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'form_factor_provider.g.dart';

// Definiamo i due layout che ci interessano
enum AppFormFactor { mobile, tabletOrDesktop }

@riverpod
class FormFactorNotifier extends _$FormFactorNotifier {
  @override
  AppFormFactor build() {
    // Il default è mobile, ma verrà aggiornato immediatamente
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
