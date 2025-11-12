/*
──────────────────────────────────────────────
🎯 FUNZIONALITÀ COMPLETA: Gestione disponibilità staff
──────────────────────────────────────────────

CONTESTO:
Progetto Flutter web "Agenda Platform".
Architettura basata su:
- Riverpod per lo stato e provider
- Widget principali: MultiStaffDayView, StaffColumn, AppointmentCard
- Configurazione: LayoutConfig e AgendaTheme

OBIETTIVO:
Schermata per gestire disponibilità settimanali dello staff.

AGGIORNAMENTI RECENTI:
- Copertura 24h (00:00–24:00)
- Scroll verticale sincronizzato tra colonna orari e griglia giorni
- Etichetta oraria centrata in ogni cella (HH:MM)

*/

import 'dart:async';
import 'dart:math' as math;

import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/agenda/domain/config/agenda_theme.dart';
import 'package:agenda_frontend/features/agenda/domain/config/layout_config.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ──────────────────────────────────────────────
// 📦 MODEL: TimeRange (ore intere)
// ──────────────────────────────────────────────
class TimeRange {
  final int startHour; // incluso
  final int endHour; // escluso

  const TimeRange(this.startHour, this.endHour)
    : assert(startHour >= 0 && startHour <= 23),
      assert(endHour >= 1 && endHour <= 24),
      assert(endHour > startHour);

  @override
  String toString() => 'TimeRange($startHour-$endHour)';

  TimeRange copyWith({int? startHour, int? endHour}) =>
      TimeRange(startHour ?? this.startHour, endHour ?? this.endHour);
}

// ──────────────────────────────────────────────
// 🧠 PROVIDER MOCK: StaffAvailabilityNotifier
// Stato: AsyncValue<Map<int, List<TimeRange>>>
// ──────────────────────────────────────────────

// Nuovo provider per persistenza per-staff: staffId -> day -> slots (Set<int>)
class StaffAvailabilityByStaffNotifier
    extends AsyncNotifier<Map<int, Map<int, Set<int>>>> {
  @override
  FutureOr<Map<int, Map<int, Set<int>>>> build() async {
    // Mock iniziale: per TUTTI gli staff (verrà sovrascritto quando si salva)
    // Turni standard: 09:00–13:00 e 14:00–19:00 dal lunedì al sabato, domenica vuoto.
    // Rappresentiamo gli slot attivi usando step di minutesPerSlot = 15 (assunto).
    const minutesPerSlot = 15; // Assunzione coerente con layout corrente.
    int slotIndexOf(int hour, int minute) =>
        (hour * 60 + minute) ~/ minutesPerSlot;

    // Genera set di slot per un turno con semantica tick inclusiva sugli estremi:
    // selezioniamo l'indice di inizio e anche quello dell'ora finale; la durata sarà
    // (count - 1) * minutesPerSlot. Esempio: 09:00..13:00 => slot 36..52 inclusi (17 slot) => 16*15 = 240 min.
    Set<int> rangeSlots(
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
    ) {
      final start = slotIndexOf(startHour, startMinute);
      final end = slotIndexOf(endHour, endMinute); // inclusivo
      return {for (int i = start; i <= end; i++) i};
    }

    final morning = rangeSlots(9, 0, 13, 0); // 9:00 -> 13:00
    final afternoon = rangeSlots(14, 0, 19, 0); // 14:00 -> 19:00
    final combined = {...morning, ...afternoon};

    Map<int, Set<int>> weekTemplate() => {
      // Days: 1 Mon .. 6 Sat -> combined, 7 Sun empty
      for (int d = 1; d <= 6; d++) d: Set<int>.from(combined),
      7: <int>{},
    };

    // Recupera elenco staff per applicare il template a tutti
    // (Se non disponibile nel build, creiamo un set minimo.)
    // Nota: non abbiamo accesso diretto ai provider qui, quindi ipotizziamo id staff 1..14 come mock.
    final staffIds = [for (int i = 1; i <= 14; i++) i];
    return {for (final id in staffIds) id: weekTemplate()};
  }

  Future<void> saveForStaff(int staffId, Map<int, Set<int>> weeklySlots) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 300));
    final current = Map<int, Map<int, Set<int>>>.from(state.value ?? {});
    current[staffId] = {
      for (final e in weeklySlots.entries) e.key: Set<int>.from(e.value),
    };
    state = AsyncData(current);
    // ignore: avoid_print
    print(
      '[StaffAvailabilityByStaff] Saved for staff $staffId: ${current[staffId]}',
    );
  }
}

