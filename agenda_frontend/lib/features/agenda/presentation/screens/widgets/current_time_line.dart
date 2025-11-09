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
      debugPrint('CurrentTimeLine updated: offset=$_offset, label=$label');
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

    // posizione visibile = posizione teorica - offset di scroll
    final layout = ref.read(layoutConfigProvider);
    final visibleTop = _offset - widget.verticalOffset + layout.headerHeight;

    return Positioned(
      top: visibleTop,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🔴 Linea rossa continua su tutta la larghezza (inclusa colonna orari)
          Container(height: 1.5, color: Colors.redAccent),

          // 🕒 Etichetta orario + pallino dentro la colonna oraria
          Positioned(
            left: 0,
            top: -6,
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
        ],
      ),
    );
  }
}
