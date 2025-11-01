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
  late final ProviderSubscription<LayoutConfig> _layoutConfigSub;

  @override
  void initState() {
    super.initState();
    _layoutConfigSub = ref.listenManual<LayoutConfig>(
      layoutConfigProvider,
      (previous, next) => _updateLine(configOverride: next),
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

  void _updateLine({LayoutConfig? configOverride}) {
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final LayoutConfig config =
        configOverride ?? ref.read(layoutConfigProvider);
    final slotHeight = config.slotHeight;
    final offset =
        (minutesSinceMidnight / config.minutesPerSlot) * slotHeight;
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
    _layoutConfigSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. La linea viene posizionata esattamente a _offset
    return Positioned(
      top: _offset,
      left: 0,
      right: 0,
      // Usiamo uno Stack per sovrapporre la linea e il testo
      child: Stack(
        clipBehavior: Clip.none, // Permette al testo di "uscire"
        children: [
          // 2. Questa è la linea rossa
          Container(
            height: 0.5, // Manteniamo un'altezza minima per la visibilità
            color: Colors.redAccent,
            // Lasciamo lo spazio per la colonna degli orari
            margin: EdgeInsets.only(left: widget.hourColumnWidth),
          ),

          // 3. Posizioniamo il testo e il pallino RELATIVAMENTE alla linea
          Positioned(
            left: 0,
            // Centriamo il testo verticalmente sulla linea.
            // (L'altezza del testo è 11 , quindi -5.5 è circa il centro)
            top: -6,
            child: SizedBox(
              width: widget.hourColumnWidth,
              child: SizedBox(
                width: widget.hourColumnWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