final staffAvailabilityByStaffProvider =
    AsyncNotifierProvider<
      StaffAvailabilityByStaffNotifier,
      Map<int, Map<int, Set<int>>>
    >(StaffAvailabilityByStaffNotifier.new);

// ──────────────────────────────────────────────
// 🎨 Colori specifici per disponibilità (coerenti con AgendaTheme)
// ──────────────────────────────────────────────

class AvailabilityTheme {
  // #41B2B2 con alpha ~20%
  static const Color availabilitySelectedColor = Color(0x3341B2B2);
  // Sfondo neutro
  static const Color availabilityDefaultColor = Color(0xFFF5F5F5);

  static const double borderRadius = LayoutConfig.borderRadius;
}

// ──────────────────────────────────────────────
// 🔢 Helper: conversione slot <-> TimeRange
// Lo slot è un indice da 0..(24h*60/minutesPerSlot - 1)
// ──────────────────────────────────────────────

int _timeToSlotIndex({
  required int hour,
  required int minute,
  required int minutesPerSlot,
}) {
  final totalMinutes = hour * 60 + minute;
  return totalMinutes ~/ minutesPerSlot;
}

int _slotIndexToStartMinute(int slotIndex, int minutesPerSlot) =>
    slotIndex * minutesPerSlot;

Set<int> rangesToSlots(List<TimeRange> ranges, int minutesPerSlot) {
  final Set<int> slots = {};
  for (final r in ranges) {
    final startSlot = _timeToSlotIndex(
      hour: r.startHour,
      minute: 0,
      minutesPerSlot: minutesPerSlot,
    );
    final endSlot = _timeToSlotIndex(
      hour: r.endHour,
      minute: 0,
      minutesPerSlot: minutesPerSlot,
    );
    for (int s = startSlot; s < endSlot; s++) {
      slots.add(s);
    }
  }
  return slots;
}

List<TimeRange> slotsToRanges(Set<int> slots, int minutesPerSlot) {
  if (slots.isEmpty) return const [];
  final sorted = slots.toList()..sort();
  final List<List<int>> clusters = [];
  List<int> current = [sorted.first];
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i] == sorted[i - 1] + 1) {
      current.add(sorted[i]);
    } else {
      clusters.add(current);
      current = [sorted[i]];
    }
  }
  clusters.add(current);

  // Converti cluster in ore intere arrotondando ai bordi delle ore
  final List<TimeRange> ranges = [];
  for (final c in clusters) {
    final startMin = _slotIndexToStartMinute(c.first, minutesPerSlot);
    final endMin = _slotIndexToStartMinute(c.last + 1, minutesPerSlot);
    final startHour = startMin ~/ 60; // floor
    final endHour = (endMin + 59) ~/ 60; // ceil
    if (endHour > startHour) {
      ranges.add(TimeRange(startHour, endHour.clamp(0, 24)));
    }
  }
  return ranges;
}

// ──────────────────────────────────────────────
// 🎛️ Controller per drag painting nella griglia
// ──────────────────────────────────────────────

class _SelectionController extends ChangeNotifier {
  bool _isDragging = false;
  bool _dragValue = false;

  bool get isDragging => _isDragging;
  bool get dragValue => _dragValue;

  void start(bool value) {
    _isDragging = true;
    _dragValue = value;
    notifyListeners();
  }

  void stop() {
    if (!_isDragging) return;
    _isDragging = false;
    notifyListeners();
  }
}

// ──────────────────────────────────────────────
// 🔳 AvailabilityCell: singolo slot interattivo
// ──────────────────────────────────────────────

class AvailabilityCell extends StatefulWidget {
  final bool selected;
  final double height;
  final VoidCallback? onTap;
  final _SelectionController? controller;
  final String timeLabel; // HH:MM

