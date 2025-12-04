import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/date_time_formats.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/time_block.dart';
import '../../../../core/widgets/app_buttons.dart';
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
  await showDialog(
    context: context,
    builder: (_) => _AddBlockDialog(
      initial: initial,
      initialDate: date,
      initialTime: time,
      initialStaffId: initialStaffId,
    ),
  );
}

class _AddBlockDialog extends ConsumerStatefulWidget {
  const _AddBlockDialog({
    this.initial,
    this.initialDate,
    this.initialTime,
    this.initialStaffId,
  });

  final TimeBlock? initial;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialStaffId;

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

    final title = isEdit ? l10n.blockDialogTitleEdit : l10n.blockDialogTitleNew;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data
              _LabeledField(
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
                      child: _LabeledField(
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
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
                      child: _LabeledField(
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
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
              _LabeledField(
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
                          final isSelected = _selectedStaffIds.contains(
                            member.id,
                          );
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
              _LabeledField(
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
          ),
        ),
      ),
      actions: [
        if (isEdit)
          AppDangerButton(onPressed: _onDelete, child: Text(l10n.actionDelete)),
        AppOutlinedActionButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppFilledButton(onPressed: _onSave, child: Text(l10n.actionSave)),
      ],
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
    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return _TimeGridPicker(
          initial: isStart ? _startTime : _endTime,
          stepMinutes: step,
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
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
  late ScrollController _scrollController;
  late List<TimeOfDay> _entries;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Genera le entries
    _entries = [];
    for (int m = 0; m < LayoutConfig.hoursInDay * 60; m += widget.stepMinutes) {
      final h = m ~/ 60;
      final mm = m % 60;
      _entries.add(TimeOfDay(hour: h, minute: mm));
    }

    // Trova l'indice dell'orario selezionato
    _selectedIndex = _entries.indexWhere(
      (t) => t.hour == widget.initial.hour && t.minute == widget.initial.minute,
    );
    if (_selectedIndex < 0) _selectedIndex = 0;

    // Scrolla all'elemento dopo il build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    // Calcola la posizione dello scroll
    // GridView con 4 colonne, ogni riga ha altezza circa 40px (childAspectRatio 2.7)
    const crossAxisCount = 4;
    const itemHeight = 40.0; // Altezza approssimativa di ogni cella
    const spacing = 6.0;

    final row = _selectedIndex ~/ crossAxisCount;
    final targetOffset = row * (itemHeight + spacing);

    // Centra la riga selezionata nella vista (300px di altezza)
    final centeredOffset = (targetOffset - 130).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      centeredOffset,
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
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(
              height: 300,
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
                  final isSelected = index == _selectedIndex;
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
