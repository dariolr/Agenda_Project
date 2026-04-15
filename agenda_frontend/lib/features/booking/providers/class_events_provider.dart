import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/class_event.dart';
import 'booking_provider.dart';

/// Notifier per gli eventi di classe pubblici della location corrente.
/// Carica una volta per location e si aggiorna se la location cambia.
class ClassEventsNotifier extends StateNotifier<AsyncValue<List<ClassEvent>>> {
  final Ref _ref;
  bool _hasFetched = false;
  int? _lastLocationId;

  ClassEventsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(effectiveLocationIdProvider, (previous, next) {
      if (next > 0 && next != _lastLocationId) {
        _hasFetched = false;
        _lastLocationId = next;
        _loadData();
      }
    }, fireImmediately: true);
  }

  Future<void> _loadData() async {
    if (_hasFetched) return;

    final locationId = _ref.read(effectiveLocationIdProvider);
    if (locationId <= 0) return;

    _hasFetched = true;

    try {
      final repository = _ref.read(bookingRepositoryProvider);
      final events = await repository.getClassEvents(locationId);
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _hasFetched = false;
    state = const AsyncValue.loading();
    await _loadData();
  }
}

final classEventsProvider =
    StateNotifierProvider<ClassEventsNotifier, AsyncValue<List<ClassEvent>>>(
      (ref) => ClassEventsNotifier(ref),
    );
