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
- Persistenza su DB tramite API (01/01/2026)
- Integrazione Staff Planning (04/01/2026)

*/

import 'dart:async';

import 'package:agenda_backend/app/theme/extensions.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/network/network_providers.dart';
import 'package:agenda_backend/core/widgets/feedback_dialog.dart';
import 'package:agenda_backend/core/widgets/local_loading_overlay.dart';
import 'package:agenda_backend/core/widgets/staff_picker_sheet.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/staff/presentation/widgets/exception_calendar_view.dart';
import 'package:agenda_backend/features/staff/presentation/widgets/staff_planning_selector.dart';
import 'package:agenda_backend/features/staff/presentation/widgets/weekly_schedule_editor.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
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
// 🧠 PROVIDER: StaffAvailabilityByStaffNotifier
// Stato: AsyncValue<Map<int, Map<int, Set<int>>>>
// Carica e salva disponibilità settimanale tramite API
// ──────────────────────────────────────────────

// Nuovo provider per persistenza per-staff: staffId -> day -> slots (Set<int>)
class StaffAvailabilityByStaffNotifier
    extends AsyncNotifier<Map<int, Map<int, Set<int>>>> {
  static const _minutesPerSlot = 15;

  @override
  FutureOr<Map<int, Map<int, Set<int>>>> build() async {
    // Carica schedules dall'API per il business corrente
    final business = ref.watch(currentBusinessProvider);
    final apiClient = ref.watch(apiClientProvider);

    try {
      final apiSchedules = await apiClient.getStaffSchedulesAll(business.id);
      return _convertApiToSlots(apiSchedules);
    } catch (_) {
      // In caso di errore, ritorna mappa vuota
      return {};
    }
  }

  /// Converte la risposta API (time strings) in slot indices.
  Map<int, Map<int, Set<int>>> _convertApiToSlots(
    Map<int, Map<int, List<Map<String, String>>>> apiSchedules,
  ) {
    final result = <int, Map<int, Set<int>>>{};

    for (final staffEntry in apiSchedules.entries) {
      final staffId = staffEntry.key;
      final weekData = staffEntry.value;

      result[staffId] = {};
      for (int day = 1; day <= 7; day++) {
        final shifts = weekData[day] ?? [];
        final slots = <int>{};

        for (final shift in shifts) {
          final startTime = shift['start_time']!;
          final endTime = shift['end_time']!;
          slots.addAll(_timeRangeToSlots(startTime, endTime));
        }

        result[staffId]![day] = slots;
      }
    }

    return result;
  }

  /// Converte HH:MM:SS -> slot index.
  int _timeToSlotIndex(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return (hours * 60 + minutes) ~/ _minutesPerSlot;
  }

  /// Converte un range orario in set di slot indices.
  Set<int> _timeRangeToSlots(String startTime, String endTime) {
    final startSlot = _timeToSlotIndex(startTime);
    final endSlot = _timeToSlotIndex(endTime);
    return {for (int i = startSlot; i < endSlot; i++) i};
  }

  /// Converte slot index -> HH:MM string.
  String _slotToTime(int slot) {
    final minutes = slot * _minutesPerSlot;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Converte slots in ranges contigui e poi in formato API.
  List<Map<String, String>> _slotsToApiShifts(Set<int> slots) {
    if (slots.isEmpty) return [];

    final sorted = slots.toList()..sort();
    final ranges = <List<int>>[];
    var current = <int>[sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        current.add(sorted[i]);
      } else {
        ranges.add(current);
        current = [sorted[i]];
      }
    }
    ranges.add(current);

    return ranges.map((range) {
      final startSlot = range.first;
      final endSlot = range.last + 1; // end è esclusivo
      return {
        'start_time': _slotToTime(startSlot),
        'end_time': _slotToTime(endSlot),
      };
    }).toList();
  }

  Future<void> saveForStaff(int staffId, Map<int, Set<int>> weeklySlots) async {
    final previousState = state;
    state = const AsyncLoading();

    try {
      final apiClient = ref.read(apiClientProvider);

      // Converti slots in formato API
      final apiSchedule = <int, List<Map<String, String>>>{};
      for (int day = 1; day <= 7; day++) {
        final slots = weeklySlots[day] ?? {};
        apiSchedule[day] = _slotsToApiShifts(slots);
      }

      // Salva su API
      await apiClient.saveStaffSchedule(
        staffId: staffId,
        schedule: apiSchedule,
      );

      // Aggiorna stato locale
      final current = Map<int, Map<int, Set<int>>>.from(
        state.value ?? previousState.value ?? {},
      );
      current[staffId] = {
        for (final e in weeklySlots.entries) e.key: Set<int>.from(e.value),
      };
      state = AsyncData(current);
    } catch (e) {
      // Ripristina stato precedente
      state = previousState;
      rethrow;
    }
  }

  /// Ricarica gli schedules dall'API.
  Future<void> refresh() async {
    ref.invalidateSelf();
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

  // Staff Planning state
  StaffPlanning? _selectedPlanning;
  WeekLabel _selectedWeekLabel = WeekLabel.a;

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

  void _switchStaff(int newStaffId, {bool updateWeeklyState = true}) {
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
      if (updateWeeklyState) {
        _weeklySelections = {
          for (final entry in loaded.entries)
            entry.key: Set<int>.from(entry.value),
        };
        _savedWeeklySelections = {
          for (final entry in loaded.entries)
            entry.key: Set<int>.from(entry.value),
        };
      }
      // Reset planning selection when switching staff
      _selectedPlanning = null;
      _selectedWeekLabel = WeekLabel.a;
    });

    // Carica i planning per questo staff dall'API
    ref.read(staffPlanningsProvider.notifier).loadPlanningsForStaff(newStaffId);
  }

  /// Callback quando viene selezionato un planning
  void _onPlanningSelected(StaffPlanning? planning) {
    setState(() {
      _selectedPlanning = planning;
      if (planning != null) {
        // Calcola la settimana corrente per biweekly
        _selectedWeekLabel = planning.computeWeekLabel(DateTime.now());
        // Carica gli slot dal template selezionato
        _loadSlotsFromPlanning(planning, _selectedWeekLabel);
      } else {
        _weeklySelections = {for (int d = 1; d <= 7; d++) d: <int>{}};
        _savedWeeklySelections = {for (int d = 1; d <= 7; d++) d: <int>{}};
      }
    });
  }

  /// Callback quando viene cambiato il template A/B
  void _onTemplateChanged(WeekLabel label) {
    if (_selectedPlanning == null) return;
    setState(() {
      _selectedWeekLabel = label;
      _loadSlotsFromPlanning(_selectedPlanning!, label);
    });
  }

  /// Carica gli slot dall'apposito template del planning
  void _loadSlotsFromPlanning(StaffPlanning planning, WeekLabel label) {
    final template = label == WeekLabel.a
        ? planning.templateA
        : planning.templateB;
    if (template != null) {
      _weeklySelections = {
        for (int d = 1; d <= 7; d++)
          d: Set<int>.from(template.daySlots[d] ?? {}),
      };
      _savedWeeklySelections = {
        for (int d = 1; d <= 7; d++)
          d: Set<int>.from(template.daySlots[d] ?? {}),
      };
    } else {
      _weeklySelections = {for (int d = 1; d <= 7; d++) d: <int>{}};
      _savedWeeklySelections = {for (int d = 1; d <= 7; d++) d: <int>{}};
    }
  }

  /// Salva il planning corrente tramite API
  Future<void> _savePlanning(WidgetRef ref, int minutesPerSlot) async {
    if (_selectedPlanning == null || _selectedStaffId == null) {
      return;
    }

    // Unifica le fasce orarie contigue
    final currentSchedule = WeeklySchedule.fromSlots(
      _weeklySelections,
      minutesPerSlot: minutesPerSlot,
    );
    final mergedSchedule = currentSchedule.mergeContiguousShifts();
    final mergedSlots = mergedSchedule.toSlots(minutesPerSlot: minutesPerSlot);

    // Aggiorna stato locale
    setState(() {
      _weeklySelections = mergedSlots;
    });

    // Aggiorna il template nel planning
    final oldTemplate = _selectedWeekLabel == WeekLabel.a
        ? _selectedPlanning!.templateA
        : _selectedPlanning!.templateB;

    final newTemplate = StaffPlanningWeekTemplate(
      id: oldTemplate?.id ?? 0,
      staffPlanningId: _selectedPlanning!.id,
      weekLabel: _selectedWeekLabel,
      daySlots: {
        for (final e in mergedSlots.entries) e.key: Set<int>.from(e.value),
      },
    );

    // Crea nuova lista template
    final newTemplates =
        _selectedPlanning!.templates
            .where((t) => t.weekLabel != _selectedWeekLabel)
            .toList()
          ..add(newTemplate);

    final updatedPlanning = _selectedPlanning!.copyWith(
      templates: newTemplates,
    );

    // Salva tramite API
    final notifier = ref.read(staffPlanningsProvider.notifier);
    final result = await notifier.updatePlanning(
      updatedPlanning,
      _selectedPlanning!,
    );

    if (result.isValid) {
      setState(() {
        _selectedPlanning = updatedPlanning;
        _savedWeeklySelections = {
          for (final e in mergedSlots.entries) e.key: Set<int>.from(e.value),
        };
      });
    } else {
      // Mostra errore
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: result.errors.join('\n'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(layoutConfigProvider);
    final availabilityByStaff = ref.watch(staffAvailabilityByStaffProvider);
    final canManageStaff = ref.watch(currentUserCanManageStaffProvider);
    // Usa lo staff filtrato per la location selezionata nella sezione staff
    final staffList = ref.watch(staffForStaffSectionProvider);

    // If a staffId was requested from another screen, pre-select it once
    final requested = ref.read(initialStaffToEditProvider).value;
    if (_selectedStaffId == null && requested != null && staffList.isNotEmpty) {
      // Usa addPostFrameCallback per evitare setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedStaffId == null) {
          _switchStaff(requested);
          ref.read(initialStaffToEditProvider).value = null;
        }
      });
    }

    // Imposta staff iniziale se non selezionato
    if (_selectedStaffId == null && staffList.isNotEmpty) {
      // Usa addPostFrameCallback per evitare setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedStaffId == null) {
          _switchStaff(staffList.first.id);
        }
      });
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: context.l10n.weeklyScheduleTitle),
              Tab(text: context.l10n.exceptionsTitle),
            ],
          ),
        ),
        body: LocalLoadingOverlay(
          isLoading: isSaving,
          child: Column(
            children: [
              // ── Toolbar azioni ───────────────────────────────
              // Toolbar con selezione staff, planning e salvataggio
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
                      onSelected: (staffId) => _switchStaff(
                        staffId,
                        updateWeeklyState: _tabController.index == 0,
                      ),
                    ),
                    // Planning selector (solo nella tab orario settimanale)
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index != 0 ||
                            _selectedStaffId == null) {
                          return const SizedBox.shrink();
                        }
                        return StaffPlanningSelector(
                          staffId: _selectedStaffId!,
                          selectedPlanningId: _selectedPlanning?.id,
                          onPlanningSelected: _onPlanningSelected,
                          onTemplateChanged: _onTemplateChanged,
                          readOnly: !canManageStaff,
                        );
                      },
                    ),
                    // Mostra pulsante salva solo nella tab orario settimanale
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index != 0) {
                          return const SizedBox.shrink();
                        }
                        return FilledButton(
                          onPressed:
                              (_selectedStaffId == null ||
                                  _selectedPlanning == null ||
                                  isSaving ||
                                  !canManageStaff)
                              ? null
                              : () => _savePlanning(ref, layout.minutesPerSlot),
                          child: Text(context.l10n.availabilitySave),
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
                    _buildWeeklyScheduleTab(layout, canManageStaff),
                    // Tab 2: Calendario eccezioni
                    if (_selectedStaffId != null)
                      SingleChildScrollView(
                        child: ExceptionCalendarView(
                          staffId: _selectedStaffId!,
                          readOnly: !canManageStaff,
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Costruisce il tab dell'editor settimanale.
  Widget _buildWeeklyScheduleTab(dynamic layout, bool canManageStaff) {
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
                  readOnly: !canManageStaff,
                  onChanged: canManageStaff ? (newSchedule) {
                    final newSlots = newSchedule.toSlots(
                      minutesPerSlot: layout.minutesPerSlot,
                    );
                    setState(() {
                      _weeklySelections = newSlots;
                    });
                  } : null,
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
                StaffCircleAvatar(
                  height: 28,
                  color: selectedStaff.color,
                  isHighlighted: false,
                  initials: selectedStaff.initials,
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
