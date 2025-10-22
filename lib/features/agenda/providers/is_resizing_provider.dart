import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider che tiene traccia se si sta ridimensionando una AppointmentCard.
/// Utilizzato per bloccare lo scroll verticale delle colonne durante il resize.
class IsResizingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() => state = true;
  void stop() => state = false;
}

final isResizingProvider = NotifierProvider<IsResizingNotifier, bool>(
  IsResizingNotifier.new,
);
