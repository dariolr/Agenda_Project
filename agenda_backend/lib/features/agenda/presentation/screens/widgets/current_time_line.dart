import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/tenant_time_service.dart';
import '../../../providers/date_range_provider.dart';
import '../../../providers/initial_scroll_provider.dart';
import '../../../providers/layout_config_provider.dart';
import '../../../providers/tenant_time_provider.dart';

/// 🔹 Linea rossa che indica l'orario corrente.
/// - visibile solo sulla data odierna
/// - sincronizzata minuto per minuto
/// - la posizione verticale effettiva viene corretta con [verticalOffset]
///   passato da AgendaScreen (offset di scroll della giornata).
class CurrentTimeLine extends ConsumerStatefulWidget {
  static const double horizontalMargin = 4.0;

  final double hourColumnWidth;
  final double verticalOffset;
  final ScrollController? verticalController;
  final double horizontalOffset;

  const CurrentTimeLine({
    super.key,
    required this.hourColumnWidth,
    required this.verticalOffset,
    this.verticalController,
    this.horizontalOffset = 0,
  });

  @override
  ConsumerState<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends ConsumerState<CurrentTimeLine> {
  Timer? _minuteTimer;
  ScrollController? _verticalController;

  // 🔹 Definiamo l'altezza della linea come costante
  static const double _lineHeight = 1.0;
  // 🔹 Definiamo il margine/gap che conterrà la linea
  static const double _lineMargin = CurrentTimeLine.horizontalMargin;
  // Altezza esplicita del box orario.
  static const double _timeBoxHeight = 22.0;

  @override
  void initState() {
    super.initState();
    _attachVerticalController(widget.verticalController);

    // Aggiornamento minuto per minuto
    _scheduleMinuteSync();
  }

  @override
  void didUpdateWidget(covariant CurrentTimeLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.verticalController, widget.verticalController)) {
      _attachVerticalController(widget.verticalController);
    }
  }

  void _attachVerticalController(ScrollController? controller) {
    _verticalController?.removeListener(_onVerticalScrollChanged);
    _verticalController = controller;
    _verticalController?.addListener(_onVerticalScrollChanged);
  }

  void _onVerticalScrollChanged() {
    if (!mounted) return;
    setState(() {});
  }

  DateTime _tenantNow(String timezone) {
    return TenantTimeService.nowInTimezone(timezone);
  }

  void _scheduleMinuteSync() {
    final timezone = ref.read(effectiveTenantTimezoneProvider);
    final now = _tenantNow(timezone);
    final msToNextMinute = 60000 - (now.second * 1000 + now.millisecond);
    _minuteTimer = Timer(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) return;
      setState(() {});
      _minuteTimer?.cancel();
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _verticalController?.removeListener(_onVerticalScrollChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialScrollDone = ref.watch(initialScrollDoneProvider);
    if (!initialScrollDone) {
      return const SizedBox.shrink();
    }

    final selectedDate = ref.watch(agendaDateProvider);
    // Calcoliamo "oggi" direttamente dal service: tenantTodayProvider è cachato
    // e non si aggiornerebbe a mezzanotte senza un'invalidazione esplicita.
    final timezone = ref.watch(effectiveTenantTimezoneProvider);
    final today = TenantTimeService.dateOnlyTodayInTimezone(timezone);
    final isToday = DateUtils.isSameDay(selectedDate, today);
    if (!isToday) {
      return const SizedBox.shrink();
    }

    final layout = ref.watch(layoutConfigProvider);
    final now = _tenantNow(timezone);
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final liveLabel =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final liveOffset = layout.offsetForMinuteOfDay(minutesSinceMidnight);

    final persistedVerticalOffset = ref.watch(agendaVerticalOffsetProvider);
    final effectiveVerticalOffset =
        (_verticalController != null && _verticalController!.hasClients)
        ? _verticalController!.offset
        : (persistedVerticalOffset ?? widget.verticalOffset);

    // Posizione del centro timeline nel contenitore padre.
    final lineCenterY =
        liveOffset - effectiveVerticalOffset + layout.headerHeight;
    final timelineTop = lineCenterY - (_timeBoxHeight / 2);
    final clipTop = (layout.headerHeight - timelineTop).clamp(
      0.0,
      _timeBoxHeight,
    );

    return Positioned(
      top: timelineTop,
      left: widget.horizontalOffset,
      right: 0,
      child: ClipRect(
        clipper: _TopCutClipper(clipTop),
        child: SizedBox(
          height: _timeBoxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // --- Linea rossa orizzontale (centrata verticalmente) ---
              Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                    SizedBox(width: widget.hourColumnWidth - _lineMargin),
                    Container(
                      width: _lineMargin,
                      height: _lineHeight,
                      color: Colors.redAccent,
                    ),
                    Expanded(
                      child: Container(
                        height: _lineHeight,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              // --- Box dell'orario ---
              Positioned(
                left: -_lineMargin - 1,
                width: widget.hourColumnWidth,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: double.infinity,
                    height: _timeBoxHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      liveLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCutClipper extends CustomClipper<Rect> {
  const _TopCutClipper(this.topCut);

  final double topCut;

  @override
  Rect getClip(Size size) {
    final cut = topCut.clamp(0.0, size.height);
    // Clip solo verticale: mantieni l'overflow orizzontale del box orario
    // (che è posizionato con left negativo per allinearsi alla colonna ore).
    return Rect.fromLTRB(-10000, cut, size.width + 10000, size.height);
  }

  @override
  bool shouldReclip(covariant _TopCutClipper oldClipper) =>
      oldClipper.topCut != topCut;
}
