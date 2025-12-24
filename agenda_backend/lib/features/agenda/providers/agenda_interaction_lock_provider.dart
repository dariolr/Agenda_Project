import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'agenda_providers.dart';
import 'is_resizing_provider.dart';
import 'selected_appointment_provider.dart';

/// Stato condiviso che indica se il puntatore è attualmente sopra una card.
class AgendaCardHoverNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setHovering(bool hovering) => state = hovering;

  void enter() => state = true;

  void exit() => state = false;
}

final agendaCardHoverProvider = NotifierProvider<AgendaCardHoverNotifier, bool>(
  AgendaCardHoverNotifier.new,
);

/// Restituisce `true` quando il PageView deve essere disabilitato
/// (drag, resize, hover o card selezionate).
final agendaDayScrollLockProvider = Provider<bool>((ref) {
  final isResizing = ref.watch(isResizingProvider);
  final isDragging = ref.watch(dragPositionProvider) != null;
  final hasSelection = !ref.watch(selectedAppointmentProvider).isEmpty;
  final isHovering = ref.watch(agendaCardHoverProvider);
  return isResizing || isDragging || hasSelection || isHovering;
});
