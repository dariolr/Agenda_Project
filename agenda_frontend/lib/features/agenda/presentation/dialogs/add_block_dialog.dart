import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_frontend/core/widgets/labeled_form_field.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/date_time_formats.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/time_block.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/config/layout_config.dart';
import '../../providers/date_range_provider.dart';
import '../../providers/layout_config_provider.dart';
import '../../providers/time_blocks_provider.dart';

/// Mostra il dialog per creare o modificare un blocco di non disponibilità.
Future<void> showAddBlockDialog(
  BuildContext context,
  WidgetRef ref, {
  TimeBlock? initial,
  DateTime? date,
  TimeOfDay? time,
  int? initialStaffId,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _AddBlockDialog(
    initial: initial,
    initialDate: date,
    initialTime: time,
    initialStaffId: initialStaffId,
    presentation: isDesktop
        ? _BlockDialogPresentation.dialog
        : _BlockDialogPresentation.bottomSheet,
  );

  if (isDesktop) {
    await showDialog(context: context, builder: (_) => dialog);
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      builder: (_) => dialog,
    );
  }
}

enum _BlockDialogPresentation { dialog, bottomSheet }

class _AddBlockDialog extends ConsumerStatefulWidget {
  const _AddBlockDialog({
    this.initial,
    this.initialDate,
    this.initialTime,
    this.initialStaffId,
    required this.presentation,
  });

  final TimeBlock? initial;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialStaffId;
  final _BlockDialogPresentation presentation;

  @override
  ConsumerState<_AddBlockDialog> createState() => _AddBlockDialogState();
}

