import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider per tracciare se è stata effettuata la prima apertura dell'agenda.
/// Lo scroll automatico all'orario corrente avviene SOLO alla prima apertura.
class InitialScrollDoneNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marca lo scroll iniziale come completato.
  void markDone() {
    state = true;
  }

  /// Reset (usato quando si cambia business).
  void reset() {
    state = false;
  }
}

final initialScrollDoneProvider =
    NotifierProvider<InitialScrollDoneNotifier, bool>(
      InitialScrollDoneNotifier.new,
    );
