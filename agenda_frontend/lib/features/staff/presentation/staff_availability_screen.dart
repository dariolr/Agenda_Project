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

import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/models/staff.dart';
import 'package:agenda_frontend/core/widgets/staff_picker_sheet.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/staff/presentation/widgets/exception_calendar_view.dart';
import 'package:agenda_frontend/features/staff/presentation/widgets/weekly_schedule_editor.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
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

    // Genera set di slot per un turno con semantica [start, end) - estremo finale ESCLUSIVO.
    // Esempio: 09:00..13:00 => slot 36..51 (09:00, 09:15, ..., 12:45)
    // Lo slot 52 (13:00) NON è incluso, quindi sarà marcato come non disponibile.
    Set<int> rangeSlots(
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
    ) {
      final start = slotIndexOf(startHour, startMinute);
      final end = slotIndexOf(endHour, endMinute); // esclusivo
      return {for (int i = start; i < end; i++) i};
    }

    final morning = rangeSlots(9, 0, 13, 0); // 9:00 -> 12:45 (13:00 escluso)
    final afternoon = rangeSlots(
      14,
      0,
      19,
      0,
    ); // 14:00 -> 18:45 (19:00 escluso)
    final combined = {...morning, ...afternoon};

    Map<int, Set<int>> weekTemplate() => {
      // Days: 1 Mon .. 6 Sat -> combined, 7 Sun empty
      for (int d = 1; d <= 6; d++) d: Set<int>.from(combined),
      7: <int>{},
    };

    // Recupera elenco staff per applicare il template a tutti
    // (Se non disponibile nel build, creiamo un set minimo.)
    // Nota: non abbiamo accesso diretto ai provider qui, quindi ipotizziamo id staff 1..4 come mock.
    final staffIds = [for (int i = 1; i <= 4; i++) i];
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
// 🖥️ Schermata principale: StaffAvailabilityScreen
// ──────────────────────────────────────────────

class StaffAvailabilityScreen extends ConsumerStatefulWidget {
  const StaffAvailabilityScreen({super.key});

  @override
  ConsumerState<StaffAvailabilityScreen> createState() =>
      _StaffAvailabilityScreenState();
}