class _AddBlockDialogState extends ConsumerState<_AddBlockDialog> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Set<int> _selectedStaffIds;
  final _reasonController = TextEditingController();
  bool _isAllDay = false;
  String? _staffError;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final agendaDate = ref.read(agendaDateProvider);

    if (widget.initial != null) {
      final block = widget.initial!;
      _date = DateTime(
        block.startTime.year,
        block.startTime.month,
        block.startTime.day,
      );
      _startTime = TimeOfDay(
        hour: block.startTime.hour,
        minute: block.startTime.minute,
      );
      _endTime = TimeOfDay(
        hour: block.endTime.hour,
        minute: block.endTime.minute,
      );
      _selectedStaffIds = Set.from(block.staffIds);
      _reasonController.text = block.reason ?? '';
      _isAllDay = block.isAllDay;
    } else {
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);
      _startTime = widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
      _endTime = TimeOfDay(
        hour: _startTime.hour + 1,
        minute: _startTime.minute,
      );
      _selectedStaffIds = widget.initialStaffId != null
          ? {widget.initialStaffId!}
          : {};
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.initial != null;
    final staff = ref.watch(staffForCurrentLocationProvider);
    final isDialog = widget.presentation == _BlockDialogPresentation.dialog;

    final title = isEdit ? l10n.blockDialogTitleEdit : l10n.blockDialogTitleNew;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data
        LabeledFormField(
          label: l10n.formDate,
          child: InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                  ),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Giornata intera switch
        Row(
          children: [
            Switch(
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
            ),
            const SizedBox(width: 8),
            Text(l10n.blockAllDay),
          ],
        ),
        const SizedBox(height: 12),

        // Orari
        if (!_isAllDay) ...[
          Row(
            children: [
              Expanded(
                child: LabeledFormField(
                  label: l10n.blockStartTime,
                  child: InkWell(
                    onTap: () => _pickTime(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: null,
                        enabledBorder: _timeError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_startTime.format(context)),
                          const Icon(Icons.schedule, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledFormField(
                  label: l10n.blockEndTime,
                  child: InkWell(
                    onTap: () => _pickTime(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: _timeError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_endTime.format(context)),
                          const Icon(Icons.schedule, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_timeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _timeError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],

        // Staff selection
        LabeledFormField(
          label: l10n.blockSelectStaff,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _staffError != null
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final member = staff[index];
                    final isSelected = _selectedStaffIds.contains(member.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          _staffError = null;
                          if (v == true) {
                            _selectedStaffIds.add(member.id);
                          } else {
                            _selectedStaffIds.remove(member.id);
                          }
                        });
                      },
                      title: Text(member.name),
                      secondary: CircleAvatar(
                        backgroundColor: member.color,
                        radius: 12,
                      ),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              if (_staffError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    _staffError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Motivo opzionale
        LabeledFormField(
          label: l10n.blockReason,
          child: TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: l10n.blockReasonHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );

    final actions = [
      if (isEdit)
        AppDangerButton(
          onPressed: _onDelete,
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(l10n.actionDelete),
        ),
      AppOutlinedActionButton(
        onPressed: () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    if (isDialog) {
      return DismissibleDialog(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Flexible(child: SingleChildScrollView(child: content)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isEdit) ...[
                        bottomActions.first, // Delete button
                        const Spacer(),
                        bottomActions[1], // Cancel button
                      ] else
                        bottomActions[0], // Cancel button
                      const SizedBox(width: 8),
                      bottomActions.last, // Save button
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            content,
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: bottomActions,
              ),
            ),
            SizedBox(height: 32 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final step = ref.read(layoutConfigProvider).minutesPerSlot;
    final selected = await AppBottomSheet.show<TimeOfDay>(
      context: context,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.9;
        return SizedBox(
          height: height,
          child: _TimeGridPicker(
            initial: isStart ? _startTime : _endTime,
            stepMinutes: step,
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _timeError = null; // Reset errore quando l'utente modifica
        if (isStart) {
          _startTime = selected;
          // Aggiusta automaticamente l'end time se necessario
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = selected;
        }
      });
    }
  }

  void _onSave() {
    final l10n = context.l10n;
    bool hasError = false;

    // Reset errori
    setState(() {
      _staffError = null;
      _timeError = null;
    });

    if (_selectedStaffIds.isEmpty) {
      setState(() => _staffError = l10n.blockSelectStaffError);
      hasError = true;
    }

    // Validazione orari
    if (!_isAllDay) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      if (endMinutes <= startMinutes) {
        setState(() => _timeError = l10n.blockTimeError);
        hasError = true;
      }
    }

    if (hasError) return;

    final DateTime startDateTime;
    final DateTime endDateTime;

    if (_isAllDay) {
      // Per blocchi giornata intera, usa l'intera giornata lavorativa
      startDateTime = DateTime(_date.year, _date.month, _date.day, 0, 0);
      endDateTime = DateTime(_date.year, _date.month, _date.day, 23, 59);
    } else {
      startDateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _startTime.hour,
        _startTime.minute,
      );
      endDateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _endTime.hour,
        _endTime.minute,
      );
    }

    final reason = _reasonController.text.trim().isEmpty
        ? null
        : _reasonController.text.trim();

    if (widget.initial == null) {
      // Nuovo blocco
      ref
          .read(timeBlocksProvider.notifier)
          .addBlock(
            staffIds: _selectedStaffIds.toList(),
            startTime: startDateTime,
            endTime: endDateTime,
            reason: reason,
            isAllDay: _isAllDay,
          );
    } else {
      // Aggiorna blocco esistente
      final updated = widget.initial!.copyWith(
        staffIds: _selectedStaffIds.toList(),
        startTime: startDateTime,
        endTime: endDateTime,
        reason: reason,
        isAllDay: _isAllDay,
      );
      ref.read(timeBlocksProvider.notifier).updateBlock(updated);
    }

    Navigator.of(context).pop();
  }

  void _onDelete() {
    if (widget.initial != null) {
      ref.read(timeBlocksProvider.notifier).deleteBlock(widget.initial!.id);
      Navigator.of(context).pop();
    }
  }
}

class _TimeGridPicker extends StatefulWidget {
  const _TimeGridPicker({required this.initial, required this.stepMinutes});
  final TimeOfDay initial;
  final int stepMinutes;

  @override
  State<_TimeGridPicker> createState() => _TimeGridPickerState();
}

class _TimeGridPickerState extends State<_TimeGridPicker> {
  late final ScrollController _scrollController;
  late final List<TimeOfDay?> _entries;
  late final int _scrollToIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Genera la lista degli orari con 4 colonne per riga
    _entries = <TimeOfDay?>[];
    for (int m = 0; m < LayoutConfig.hoursInDay * 60; m += widget.stepMinutes) {
      final h = m ~/ 60;
      final mm = m % 60;
      _entries.add(TimeOfDay(hour: h, minute: mm));
    }

    // Verifica se l'orario iniziale è già nella lista
    int exactIndex = _entries.indexWhere(
      (t) =>
          t != null &&
          t.hour == widget.initial.hour &&
          t.minute == widget.initial.minute,
    );

    if (exactIndex >= 0) {
      // L'orario è già presente
      _scrollToIndex = exactIndex;
    } else {
      // L'orario non è presente: inserisci una NUOVA RIGA con l'orario
      // nella colonna corretta e le altre colonne vuote
      final columnsPerRow = 60 ~/ widget.stepMinutes;
      final targetColumn = widget.initial.minute ~/ widget.stepMinutes;
      final baseIndex = (widget.initial.hour + 1) * columnsPerRow;

      // Crea la nuova riga con 4 elementi (solo uno valorizzato)
      final newRow = List<TimeOfDay?>.filled(columnsPerRow, null);
      newRow[targetColumn] = widget.initial;

      // Inserisci la nuova riga
      final insertIndex = baseIndex.clamp(0, _entries.length);
      _entries.insertAll(insertIndex, newRow);

      // L'indice dell'orario selezionato è la posizione nella nuova riga
      _scrollToIndex = insertIndex + targetColumn;
    }

    // Scroll all'orario dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    const crossAxisCount = 4;
    const mainAxisSpacing = 6.0;
    const childAspectRatio = 2.7;
    const padding = 12.0;

    // Usa la larghezza effettiva del context
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - padding * 2;
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * 6) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final rowHeight = itemHeight + mainAxisSpacing;

    // Calcola la riga dell'elemento target
    final targetRow = _scrollToIndex ~/ crossAxisCount;

    // Calcola l'offset per centrare la riga target
    final viewportHeight = _scrollController.position.viewportDimension;
    // Offset aggiuntivo per centrare meglio (compensa header visivo)
    const headerOffset = 40.0;
    final targetOffset =
        (targetRow * rowHeight) -
        (viewportHeight / 2) +
        (rowHeight / 2) +
        headerOffset;

    // Limita l'offset ai bounds dello scroll
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Text(
                  MaterialLocalizations.of(context).timePickerHourLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.7,
                ),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final t = _entries[index];
                  // Se la cella è vuota, mostra uno spazio vuoto
                  if (t == null) {
                    return const SizedBox.shrink();
                  }
                  // Evidenzia l'orario selezionato
                  final isSelected = index == _scrollToIndex;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : null,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => Navigator.pop(context, t),
                    child: Text(_format(context, t)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(BuildContext ctx, TimeOfDay t) {
    return DtFmt.hm(ctx, t.hour, t.minute);
  }
}