  const AvailabilityCell({
    super.key,
    required this.selected,
    required this.height,
    required this.timeLabel,
    this.onTap,
    this.controller,
  });

  @override
  State<AvailabilityCell> createState() => _AvailabilityCellState();
}

class _AvailabilityCellState extends State<AvailabilityCell> {
  bool _hovered = false;

  void _maybePaintOnHover() {
    final ctrl = widget.controller;
    if (ctrl != null && ctrl.isDragging && widget.onTap != null) {
      // Durante il drag, "entra" nella cella e applica il valore di drag
      if (widget.selected != ctrl.dragValue) {
        widget.onTap!.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AvailabilityTheme.availabilitySelectedColor
        : AvailabilityTheme.availabilityDefaultColor;
    final l10n = context.l10n;
    final semanticLabel = widget.selected
        ? l10n.availabilitySlotSelectedLabel(widget.timeLabel)
        : l10n.availabilitySlotUnselectedLabel(widget.timeLabel);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _maybePaintOnHover();
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onPanStart: (_) {
          widget.controller?.start(!widget.selected);
          // applica anche alla cella corrente
          widget.onTap?.call();
        },
        onPanUpdate: (_) => _maybePaintOnHover(),
        onPanEnd: (_) => widget.controller?.stop(),
        onPanCancel: () => widget.controller?.stop(),
        child: Semantics(
          selected: widget.selected,
          button: true,
          label: semanticLabel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: widget.height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                AvailabilityTheme.borderRadius,
              ),
              border: Border.all(
                color: AgendaTheme.appointmentBorder,
                width: 0.6,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.timeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.black87,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 🗓️ AvailabilityGrid: 7 colonne × N righe (slot)
// ──────────────────────────────────────────────

class AvailabilityGrid extends StatefulWidget {
  final int startHour;
  final int endHour;
  final LayoutConfig layout;
  final Map<int, Set<int>> selections; // day(1..7) -> slots
  final void Function(int day, int slotIndex) onToggle;
  final int selectedDay; // evidenziazione header e per pulsanti esterni
  final void Function(int day)? onClearDay;
  final void Function(int day)? onCopyDayToAll;

  const AvailabilityGrid({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.layout,
    required this.selections,
    required this.onToggle,
    required this.selectedDay,
    this.onClearDay,
    this.onCopyDayToAll,
  });
  @override
  State<AvailabilityGrid> createState() => _AvailabilityGridState();
}

class _AvailabilityGridState extends State<AvailabilityGrid> {
  late final ScrollController verticalController;
  late final ScrollController headerHController;
  bool _didInitialScroll = false;

  int get slotsPerHour => (60 ~/ widget.layout.minutesPerSlot);
  int get visibleSlots => (widget.endHour - widget.startHour) * slotsPerHour;

  @override
  void initState() {
    super.initState();
    verticalController = ScrollController();
    headerHController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialHour());
  }

  void _scrollToInitialHour() {
    if (_didInitialScroll || !verticalController.hasClients) return;
    // Trova lo slot assoluto minimo attivo tra tutti i giorni
    int? earliestSlot;
    for (final daySet in widget.selections.values) {
      if (daySet.isNotEmpty) {
        final minInDay = daySet.reduce((a, b) => a < b ? a : b);
        if (earliestSlot == null || minInDay < earliestSlot) {
          earliestSlot = minInDay;
        }
      }
    }
    int targetHour;
    if (earliestSlot != null) {
      final earliestMinute = earliestSlot * widget.layout.minutesPerSlot;
      targetHour = earliestMinute ~/ 60;
    } else {
      targetHour = 9; // default 09:00
    }
    targetHour = targetHour.clamp(widget.startHour, widget.endHour - 1);
    const double slotVPad = 2.0;
    final double slotStride = widget.layout.slotHeight + (slotVPad * 2);
    final double offset =
        (targetHour - widget.startHour) * slotsPerHour * slotStride;
    final double maxOffset = verticalController.position.maxScrollExtent;
    verticalController.jumpTo(offset.clamp(0, maxOffset));
    _didInitialScroll = true;
  }

  @override
  void dispose() {
    verticalController.dispose();
    headerHController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectionController = _SelectionController();

    final l10n = context.l10n;
    final dayNames = [
      l10n.dayMonShort,
      l10n.dayTueShort,
      l10n.dayWedShort,
      l10n.dayThuShort,
      l10n.dayFriShort,
      l10n.daySatShort,
      l10n.daySunShort,
    ];
    final hourLabels = List.generate(
      widget.endHour - widget.startHour,
      (i) => widget.startHour + i,
    );
    final hourColWidth = math.max(widget.layout.hourColumnWidth, 52.0);
    // Deve combaciare con il Padding verticale degli slot nelle colonne dei giorni
    const double slotVPad = 2.0;
    final double slotStride = widget.layout.slotHeight + (slotVPad * 2);

    Widget buildDayHeader(int day) {
      final hasActive = (widget.selections[day]?.isNotEmpty ?? false);
      // Calcola i minuti esatti raggruppando gli slot consecutivi
      int totalMinutes = 0;
      final daySlots = widget.selections[day] ?? const <int>{};
      if (daySlots.isNotEmpty) {
        final sorted = daySlots.toList()..sort();
        List<int> current = [sorted.first];
        for (int i = 1; i < sorted.length; i++) {
          if (sorted[i] == sorted[i - 1] + 1) {
            current.add(sorted[i]);
          } else {
            // Regola: il primo slot di una serie indica solo l'inizio,
            // quindi la durata è (n-1) * minutesPerSlot
            totalMinutes +=
                math.max(0, (current.length - 1)) *
                widget.layout.minutesPerSlot;
            current = [sorted[i]];
          }
        }
        totalMinutes +=
            math.max(0, (current.length - 1)) * widget.layout.minutesPerSlot;
      }
      final totalHours = totalMinutes ~/ 60;
      final remMinutes = totalMinutes % 60;
      String totalStr = '';
      if (totalMinutes > 0) {
        if (remMinutes == 0) {
          totalStr = l10n.hoursHoursOnly(totalHours);
        } else {
          totalStr = l10n.hoursMinutesCompact(totalHours, remMinutes);
        }
      }
      return SizedBox(
        height: LayoutConfig.headerHeightFor(context),
        child: Stack(
          children: [
            // Background + label centrata
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AgendaTheme.staffHeaderBackground(
                    hasActive ? Colors.teal : Colors.blueGrey,
                  ),
                  borderRadius: BorderRadius.circular(
                    AvailabilityTheme.borderRadius,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNames[day - 1],
                      style: AgendaTheme.staffHeaderTextStyle,
                    ),
                    if (hasActive && totalStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          totalStr,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    const double actionsHeight = 28.0;

    Widget buildDayActions(int day) {
      return SizedBox(
        height: actionsHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: l10n.availabilityCopyToAll,
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              iconSize: 18,
              color: Colors.black87,
              onPressed: widget.onCopyDayToAll == null
                  ? null
                  : () => widget.onCopyDayToAll!(day),
              icon: const Icon(Icons.content_copy),
            ),
            IconButton(
              tooltip: l10n.availabilityClear,
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              iconSize: 18,
              color: Colors.black87,
              onPressed: widget.onClearDay == null
                  ? null
                  : () => widget.onClearDay!(day),
              icon: const Icon(Icons.cancel_outlined),
            ),
          ],
        ),
      );
    }

    Widget buildHourColumnBody() {
      return SizedBox(
        width: hourColWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in hourLabels)
              SizedBox(
                // Altezza di un blocco ora = numero di slot per ora * (altezza cella + padding verticale per slot)
                height: slotStride * slotsPerHour,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0, top: 2),
                    child: Text(
                      DtFmt.hOnly(context, h),
                      style: AgendaTheme.hourTextStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget buildDayBody(int day) {
      final daySlots = widget.selections[day] ?? <int>{};
      final firstSlotIndex = _timeToSlotIndex(
        hour: widget.startHour,
        minute: 0,
        minutesPerSlot: widget.layout.minutesPerSlot,
      );
      return SizedBox(
        width: LayoutConfig.minColumnWidthDesktop,
        child: Column(
          children: [
            for (int index = 0; index < visibleSlots; index++) ...[
              Builder(
                builder: (_) {
                  final absoluteIndex = firstSlotIndex + index;
                  final selected = daySlots.contains(absoluteIndex);
                  final totalMinutes =
                      absoluteIndex * widget.layout.minutesPerSlot;
                  final hour = totalMinutes ~/ 60;
                  final minute = totalMinutes % 60;
                  final label = DtFmt.hm(context, hour, minute);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 2,
                    ),
                    child: AvailabilityCell(
                      key: Key(
                        'availability_cell_day_${day}_slot_$absoluteIndex',
                      ),
                      selected: selected,
                      height: widget.layout.slotHeight,
                      controller: selectionController,
                      timeLabel: label,
                      onTap: () => widget.onToggle(day, absoluteIndex),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Azioni sopra gli header (scroll orizzontale separato)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: hourColWidth, height: actionsHeight),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: headerHController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int day = 1; day <= 7; day++) ...[
                      SizedBox(
                        width: LayoutConfig.minColumnWidthDesktop,
                        child: buildDayActions(day),
                      ),
                      if (day < 7) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // Header (scroll orizzontale separato)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: hourColWidth,
              height: LayoutConfig.headerHeightFor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: headerHController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int day = 1; day <= 7; day++) ...[
                      SizedBox(
                        width: LayoutConfig.minColumnWidthDesktop,
                        child: buildDayHeader(day),
                      ),
                      if (day < 7) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Corpo con scroll sincronizzato (vert)
        Expanded(
          child: ScrollConfiguration(
            behavior: const NoScrollbarBehavior(),
            child: SingleChildScrollView(
              controller: verticalController,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHourColumnBody(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: const NoScrollbarBehavior(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int day = 1; day <= 7; day++) ...[
                              buildDayBody(day),
                              if (day < 7) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 🖥️ Schermata principale: StaffAvailabilityScreen
// ──────────────────────────────────────────────

class StaffAvailabilityScreen extends ConsumerStatefulWidget {
  const StaffAvailabilityScreen({super.key});

  @override
  ConsumerState<StaffAvailabilityScreen> createState() =>
      _StaffAvailabilityScreenState();
}

class _StaffAvailabilityScreenState
    extends ConsumerState<StaffAvailabilityScreen> {
  // Stato locale per staff corrente: selezioni per giorno (slot assoluti)
  Map<int, Set<int>> _weeklySelections = {
    for (int d = 1; d <= 7; d++) d: <int>{},
  };
  // Mappa staffId -> disponibilità settimanale (slots)
  final Map<int, Map<int, Set<int>>> _staffSelections = {};
  int? _selectedStaffId; // definito dopo aver caricato staff list
  final int _selectedDay = 1;
  bool _initializedFromProvider = false;

  // Configurazione visiva: fascia 08:00–20:00
  static const int _startHour = 0; // start at midnight
  static const int _endHour = 24; // cover full 24h

  // Metodo legacy rimosso: la conversione da ranges a slots ora non serve
  // perché salviamo direttamente gli slot. Manteniamo il commento per riferimento storico.

  void _ensureCurrentStaffInit(int staffId) {
    _staffSelections.putIfAbsent(staffId, () {
      // Clona la struttura vuota
      return {for (int d = 1; d <= 7; d++) d: <int>{}};
    });
  }

  void _switchStaff(int newStaffId) {
    final currentId = _selectedStaffId;
    if (currentId == newStaffId) return;
    // Salva lo stato corrente nello staff precedente
    if (currentId != null) {
      _staffSelections[currentId] = {
        for (final entry in _weeklySelections.entries)
          entry.key: Set<int>.from(entry.value),
      };
    }
    // Carica stato per nuovo staff (o crea vuoto)
    _ensureCurrentStaffInit(newStaffId);
    final loaded = _staffSelections[newStaffId]!;
    setState(() {
      _selectedStaffId = newStaffId;
      _weeklySelections = {
        for (final entry in loaded.entries)
          entry.key: Set<int>.from(entry.value),
      };
    });
  }

  void _toggleSlot(int day, int slotIndex) {
    setState(() {
      final set = _weeklySelections.putIfAbsent(day, () => <int>{});
      if (!set.add(slotIndex)) {
        set.remove(slotIndex);
      }
    });
  }

  // Metodi legacy rimossi: applica a tutti i giorni / azzera giorno.

  Future<void> _save(WidgetRef ref, int minutesPerSlot) async {
    // Persisti nello storage locale per staff corrente
    if (_selectedStaffId != null) {
      _staffSelections[_selectedStaffId!] = {
        for (final entry in _weeklySelections.entries)
          entry.key: Set<int>.from(entry.value),
      };
    }
    if (_selectedStaffId != null) {
      await ref
          .read(staffAvailabilityByStaffProvider.notifier)
          .saveForStaff(_selectedStaffId!, _weeklySelections);
    }
    if (mounted) {
      final l10n = context.l10n;
      String message;
      if (_selectedStaffId == null) {
        message = l10n.availabilitySaved;
      } else {
        // Trova il nome staff per messaggio più chiaro
        final staffList = ref.read(allStaffProvider);
        String name = _selectedStaffId!.toString();
        if (staffList.isNotEmpty) {
          final staff = staffList.firstWhere(
            (s) => s.id == _selectedStaffId,
            orElse: () => staffList.first,
          );
          name = '${staff.name} ${staff.surname}'.trim();
        }
        message = l10n.availabilitySavedFor(name);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(layoutConfigProvider);
    final availabilityByStaff = ref.watch(staffAvailabilityByStaffProvider);
    final staffList = ref.watch(allStaffProvider);

    // If a staffId was requested from another screen, pre-select it once
    final requested = ref.read(initialStaffToEditProvider).value;
    if (_selectedStaffId == null && requested != null && staffList.isNotEmpty) {
      _switchStaff(requested);
      // clear the request to avoid re-applying
      ref.read(initialStaffToEditProvider).value = null;
    }

    // Imposta staff iniziale se non selezionato
    if (_selectedStaffId == null && staffList.isNotEmpty) {
      _switchStaff(staffList.first.id);
    }

    availabilityByStaff.whenOrNull(
      data: (all) {
        if (_initializedFromProvider) return;
        final currentWeekly = (_selectedStaffId != null)
            ? (all[_selectedStaffId!] ?? const <int, Set<int>>{})
            : const <int, Set<int>>{};
        setState(() {
          _weeklySelections = {
            for (final e in currentWeekly.entries)
              e.key: Set<int>.from(e.value),
          };
          _initializedFromProvider = true;
        });
      },
    );

    final isSaving = availabilityByStaff.isLoading;

    String? staffName;
    if (_selectedStaffId != null && staffList.isNotEmpty) {
      final staff = staffList.firstWhere(
        (s) => s.id == _selectedStaffId,
        orElse: () => staffList.first,
      );
      staffName = '${staff.name} ${staff.surname}'.trim();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          staffName == null
              ? context.l10n.availabilityTitle
              : context.l10n.availabilityTitleFor(staffName),
        ),
      ),
      body: Column(
        children: [
          // ── Toolbar azioni ───────────────────────────────
          // Toolbar semplificata: solo selezione staff e salvataggio
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(context.l10n.labelStaff),
                DropdownButton<int>(
                  value: _selectedStaffId,
                  hint: Text(context.l10n.labelSelect),
                  items: [
                    for (final s in staffList)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.name} ${s.surname}'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) _switchStaff(v);
                  },
                ),
                FilledButton(
                  onPressed: (_selectedStaffId == null || isSaving)
                      ? null
                      : () => _save(ref, layout.minutesPerSlot),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.availabilitySave),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Griglia disponibilità ─────────────────────────
          Expanded(
            child: AvailabilityGrid(
              startHour: _startHour,
              endHour: _endHour,
              layout: layout,
              selections: _weeklySelections,
              onToggle: _toggleSlot,
              selectedDay: _selectedDay,
              onClearDay: (day) {
                setState(() {
                  _weeklySelections[day] = <int>{};
                });
              },
              onCopyDayToAll: (day) {
                final pattern = _weeklySelections[day] ?? <int>{};
                setState(() {
                  for (int d = 1; d <= 7; d++) {
                    _weeklySelections[d] = {...pattern};
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
