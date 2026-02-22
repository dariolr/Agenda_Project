/*
──────────────────────────────────────────────
🎯 Staff Planning Screen - Gestione Planning Disponibilità
──────────────────────────────────────────────

FLUSSO:
1. Seleziona staff dal dropdown
2. Vedi LISTA planning (evidenziato quello attivo oggi)
3. Click su planning → Editor completo (tipo, date, orari)
4. "+" per aggiungere nuovo planning

*/

import 'package:agenda_backend/app/theme/extensions.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/widgets/adaptive_dropdown.dart';
import 'package:agenda_backend/core/widgets/staff_picker_sheet.dart';
import 'package:agenda_backend/features/staff/presentation/dialogs/planning_editor_dialog.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StaffPlanningScreen extends ConsumerStatefulWidget {
  const StaffPlanningScreen({super.key, this.initialStaffId});

  final int? initialStaffId;

  @override
  ConsumerState<StaffPlanningScreen> createState() =>
      _StaffPlanningScreenState();
}

class _StaffPlanningScreenState extends ConsumerState<StaffPlanningScreen> {
  int? _selectedStaffId;
  bool _initialSelectionDone = false;
  int? _selectedYear;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStaffId != null) {
      _selectedStaffId = widget.initialStaffId;
      _loadPlannings(widget.initialStaffId!);
    }
  }

  Future<void> _loadPlannings(int staffId) async {
    setState(() => _isLoading = true);
    await ref
        .read(staffPlanningsProvider.notifier)
        .loadPlanningsForStaff(staffId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onStaffSelected(int staffId) {
    setState(() => _selectedStaffId = staffId);
    _loadPlannings(staffId);
  }

  Future<void> _addPlanning() async {
    if (_selectedStaffId == null) return;

    // Passa i plannings esistenti per calcolare la data inizio
    final planningsMap = ref.read(staffPlanningsProvider);
    final existingPlannings =
        planningsMap[_selectedStaffId] ?? <StaffPlanning>[];

    final result = await showPlanningEditorDialog(
      context,
      ref,
      staffId: _selectedStaffId!,
      existingPlannings: existingPlannings,
    );

    if (result == true) {
      // Ricarica la lista
      _loadPlannings(_selectedStaffId!);
    }
  }

  Future<void> _editPlanning(StaffPlanning planning) async {
    final result = await showPlanningEditorDialog(
      context,
      ref,
      staffId: planning.staffId,
      planning: planning,
    );

    if (result == true) {
      // Ricarica la lista
      _loadPlannings(planning.staffId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final staffList = ref.watch(staffForStaffSectionProvider);
    final planningsMap = ref.watch(staffPlanningsProvider);

    // Auto-select first staff if none selected
    if (!_initialSelectionDone &&
        _selectedStaffId == null &&
        staffList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onStaffSelected(staffList.first.id);
        _initialSelectionDone = true;
      });
    }

    final selectedStaff = staffList
        .where((s) => s.id == _selectedStaffId)
        .firstOrNull;
    final allPlannings = _selectedStaffId != null
        ? (planningsMap[_selectedStaffId] ?? <StaffPlanning>[])
        : <StaffPlanning>[];

    // Calcola anni coperti dai planning
    final currentYear = DateTime.now().year;
    final yearsSet = <int>{currentYear}; // Includi sempre anno corrente
    for (final p in allPlannings) {
      yearsSet.add(p.validFrom.year);
      if (p.validTo != null) {
        yearsSet.add(p.validTo!.year);
      }
    }
    final availableYears = yearsSet.toList()
      ..sort((a, b) => b.compareTo(a)); // Decrescente

    // Imposta anno corrente di default se non selezionato
    final effectiveYear = _selectedYear ?? currentYear;

    // Filtra planning per anno selezionato
    // Un planning "cade dentro un anno" se:
    // validFrom.year <= anno E (validTo == null OR validTo.year >= anno)
    bool planningInYear(StaffPlanning p, int year) {
      if (p.validFrom.year > year) return false;
      if (p.validTo == null) return true;
      return p.validTo!.year >= year;
    }

    final filteredPlannings = allPlannings
        .where((p) => planningInYear(p, effectiveYear))
        .toList();

    // Ordina per data inizio, poi data fine
    int comparePlannings(StaffPlanning a, StaffPlanning b) {
      final cmp = a.validFrom.compareTo(b.validFrom);
      if (cmp != 0) return cmp;
      // Se validTo è null, va dopo
      if (a.validTo == null && b.validTo == null) return 0;
      if (a.validTo == null) return 1;
      if (b.validTo == null) return -1;
      return a.validTo!.compareTo(b.validTo!);
    }

    filteredPlannings.sort(comparePlannings);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_selectedStaffId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Material(
                elevation: 0,
                color: theme.colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _addPlanning,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 22,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.planningListAdd,
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Staff Selector ──
          _StaffSelector(
            staffList: staffList,
            selectedStaff: selectedStaff,
            onSelected: _onStaffSelected,
          ),

          const Divider(height: 1),

          // ── Planning List ──
          Expanded(
            child: _selectedStaffId == null
                ? Center(
                    child: Text(
                      l10n.selectStaffTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPlannings.isEmpty && allPlannings.isEmpty
                ? _EmptyState(onAdd: _addPlanning)
                : _PlanningList(
                    plannings: filteredPlannings,
                    availableYears: availableYears,
                    selectedYear: effectiveYear,
                    onYearChanged: (year) =>
                        setState(() => _selectedYear = year),
                    onEdit: _editPlanning,
                    onAdd: _addPlanning,
                  ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Staff Selector Widget
// ──────────────────────────────────────────────
class _StaffSelector extends ConsumerWidget {
  const _StaffSelector({
    required this.staffList,
    required this.selectedStaff,
    required this.onSelected,
  });

  final List<Staff> staffList;
  final Staff? selectedStaff;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () async {
          final selectedId = await showStaffPickerSheet(
            context: context,
            ref: ref,
            staff: staffList,
            selectedId: selectedStaff?.id,
          );
          if (selectedId != null) {
            onSelected(selectedId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (selectedStaff != null) ...[
                StaffCircleAvatar(
                  height: 36,
                  color: selectedStaff!.color,
                  isHighlighted: false,
                  initials: selectedStaff!.initials,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStaff!.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        l10n.selectStaffTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.selectStaffTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Empty State Widget
// ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.planningListEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi un planning per definire gli orari di lavoro',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.planningListAdd),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Planning List Widget
// ──────────────────────────────────────────────
class _PlanningList extends ConsumerStatefulWidget {
  const _PlanningList({
    required this.plannings,
    required this.availableYears,
    required this.selectedYear,
    required this.onYearChanged,
    required this.onEdit,
    required this.onAdd,
  });

  final List<StaffPlanning> plannings;
  final List<int> availableYears;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<StaffPlanning> onEdit;
  final VoidCallback onAdd;

  @override
  ConsumerState<_PlanningList> createState() => _PlanningListState();
}

class _PlanningListState extends ConsumerState<_PlanningList> {
  bool _isHovered = false;

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

    return Column(
      children: [
        // Filtro anno
        if (widget.availableYears.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                AdaptiveDropdown<int>(
                  items: widget.availableYears.map((year) {
                    return AdaptiveDropdownItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  selectedValue: widget.selectedYear,
                  onSelected: widget.onYearChanged,
                  modalTitle: 'Anno',
                  useRootNavigator: true,
                  onOpened: () => setState(() => _isHovered = true),
                  onClosed: () => setState(() => _isHovered = false),
                  popupWidth: 100,
                  child: MouseRegion(
                    onEnter: (_) {
                      if (!_isHovered) setState(() => _isHovered = true);
                    },
                    onExit: (_) {
                      if (_isHovered) setState(() => _isHovered = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.selectedYear.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
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
                ),
                const Spacer(),
              ],
            ),
          ),

        // Lista planning
        Expanded(
          child: widget.plannings.isEmpty
              ? Center(
                  child: Text(
                    'Nessun planning per ${widget.selectedYear}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.plannings.length,
                  itemBuilder: (context, index) {
                    final planning = widget.plannings[index];
                    return _PlanningCard(
                      planning: planning,
                      onTap: () => widget.onEdit(planning),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Planning Card Widget
// ──────────────────────────────────────────────
class _PlanningCard extends StatelessWidget {
  const _PlanningCard({required this.planning, required this.onTap});

  final StaffPlanning planning;
  final VoidCallback onTap;

  /// Calcola minuti settimanali da un template.
  int _calculateWeeklyMinutes(
    StaffPlanningWeekTemplate? template, {
    int minutesPerSlot = 15,
  }) {
    if (template == null) return 0;
    int totalMinutes = 0;
    for (final daySlots in template.daySlots.values) {
      totalMinutes += daySlots.length * minutesPerSlot;
    }
    return totalMinutes;
  }

  String _formatDuration(BuildContext context, int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return context.l10n.hoursHoursOnly(h);
    return context.l10n.hoursMinutesCompact(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final today = DateTime.now();
    final isActive = planning.isValidForDate(today);
    final isExpired =
        planning.validTo != null && planning.validTo!.isBefore(today);
    final isFuture = planning.validFrom.isAfter(today);
    final dateFormat = DateFormat('d MMM yyyy', 'it');

    // Calcola stato
    String status;
    Color statusColor;
    if (isActive) {
      status = 'Attivo';
      statusColor = theme.colorScheme.primary;
    } else if (isFuture) {
      status = 'Futuro';
      statusColor = theme.colorScheme.tertiary;
    } else {
      status = 'Scaduto';
      statusColor = theme.colorScheme.onSurfaceVariant;
    }

    // Calcola ore settimanali (serve prima per determinare il tipo label)
    final minutesA = _calculateWeeklyMinutes(
      planning.templateA,
      minutesPerSlot: planning.planningSlotMinutes,
    );
    final minutesB = _calculateWeeklyMinutes(
      planning.templateB,
      minutesPerSlot: planning.planningSlotMinutes,
    );
    final totalMinutes = minutesA + minutesB;

    // Tipo planning: se 0 ore mostra "Non disponibile"
    final String typeLabel;
    final IconData typeIcon;
    if (totalMinutes == 0) {
      typeLabel = l10n.planningTypeUnavailable;
      typeIcon = Icons.event_busy_outlined;
    } else if (planning.type == StaffPlanningType.weekly) {
      typeLabel = l10n.planningTypeWeekly;
      typeIcon = Icons.view_week_outlined;
    } else {
      typeLabel = l10n.planningTypeBiweekly;
      typeIcon = Icons.date_range_outlined;
    }

    // Periodo validità
    final validFromStr = dateFormat.format(planning.validFrom);
    final validityText = planning.validTo != null
        ? l10n.planningValidFromTo(
            validFromStr,
            dateFormat.format(planning.validTo!),
          )
        : l10n.planningValidFromOnly(validFromStr);

    String hoursText;
    if (planning.type == StaffPlanningType.weekly) {
      hoursText = l10n.planningWeeklyDuration(
        _formatDuration(context, minutesA),
      );
    } else {
      hoursText = l10n.planningBiweeklyDuration(
        _formatDuration(context, minutesA),
        _formatDuration(context, minutesB),
        _formatDuration(context, totalMinutes),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: isExpired ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: tipo + stato
                Row(
                  children: [
                    Icon(
                      typeIcon,
                      size: 20,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive ? theme.colorScheme.primary : null,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Periodo validità - "Valida dal ... al ..."
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: planning.validTo != null
                          ? Text(
                              validityText,
                              style: theme.textTheme.bodyMedium,
                            )
                          : Row(
                              children: [
                                Text(
                                  validityText,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.all_inclusive,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.planningOpenEnded,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Ore settimanali
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hoursText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
