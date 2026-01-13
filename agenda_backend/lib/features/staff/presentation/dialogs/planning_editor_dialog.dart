/*
──────────────────────────────────────────────
🎯 Planning Editor Dialog
──────────────────────────────────────────────

Dialog COMPLETO per creare/modificare un planning:
- Tipo (settimanale/bisettimanale)
- Date validità (da/a)
- Griglia orari settimanali
- Per biweekly: tab A e B

*/

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/theme/app_spacing.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/core/widgets/form_loading_overlay.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/staff/presentation/widgets/weekly_schedule_editor.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Mostra il dialog editor planning.
/// Ritorna true se salvato, false/null se annullato.
/// [existingPlannings] serve per calcolare la data inizio di un nuovo planning.
Future<bool?> showPlanningEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  required int staffId,
  StaffPlanning? planning,
  List<StaffPlanning> existingPlannings = const [],
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final content = _PlanningEditorContent(
    staffId: staffId,
    planning: planning,
    isDesktop: isDesktop,
    existingPlannings: existingPlannings,
  );

  if (isDesktop) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => content,
    );
  } else {
    return AppBottomSheet.show<bool>(
      context: context,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
      builder: (_) => content,
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

class _PlanningEditorContent extends ConsumerStatefulWidget {
  const _PlanningEditorContent({
    required this.staffId,
    this.planning,
    required this.isDesktop,
    this.existingPlannings = const [],
  });

  final int staffId;
  final StaffPlanning? planning;
  final bool isDesktop;
  final List<StaffPlanning> existingPlannings;

  bool get isEditing => planning != null;

  @override
  ConsumerState<_PlanningEditorContent> createState() =>
      _PlanningEditorContentState();
}

class _PlanningEditorContentState extends ConsumerState<_PlanningEditorContent>
    with SingleTickerProviderStateMixin {
  late StaffPlanningType _type;
  late DateTime _validFrom;
  DateTime? _validTo;
  bool _isOpenEnded = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  // Orari per template A e B
  late Map<int, Set<int>> _slotsA;
  late Map<int, Set<int>> _slotsB;

  // Tab controller per biweekly
  TabController? _tabController;
  WeekLabel _currentTab = WeekLabel.a;

  @override
  void initState() {
    super.initState();

    // Inizializza valori da planning esistente o default
    if (widget.planning != null) {
      final p = widget.planning!;
      _type = p.type;
      _validFrom = p.validFrom;
      _validTo = p.validTo;
      _isOpenEnded = p.validTo == null;

      // Carica slot dai template
      _slotsA = _loadSlotsFromTemplate(p.templateA);
      _slotsB = _loadSlotsFromTemplate(p.templateB);
    } else {
      _type = StaffPlanningType.weekly;
      // Data inizio = data fine planning attivo + 1 giorno, altrimenti oggi
      _validFrom = _calculateDefaultStartDate();
      _validTo = null;
      _isOpenEnded = true;
      _slotsA = {for (int d = 1; d <= 7; d++) d: <int>{}};
      _slotsB = {for (int d = 1; d <= 7; d++) d: <int>{}};
    }

    _setupTabController();
  }

  /// Calcola la data inizio default per un nuovo planning:
  /// - Se esiste un planning attivo con validTo → validTo + 1 giorno
  /// - Altrimenti → data attuale
  DateTime _calculateDefaultStartDate() {
    final today = DateTime.now();

    // Cerca il planning attivo (che include oggi) con validTo definita
    for (final p in widget.existingPlannings) {
      if (p.isValidForDate(today) && p.validTo != null) {
        return p.validTo!.add(const Duration(days: 1));
      }
    }

    // Se non c'è planning attivo con fine definita, cerca quello più recente
    DateTime? latestEnd;
    for (final p in widget.existingPlannings) {
      if (p.validTo != null &&
          (latestEnd == null || p.validTo!.isAfter(latestEnd))) {
        latestEnd = p.validTo;
      }
    }

    if (latestEnd != null && latestEnd.isAfter(today)) {
      return latestEnd.add(const Duration(days: 1));
    }

    return today;
  }

  void _setupTabController() {
    _tabController?.dispose();
    if (_type == StaffPlanningType.biweekly) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          setState(() {
            _currentTab = _tabController!.index == 0
                ? WeekLabel.a
                : WeekLabel.b;
          });
        }
      });
    } else {
      _tabController = null;
    }
  }

  Map<int, Set<int>> _loadSlotsFromTemplate(
    StaffPlanningWeekTemplate? template,
  ) {
    if (template == null) {
      return {for (int d = 1; d <= 7; d++) d: <int>{}};
    }
    return {
      for (int d = 1; d <= 7; d++) d: Set<int>.from(template.daySlots[d] ?? {}),
    };
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onTypeChanged(StaffPlanningType? newType) {
    if (newType == null || newType == _type) return;
    setState(() {
      _type = newType;
      _setupTabController();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _validFrom : (_validTo ?? DateTime.now());
    final first = isStart ? DateTime(2020) : _validFrom;
    final last = DateTime(2030);

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: CalendarDatePicker(
            initialDate: initial,
            firstDate: first,
            lastDate: last,
            onDateChanged: (value) => Navigator.of(context).pop(value),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
          // Se fine è prima di inizio, aggiustala
          if (_validTo != null && _validTo!.isBefore(_validFrom)) {
            _validTo = _validFrom;
          }
        } else {
          _validTo = picked;
        }
      });
    }
  }

  void _onSlotsChanged(Map<int, Set<int>> newSlots) {
    setState(() {
      if (_type == StaffPlanningType.weekly || _currentTab == WeekLabel.a) {
        _slotsA = newSlots;
      } else {
        _slotsB = newSlots;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final notifier = ref.read(staffPlanningsProvider.notifier);
      final layout = ref.read(layoutConfigProvider);
      final minutesPerSlot = layout.minutesPerSlot;

      // Unifica slot contigui
      final mergedSlotsA = _mergeSlots(_slotsA, minutesPerSlot);
      final mergedSlotsB = _mergeSlots(_slotsB, minutesPerSlot);

      // Crea template
      final templates = <StaffPlanningWeekTemplate>[
        StaffPlanningWeekTemplate(
          id: widget.planning?.templateA?.id ?? 0,
          staffPlanningId: widget.planning?.id ?? 0,
          weekLabel: WeekLabel.a,
          daySlots: {
            for (final e in mergedSlotsA.entries) e.key: Set<int>.from(e.value),
          },
        ),
        if (_type == StaffPlanningType.biweekly)
          StaffPlanningWeekTemplate(
            id: widget.planning?.templateB?.id ?? 0,
            staffPlanningId: widget.planning?.id ?? 0,
            weekLabel: WeekLabel.b,
            daySlots: {
              for (final e in mergedSlotsB.entries)
                e.key: Set<int>.from(e.value),
            },
          ),
      ];

      final planning = StaffPlanning(
        id: widget.planning?.id ?? 0,
        staffId: widget.staffId,
        type: _type,
        validFrom: _validFrom,
        validTo: _isOpenEnded ? null : _validTo,
        templates: templates,
        createdAt: widget.planning?.createdAt ?? DateTime.now(),
      );

      if (widget.isEditing) {
        final result = await notifier.updatePlanning(
          planning,
          widget.planning!,
        );
        if (!result.isValid) {
          setState(() => _error = _translateError(result.errors.join('\n')));
          return;
        }
      } else {
        final result = await notifier.addPlanning(planning);
        if (!result.isValid) {
          setState(() => _error = _translateError(result.errors.join('\n')));
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<int, Set<int>> _mergeSlots(Map<int, Set<int>> slots, int minutesPerSlot) {
    final schedule = WeeklySchedule.fromSlots(
      slots,
      minutesPerSlot: minutesPerSlot,
    );
    final merged = schedule.mergeContiguousShifts();
    return merged.toSlots(minutesPerSlot: minutesPerSlot);
  }

  String _translateError(String error) {
    if (error.contains('overlap_error') || error.contains('Sovrapposizione')) {
      return 'Esiste già un planning attivo per questo periodo. '
          'Modifica o elimina il planning esistente prima di crearne uno nuovo.';
    }
    if (error.contains('api_error')) {
      return 'Errore di comunicazione con il server. Riprova.';
    }
    return error;
  }

  Future<void> _delete() async {
    if (widget.planning == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.planningDeleteTitle),
        content: Text(context.l10n.planningDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await ref
          .read(staffPlanningsProvider.notifier)
          .deletePlanning(widget.staffId, widget.planning!.id);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy', 'it');
    final isBusy = _isSaving || _isDeleting;

    final currentSlots = _currentTab == WeekLabel.a ? _slotsA : _slotsB;
    final title = widget.isEditing
        ? l10n.planningEditTitle
        : l10n.planningCreateTitle;

    final horizontalPadding = widget.isDesktop ? 24.0 : 16.0;

    // Azioni footer
    final actions = <Widget>[
      // Elimina (solo in modifica)
      if (widget.isEditing)
        TextButton(
          onPressed: _isDeleting || _isSaving ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: Text(l10n.actionDelete),
        ),
      // Annulla
      TextButton(
        onPressed: _isSaving || _isDeleting
            ? null
            : () => Navigator.of(context).pop(false),
        child: Text(l10n.actionCancel),
      ),
      // Salva (senza icona)
      AppFilledButton(
        onPressed: _isSaving || _isDeleting ? null : _save,
        child: Text(l10n.actionSave),
      ),
    ];

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Errore ──
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _error = null),
                  color: theme.colorScheme.onErrorContainer,
                  iconSize: 18,
                ),
              ],
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.formFirstRowSpacing),

                // ── Tipo Planning ──
                Text(
                  l10n.planningType,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<StaffPlanningType>(
                  segments: [
                    ButtonSegment(
                      value: StaffPlanningType.weekly,
                      label: Text(l10n.planningTypeWeekly),
                      icon: const Icon(Icons.view_week_outlined),
                    ),
                    ButtonSegment(
                      value: StaffPlanningType.biweekly,
                      label: Text(l10n.planningTypeBiweekly),
                      icon: const Icon(Icons.date_range_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) => _onTypeChanged(set.first),
                ),

                const SizedBox(height: AppSpacing.formRowSpacing),

                // ── Date Validità ──
                Text(
                  l10n.planningValidFrom,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Data inizio
                InkWell(
                  onTap: () => _pickDate(isStart: true),
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(dateFormat.format(_validFrom)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.formRowSpacing),

                // Data fine
                Text(
                  l10n.planningValidTo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _isOpenEnded
                          ? InputDecorator(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                fillColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                filled: true,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.all_inclusive,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.planningOpenEnded,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: () => _pickDate(isStart: false),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(dateFormat.format(_validTo!)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Pulsante senza scadenza a destra
                Align(
                  alignment: Alignment.centerRight,
                  child: AppOutlinedActionButton(
                    onPressed: () {
                      setState(() {
                        if (_isOpenEnded) {
                          _isOpenEnded = false;
                          _validTo = _validFrom.add(const Duration(days: 30));
                        } else {
                          _isOpenEnded = true;
                          _validTo = null;
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOpenEnded ? Icons.event : Icons.all_inclusive,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOpenEnded
                              ? l10n.planningSetEndDate
                              : l10n.planningOpenEnded,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab per biweekly ──
                if (_type == StaffPlanningType.biweekly) ...[
                  const SizedBox(height: AppSpacing.formRowSpacing),
                  Text(
                    'Settimana',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: l10n.planningWeekA),
                      Tab(text: l10n.planningWeekB),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.formRowSpacing),

                // ── Griglia Orari ──
                WeeklyScheduleEditor(
                  initialSchedule: WeeklySchedule.fromSlots(currentSlots),
                  onChanged: (schedule) {
                    final newSlots = schedule.toSlots();
                    _onSlotsChanged(newSlots);
                  },
                  showHeader: true,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Footer con azioni ──
        Container(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.formFirstRowSpacing,
            horizontalPadding,
            0,
          ),
          child: Row(
            mainAxisAlignment: actions.length == 3
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (widget.isEditing) actions[0],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  actions[widget.isEditing ? 1 : 0],
                  const SizedBox(width: 8),
                  SizedBox(
                    width: AppButtonStyles.dialogButtonWidth,
                    child: actions[widget.isEditing ? 2 : 1],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
      ],
    );
    final loadingContent = FormLoadingOverlay(
      isLoading: isBusy,
      child: content,
    );

    if (widget.isDesktop) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titolo
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                // Contenuto scrollabile
                Flexible(child: loadingContent),
              ],
            ),
          ),
        ),
      );
    }

    // BottomSheet mode
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con titolo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: loadingContent),
        ],
      ),
    );
  }
}
