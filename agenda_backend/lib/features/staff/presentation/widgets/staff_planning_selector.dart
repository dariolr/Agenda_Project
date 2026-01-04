import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/features/staff/presentation/dialogs/staff_planning_dialog.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Widget che mostra la lista dei planning per uno staff e permette di
/// selezionarne uno, crearne uno nuovo o modificare quello esistente.
class StaffPlanningSelector extends ConsumerWidget {
  const StaffPlanningSelector({
    super.key,
    required this.staffId,
    required this.selectedPlanningId,
    required this.onPlanningSelected,
    this.onTemplateChanged,
  });

  final int staffId;
  final int? selectedPlanningId;
  final ValueChanged<StaffPlanning?> onPlanningSelected;

  /// Callback quando viene cambiato il template (A/B) per biweekly
  final ValueChanged<WeekLabel>? onTemplateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannings = ref.watch(planningsForStaffProvider(staffId));
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMd(Intl.getCurrentLocale());

    // Trova il planning selezionato
    final selectedPlanning = selectedPlanningId != null
        ? plannings.where((p) => p.id == selectedPlanningId).firstOrNull
        : null;

    // Determina lo stato del planning (attivo, futuro, passato)
    String getPlanningStatus(StaffPlanning p) {
      final today = DateTime.now();
      if (p.isValidForDate(today)) return l10n.planningActive;
      if (p.validFrom.isAfter(today)) return l10n.planningFuture;
      return l10n.planningPast;
    }

    // Label per il planning
    String getPlanningLabel(StaffPlanning p) {
      final type = p.type == StaffPlanningType.weekly
          ? l10n.planningTypeWeekly
          : l10n.planningTypeBiweekly;
      final from = dateFormat.format(p.validFrom);
      final validity = p.validTo != null
          ? l10n.planningValidityRange(from, dateFormat.format(p.validTo!))
          : l10n.planningValidityFrom(from);
      return '$type • $validity';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dropdown per selezionare planning
        if (plannings.isEmpty)
          OutlinedButton.icon(
            onPressed: () => _createPlanning(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.planningListAdd),
          )
        else
          PopupMenuButton<int?>(
            tooltip: l10n.planningListTitle,
            onSelected: (id) {
              if (id == -1) {
                _createPlanning(context, ref);
              } else {
                final planning = plannings.where((p) => p.id == id).firstOrNull;
                onPlanningSelected(planning);
              }
            },
            itemBuilder: (context) => [
              // Header
              PopupMenuItem<int?>(
                enabled: false,
                child: Text(
                  l10n.planningListTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              // Lista planning
              ...plannings.map(
                (p) => PopupMenuItem<int?>(
                  value: p.id,
                  child: Row(
                    children: [
                      if (p.id == selectedPlanningId)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: theme.colorScheme.primary,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getPlanningLabel(p),
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              getPlanningStatus(p),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: p.isValidForDate(DateTime.now())
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          _editPlanning(context, ref, p);
                        },
                        tooltip: l10n.actionEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              // Aggiungi nuovo
              PopupMenuItem<int?>(
                value: -1,
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.planningListAdd,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
            child: Chip(
              avatar: Icon(
                selectedPlanning?.type == StaffPlanningType.biweekly
                    ? Icons.date_range_outlined
                    : Icons.view_week_outlined,
                size: 18,
              ),
              label: Text(
                selectedPlanning != null
                    ? getPlanningLabel(selectedPlanning)
                    : l10n.planningListEmpty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              deleteIcon: const Icon(Icons.arrow_drop_down, size: 18),
              onDeleted: () {}, // Handled by PopupMenuButton
            ),
          ),

        // Toggle A/B per biweekly
        if (selectedPlanning?.type == StaffPlanningType.biweekly &&
            onTemplateChanged != null) ...[
          const SizedBox(width: 12),
          _WeekLabelToggle(
            planning: selectedPlanning!,
            onChanged: onTemplateChanged!,
          ),
        ],
      ],
    );
  }

  Future<void> _createPlanning(BuildContext context, WidgetRef ref) async {
    final result = await showStaffPlanningDialog(
      context,
      ref,
      staffId: staffId,
    );
    if (result != null) {
      onPlanningSelected(result);
    }
  }

  Future<void> _editPlanning(
    BuildContext context,
    WidgetRef ref,
    StaffPlanning planning,
  ) async {
    final result = await showStaffPlanningDialog(
      context,
      ref,
      staffId: staffId,
      initial: planning,
    );
    if (result != null) {
      onPlanningSelected(result);
    }
  }
}

/// Toggle per selezionare settimana A o B in un planning biweekly
class _WeekLabelToggle extends StatefulWidget {
  const _WeekLabelToggle({required this.planning, required this.onChanged});

  final StaffPlanning planning;
  final ValueChanged<WeekLabel> onChanged;

  @override
  State<_WeekLabelToggle> createState() => _WeekLabelToggleState();
}

class _WeekLabelToggleState extends State<_WeekLabelToggle> {
  late WeekLabel _currentLabel;

  @override
  void initState() {
    super.initState();
    // Calcola la settimana corrente
    _currentLabel = widget.planning.computeWeekLabel(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planningCurrentWeek(_currentLabel == WeekLabel.a ? 'A' : 'B'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        SegmentedButton<WeekLabel>(
          segments: [
            ButtonSegment(value: WeekLabel.a, label: Text(l10n.planningWeekA)),
            ButtonSegment(value: WeekLabel.b, label: Text(l10n.planningWeekB)),
          ],
          selected: {_currentLabel},
          onSelectionChanged: (selection) {
            setState(() => _currentLabel = selection.first);
            widget.onChanged(selection.first);
          },
        ),
      ],
    );
  }
}