class _StaffAvailabilityScreenState
    extends ConsumerState<StaffAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  // Stato locale per staff corrente: selezioni per giorno (slot assoluti)
  Map<int, Set<int>> _weeklySelections = {
    for (int d = 1; d <= 7; d++) d: <int>{},
  };
  // Stato salvato originale per confronto (traccia modifiche non salvate)
  Map<int, Set<int>> _savedWeeklySelections = {
    for (int d = 1; d <= 7; d++) d: <int>{},
  };
  // Mappa staffId -> disponibilità settimanale (slots)
  final Map<int, Map<int, Set<int>>> _staffSelections = {};
  int? _selectedStaffId; // definito dopo aver caricato staff list
  bool _initializedFromProvider = false;

  // Tab controller per navigare tra orario settimanale ed eccezioni
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Verifica se ci sono modifiche non salvate.
  bool get _hasUnsavedChanges {
    if (_weeklySelections.length != _savedWeeklySelections.length) return true;
    for (final entry in _weeklySelections.entries) {
      final saved = _savedWeeklySelections[entry.key];
      if (saved == null) return true;
      if (!_setEquals(entry.value, saved)) return true;
    }
    return false;
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

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

  Future<void> _save(WidgetRef ref, int minutesPerSlot) async {
    // Prima di salvare, unifica le fasce orarie contigue
    final currentSchedule = WeeklySchedule.fromSlots(
      _weeklySelections,
      minutesPerSlot: minutesPerSlot,
    );
    final mergedSchedule = currentSchedule.mergeContiguousShifts();
    final mergedSlots = mergedSchedule.toSlots(minutesPerSlot: minutesPerSlot);

    // Aggiorna lo stato locale con le fasce unificate
    setState(() {
      _weeklySelections = mergedSlots;
    });

    // Persisti nello storage locale per staff corrente
    if (_selectedStaffId != null) {
      _staffSelections[_selectedStaffId!] = {
        for (final entry in mergedSlots.entries)
          entry.key: Set<int>.from(entry.value),
      };
    }
    if (_selectedStaffId != null) {
      await ref
          .read(staffAvailabilityByStaffProvider.notifier)
          .saveForStaff(_selectedStaffId!, mergedSlots);
    }
    // Aggiorna lo stato salvato dopo il salvataggio
    _savedWeeklySelections = {
      for (final entry in mergedSlots.entries)
        entry.key: Set<int>.from(entry.value),
    };
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(layoutConfigProvider);
    final availabilityByStaff = ref.watch(staffAvailabilityByStaffProvider);
    // Usa lo staff filtrato per la location selezionata nella sezione staff
    final staffList = ref.watch(staffForStaffSectionProvider);

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
          // Salva lo stato originale per tracciare modifiche
          _savedWeeklySelections = {
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

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _showDiscardChangesDialog();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            staffName == null
                ? context.l10n.availabilityTitle
                : context.l10n.availabilityTitleFor(staffName),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: context.l10n.weeklyScheduleTitle),
              Tab(text: context.l10n.exceptionsTitle),
            ],
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
                  _StaffSelectorDropdown(
                    staffList: staffList,
                    selectedStaffId: _selectedStaffId,
                    onSelected: _switchStaff,
                  ),
                  // Mostra pulsante salva solo nella tab orario settimanale
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index != 0) {
                        return const SizedBox.shrink();
                      }
                      return FilledButton(
                        onPressed: (_selectedStaffId == null || isSaving)
                            ? null
                            : () => _save(ref, layout.minutesPerSlot),
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.availabilitySave),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── TabBarView con editor settimanale ed eccezioni ────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Editor orario settimanale
                  _buildWeeklyScheduleTab(layout),
                  // Tab 2: Calendario eccezioni
                  if (_selectedStaffId != null)
                    SingleChildScrollView(
                      child: ExceptionCalendarView(staffId: _selectedStaffId!),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce il tab dell'editor settimanale.
  Widget _buildWeeklyScheduleTab(dynamic layout) {
    final schedule = WeeklySchedule.fromSlots(
      _weeklySelections,
      minutesPerSlot: layout.minutesPerSlot,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Editor turni settimanali (scrollabile) - sotto
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 80, // Spazio per l'header
                ),
                child: WeeklyScheduleEditor(
                  initialSchedule: WeeklySchedule.fromSlots(
                    _weeklySelections,
                    minutesPerSlot: layout.minutesPerSlot,
                  ),
                  showHeader: false,
                  onChanged: (newSchedule) {
                    final newSlots = newSchedule.toSlots(
                      minutesPerSlot: layout.minutesPerSlot,
                    );
                    setState(() {
                      _weeklySelections = newSlots;
                    });
                  },
                ),
              ),
            ),

            // Header fisso con ombra - sopra
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.weeklyScheduleTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.weeklyScheduleTotalHours(
                          schedule.totalHours,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Mostra dialog di conferma per scartare le modifiche non salvate.
  Future<bool> _showDiscardChangesDialog() async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionDiscard),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Widget per selezione staff con bottom sheet/dialog (come nel form appuntamento)
class _StaffSelectorDropdown extends ConsumerStatefulWidget {
  const _StaffSelectorDropdown({
    required this.staffList,
    required this.selectedStaffId,
    required this.onSelected,
  });

  final List<Staff> staffList;
  final int? selectedStaffId;
  final ValueChanged<int> onSelected;

  @override
  ConsumerState<_StaffSelectorDropdown> createState() =>
      _StaffSelectorDropdownState();
}

class _StaffSelectorDropdownState
    extends ConsumerState<_StaffSelectorDropdown> {
  bool _isHovered = false;

  String _getSelectedLabel() {
    if (widget.selectedStaffId == null) {
      return context.l10n.labelSelect;
    }
    final staff = widget.staffList.firstWhere(
      (s) => s.id == widget.selectedStaffId,
      orElse: () => widget.staffList.first,
    );
    return '${staff.name} ${staff.surname}'.trim();
  }

  Staff? _getSelectedStaff() {
    if (widget.selectedStaffId == null) return null;
    return widget.staffList.firstWhere(
      (s) => s.id == widget.selectedStaffId,
      orElse: () => widget.staffList.first,
    );
  }

  Future<void> _showPicker() async {
    final result = await showStaffPickerSheet(
      context: context,
      ref: ref,
      staff: widget.staffList,
      selectedId: widget.selectedStaffId,
    );
    if (result != null) {
      widget.onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final interactions = theme.extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final backgroundColor = _isHovered
        ? Color.alphaBlend(hoverFill, colorScheme.surface)
        : colorScheme.surface;

    final selectedStaff = _getSelectedStaff();

    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: _showPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedStaff != null) ...[
                CircleAvatar(
                  backgroundColor: selectedStaff.color,
                  radius: 14,
                  child: Text(
                    selectedStaff.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(_getSelectedLabel(), style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
