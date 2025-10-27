import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/config/layout_config.dart';
import '../../../providers/layout_config_provider.dart';

/// 🔹 Widget autonomo che disegna e aggiorna la riga rossa dell’orario corrente
class CurrentTimeLine extends ConsumerStatefulWidget {
  final double hourColumnWidth;

  const CurrentTimeLine({super.key, required this.hourColumnWidth});

  @override
  ConsumerState<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends ConsumerState<CurrentTimeLine> {
  Timer? _minuteTimer;
  double _offset = 0;
  String _label = '';
  late final ProviderSubscription<double> _slotHeightSub;

  @override
  void initState() {
    super.initState();
    _slotHeightSub = ref.listenManual<double>(
      layoutConfigProvider,
      (previous, next) => _updateLine(slotHeightOverride: next),
      fireImmediately: true,
    );
    _scheduleMinuteSync();
  }

  void _scheduleMinuteSync() {
    final now = DateTime.now();
    final msToNextMinute = 60000 - (now.second * 1000 + now.millisecond);

    _minuteTimer = Timer(Duration(milliseconds: msToNextMinute), () {
      _updateLine();
      _minuteTimer?.cancel();
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _updateLine();
      });
    });
  }

  void _updateLine({double? slotHeightOverride}) {
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final double slotHeight =
        slotHeightOverride ?? ref.read(layoutConfigProvider);
    final offset =
        (minutesSinceMidnight / LayoutConfig.minutesPerSlot) * slotHeight;
    final label =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    if (mounted) {
      setState(() {
        _offset = offset;
        _label = label;
      });
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _slotHeightSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _offset,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Pallino e orario nella colonna ore
          SizedBox(
            width: widget.hourColumnWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _label,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          // Linea rossa che attraversa tutte le colonne
          Expanded(child: Container(height: 0.5, color: Colors.redAccent)),
        ],
      ),
    );
  }
}
