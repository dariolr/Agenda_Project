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
  static const double horizontalMargin = 4.0;

  final double hourColumnWidth;
  final double verticalOffset;
  final double horizontalOffset;

  const CurrentTimeLine({
    super.key,
    required this.hourColumnWidth,
    required this.verticalOffset,
    this.horizontalOffset = 0,
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
  static const double _lineMargin = CurrentTimeLine.horizontalMargin;

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
      left: widget.horizontalOffset,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- Linea rossa orizzontale (l'elemento di riferimento) ---
          Row(
            children: [
              // Spazio per la colonna oraria
              SizedBox(width: widget.hourColumnWidth - _lineMargin),
              // Linea dalla fine del box fino al bordo destro
              Container(
                width: _lineMargin,
                height: _lineHeight,
                color: Colors.redAccent,
              ),
              Expanded(
                child: Container(height: _lineHeight, color: Colors.redAccent),
              ),
            ],
          ),
          // --- Box dell'orario (centrato verticalmente sulla linea) ---
          Positioned(
            left: -_lineMargin - 1,
            width: widget.hourColumnWidth,
            top: 0,
            child: FractionalTranslation(
              // Sposta il box del 50% della sua altezza verso l'alto
              // così il suo centro si allinea con la linea
              translation: const Offset(0, -0.5),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    _label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
