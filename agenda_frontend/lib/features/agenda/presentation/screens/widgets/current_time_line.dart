import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/config/layout_config.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/layout_config_provider.dart';

/// 🔹 Linea rossa che indica l'orario corrente.
/// - visibile solo sulla data odierna
/// - sincronizzata minuto per minuto
/// - la posizione verticale effettiva viene corretta con [verticalOffset]
///   passato da AgendaScreen (offset di scroll della giornata).
class CurrentTimeLine extends ConsumerStatefulWidget {
  final double hourColumnWidth;
  final double verticalOffset;

  const CurrentTimeLine({
    super.key,
    required this.hourColumnWidth,
    required this.verticalOffset,
  });

  @override
  ConsumerState<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends ConsumerState<CurrentTimeLine> {
  Timer? _minuteTimer;
  double _offset = 0;
  String _label = '';
  late final ProviderSubscription<LayoutConfig> _layoutConfigSub;

  // 🔹 Definiamo l'altezza della linea come costante
  static const double _lineHeight = 1.0;
  // 🔹 Definiamo il margine/gap che conterrà la linea
  static const double _lineMargin = 4.0;

  @override
  void initState() {
    super.initState();

    // Ascolta i cambi di LayoutConfig (slotHeight / minutesPerSlot)
    _layoutConfigSub = ref.listenManual<LayoutConfig>(
      layoutConfigProvider,
      (prev, next) => _updateLine(configOverride: next),
      fireImmediately: true,
    );

    // Aggiornamento minuto per minuto
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
    final offset = (minutesSinceMidnight / config.minutesPerSlot) * slotHeight;
    final label =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    if (!mounted) return;
    setState(() {
      _offset = offset;
      _label = label;
    });
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _layoutConfigSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mostra la linea solo se la data visualizzata è oggi
    final selectedDate = ref.watch(agendaDateProvider);
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = DateUtils.isSameDay(selectedDate, today);
    if (!isToday) {
      return const SizedBox.shrink();
    }

    final layout = ref.read(layoutConfigProvider);

    // 🔹 Calcoliamo la posizione Y del CENTRO della linea
    final lineCenterY = _offset - widget.verticalOffset + layout.headerHeight;
    // 🔹 Calcoliamo il 'top' per il Positioned
    final lineTopY = lineCenterY - (_lineHeight / 2);

    return Positioned(
      top: lineTopY,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- 1. Colonna Oraria (Box + 4px di linea) ---
          SizedBox(
            width: widget.hourColumnWidth,
            // 💡 Usiamo una Row interna per separare Box e 4px di linea
            child: Row(
              children: [
                // 1a. Spazio flessibile con il Box
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    // Il Box rosso
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        _label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // 1b. Il "margine" di 4px, che è la linea rossa
                Container(
                  width: _lineMargin,
                  height: _lineHeight,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // --- 2. La linea rossa nel corpo principale ---
          Expanded(
            child: Container(height: _lineHeight, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
