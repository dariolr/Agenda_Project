import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/core/widgets/app_dialogs.dart';
import 'package:agenda_backend/core/widgets/local_loading_overlay.dart';
import 'package:agenda_backend/core/widgets/labeled_form_field.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Mostra il dialog per creare o modificare un planning.
Future<StaffPlanning?> showStaffPlanningDialog(
  BuildContext context,
  WidgetRef ref, {
  required int staffId,
  StaffPlanning? initial,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _StaffPlanningDialog(
    staffId: staffId,
    initial: initial,
    isDesktop: isDesktop,
  );

  if (isDesktop) {
    return showDialog<StaffPlanning>(context: context, builder: (_) => dialog);
  } else {
    return AppBottomSheet.show<StaffPlanning>(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      builder: (_) => dialog,
    );
  }
}

class _StaffPlanningDialog extends ConsumerStatefulWidget {
  const _StaffPlanningDialog({
    required this.staffId,
    this.initial,
    required this.isDesktop,
  });

  final int staffId;
  final StaffPlanning? initial;
  final bool isDesktop;

  bool get isEditing => initial != null;

  @override
  ConsumerState<_StaffPlanningDialog> createState() =>
      _StaffPlanningDialogState();
}

class _StaffPlanningDialogState extends ConsumerState<_StaffPlanningDialog> {
  late StaffPlanningType _type;
  late DateTime _validFrom;
  DateTime? _validTo;
  bool _isOpenEnded = true;
  bool _isSaving = false;
  String? _error;

  String _translateError(String error) {
    if (error.contains('overlap_error') || error.contains('Sovrapposizione')) {
      return 'Esiste già un planning attivo per questo periodo. '
          'Modifica o elimina il planning esistente prima di crearne uno nuovo.';
    }
    if (error.contains('api_error:')) {
      return error.replaceFirst('api_error: ', '');
    }
    return error;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _type = widget.initial!.type;
      _validFrom = widget.initial!.validFrom;
      _validTo = widget.initial!.validTo;
      _isOpenEnded = widget.initial!.validTo == null;
    } else {
      _type = StaffPlanningType.weekly;
      _validFrom = DateTime.now();
      _validTo = null;
      _isOpenEnded = true;
    }
  }

  Future<void> _pickValidFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _validFrom = picked;
        // Se validTo è prima di validFrom, aggiorna
        if (_validTo != null && _validTo!.isBefore(_validFrom)) {
          _validTo = _validFrom;
        }
      });
    }
  }

  Future<void> _pickValidTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validTo ?? _validFrom,
      firstDate: _validFrom,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _validTo = picked);
    }
  }

  Future<void> _onSave() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final notifier = ref.read(staffPlanningsProvider.notifier);

      // Prepara i template (vuoti per ora, verranno popolati dall'editor)
      final templates = <StaffPlanningWeekTemplate>[
        StaffPlanningWeekTemplate(
          id: widget.initial?.templateA?.id ?? 0,
          staffPlanningId: widget.initial?.id ?? 0,
          weekLabel: WeekLabel.a,
          daySlots: widget.initial?.templateA?.daySlots ?? {},
        ),
        if (_type == StaffPlanningType.biweekly)
          StaffPlanningWeekTemplate(
            id: widget.initial?.templateB?.id ?? 0,
            staffPlanningId: widget.initial?.id ?? 0,
            weekLabel: WeekLabel.b,
            daySlots: widget.initial?.templateB?.daySlots ?? {},
          ),
      ];

      final planning = StaffPlanning(
        id: widget.initial?.id ?? 0,
        staffId: widget.staffId,
        type: _type,
        validFrom: _validFrom,
        validTo: _isOpenEnded ? null : _validTo,
        templates: templates,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      );

      if (widget.isEditing) {
        final result = await notifier.updatePlanning(planning, widget.initial!);
        if (!result.isValid) {
          setState(() => _error = _translateError(result.errors.join('\n')));
          return;
        }
        // Per update, usa il planning locale (l'ID non cambia)
        if (mounted) {
          Navigator.of(context).pop(planning);
        }
      } else {
        final result = await notifier.addPlanning(planning);
        if (!result.isValid) {
          setState(() => _error = _translateError(result.errors.join('\n')));
          return;
        }
        // Per create, usa il planning dal server (con ID corretto)
        if (mounted) {
          Navigator.of(context).pop(result.planning);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _onDelete() async {
    if (widget.initial == null) return;

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
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(staffPlanningsProvider.notifier)
          .deletePlanning(widget.staffId, widget.initial!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(Intl.getCurrentLocale());

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tipo planning
        LabeledFormField(
          label: l10n.planningType,
          child: SegmentedButton<StaffPlanningType>(
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
            onSelectionChanged: (selection) {
              setState(() => _type = selection.first);
            },
          ),
        ),
        const SizedBox(height: 16),

        // Data inizio
        LabeledFormField(
          label: l10n.planningValidFrom,
          child: InkWell(
            onTap: _pickValidFrom,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(dateFormat.format(_validFrom)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Data fine (opzionale)
        LabeledFormField(
          label: l10n.planningValidTo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isOpenEnded,
                    onChanged: (v) {
                      setState(() {
                        _isOpenEnded = v ?? true;
                        if (!_isOpenEnded && _validTo == null) {
                          _validTo = _validFrom.add(const Duration(days: 365));
                        }
                      });
                    },
                  ),
                  Text(l10n.planningOpenEnded),
                ],
              ),
              if (!_isOpenEnded)
                InkWell(
                  onTap: _pickValidTo,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _validTo != null
                          ? dateFormat.format(_validTo!)
                          : l10n.planningSelectDate,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Errore
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    final actions = [
      if (widget.isEditing)
        AppDangerButton(
          onPressed: _isSaving ? null : _onDelete,
          child: Text(l10n.actionDelete),
        ),
      AppOutlinedActionButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _isSaving ? null : _onSave,
        child: Text(l10n.actionSave),
      ),
    ];

    final loadingContent = LocalLoadingOverlay(
      isLoading: _isSaving,
      child: content,
    );

    if (widget.isDesktop) {
      return AppFormDialog(
        title: Text(
          widget.isEditing ? l10n.planningEditTitle : l10n.planningCreateTitle,
        ),
        content: loadingContent,
        actions: actions,
      );
    }

    // Bottom sheet layout
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isEditing ? l10n.planningEditTitle : l10n.planningCreateTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        loadingContent,
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: actions,
        ),
      ],
    );
  }
}
