import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/business_closure.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/business/providers/business_closures_provider.dart';

/// Dialog per creare o modificare una chiusura business
class BusinessClosureDialog extends ConsumerStatefulWidget {
  final BusinessClosure? closure;

  const BusinessClosureDialog({super.key, this.closure});

  static Future<bool?> show(BuildContext context, {BusinessClosure? closure}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BusinessClosureDialog(closure: closure),
    );
  }

  @override
  ConsumerState<BusinessClosureDialog> createState() =>
      _BusinessClosureDialogState();
}

class _BusinessClosureDialogState extends ConsumerState<BusinessClosureDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  bool get isEditing => widget.closure != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate =
        widget.closure?.startDate ?? DateTime(now.year, now.month, now.day);
    _endDate =
        widget.closure?.endDate ?? DateTime(now.year, now.month, now.day);
    _reasonController = TextEditingController(
      text: widget.closure?.reason ?? '',
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        // Se la data fine è prima della nuova data inizio, aggiornala
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validazione date
    if (_endDate.isBefore(_startDate)) {
      FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.closuresInvalidDateRange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(businessClosuresProvider.notifier);

      if (isEditing) {
        await notifier.updateClosure(
          closureId: widget.closure!.id,
          startDate: _startDate,
          endDate: _endDate,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        );
      } else {
        await notifier.addClosure(
          startDate: _startDate,
          endDate: _endDate,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        FeedbackDialog.showSuccess(
          context,
          title: isEditing
              ? context.l10n.closuresUpdateSuccess
              : context.l10n.closuresAddSuccess,
          message: '',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Gestisci errore overlap
        if (errorMessage.contains('409') ||
            errorMessage.toLowerCase().contains('overlap')) {
          errorMessage = context.l10n.closuresOverlapError;
        }
        FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );

    final durationDays = _endDate.difference(_startDate).inDays + 1;

    return AlertDialog(
      title: Text(isEditing ? l10n.closuresEditTitle : l10n.closuresNewTitle),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker row
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: l10n.closuresStartDate,
                      value: _startDate,
                      dateFormat: dateFormat,
                      onTap: _selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DatePickerField(
                      label: l10n.closuresEndDate,
                      value: _endDate,
                      dateFormat: dateFormat,
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Duration info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.closuresDays(durationDays),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reason field
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: l10n.closuresReason,
                  hintText: l10n.closuresReasonHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppAsyncFilledButton(
          onPressed: _isSaving ? null : _onSave,
          isLoading: _isSaving,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateFormat.format(value), style: theme.textTheme.bodyLarge),
            Icon(
              Icons.calendar_month,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
