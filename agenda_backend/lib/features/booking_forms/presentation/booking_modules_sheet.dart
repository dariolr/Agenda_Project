import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../../core/widgets/labeled_form_field.dart';
import '../../agenda/providers/business_providers.dart';
import '../domain/booking_form_for_booking.dart';
import '../domain/booking_form_models.dart';
import '../providers/booking_forms_provider.dart';

/// Apre il foglio "Moduli" di una prenotazione (visualizzazione/modifica).
Future<void> showBookingModulesSheet(
  BuildContext context, {
  required int bookingId,
}) {
  return AppForm.show<void>(
    context: context,
    builder: (_) => _BookingModulesSheet(bookingId: bookingId),
  );
}

class _BookingModulesSheet extends ConsumerStatefulWidget {
  const _BookingModulesSheet({required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<_BookingModulesSheet> createState() =>
      _BookingModulesSheetState();
}

class _BookingModulesSheetState extends ConsumerState<_BookingModulesSheet> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<BookingFormForBooking> _forms = const [];

  /// Valore corrente per id campo (String / bool / `List<String>`).
  final Map<int, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final forms = await ref
          .read(bookingFormsRepositoryProvider)
          .getBookingForms(businessId, widget.bookingId);
      if (!mounted) return;
      setState(() {
        _forms = forms;
        _values
          ..clear()
          ..addEntries(forms.expand((f) => f.values.entries));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildSubmissions() {
    final submissions = <Map<String, dynamic>>[];
    for (final form in _forms) {
      final answers = <Map<String, dynamic>>[];
      for (final field in form.fields) {
        if (field.fieldType == 'info_text') continue;
        final value = _values[field.id];
        switch (field.fieldType) {
          case 'multiple_choice':
            if (value is List && value.isNotEmpty) {
              answers.add({'field_id': field.id, 'value': value});
            }
            break;
          case 'checkbox':
          case 'consent':
            if (value == true) {
              answers.add({'field_id': field.id, 'value': true});
            }
            break;
          default:
            if (value is String && value.trim().isNotEmpty) {
              answers.add({'field_id': field.id, 'value': value.trim()});
            }
        }
      }
      submissions.add({'form_id': form.id, 'answers': answers});
    }
    return submissions;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref
          .read(bookingFormsRepositoryProvider)
          .saveBookingForms(businessId, widget.bookingId, _buildSubmissions());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        await FeedbackDialog.showError(
          context,
          title: context.l10n.bookingModulesError,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasForms = !_loading && _error == null && _forms.isNotEmpty;
    return AppFormScaffold(
      isLoading: _saving,
      title: Text(l10n.bookingModulesTitle),
      // Su mobile AppForm.show fornisce già il padding orizzontale del
      // bottom sheet: azzero quello dello scaffold per evitare margini doppi.
      mobileContentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      mobileActionsPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      mobileBottomSpacing: 16,
      content: _buildContent(context),
      actions: hasForms
          ? [
              AppOutlinedActionButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              AppFilledButton(onPressed: _save, child: Text(l10n.actionSave)),
            ]
          : const [],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }
    if (_forms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.bookingModulesEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _forms.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _FormCard(
            form: _forms[i],
            values: _values,
            onChanged: (fieldId, value) =>
                setState(() => _values[fieldId] = value),
          ),
        ],
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.form,
    required this.values,
    required this.onChanged,
  });

  final BookingFormForBooking form;
  final Map<int, dynamic> values;
  final void Function(int fieldId, dynamic value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    form.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (form.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                form.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < form.fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _FieldInput(
                field: form.fields[i],
                value: values[form.fields[i].id],
                onChanged: (value) => onChanged(form.fields[i].id, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final BookingFormField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  String _labelWithRequired(BuildContext context) =>
      field.isRequired ? '${field.label} *' : field.label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (field.fieldType) {
      case 'info_text':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(field.label, style: theme.textTheme.bodyMedium),
        );

      case 'long_text':
        return _textField(context, maxLines: 3);

      case 'date':
        return _dateField(context);

      case 'single_choice':
        return LabeledFormField(
          label: _labelWithRequired(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final option in field.options)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: option['value']!,
                  groupValue: value is String ? value : null,
                  title: Text(option['label'] ?? option['value']!),
                  onChanged: (v) => onChanged(v),
                ),
            ],
          ),
        );

      case 'segmented_choice':
        return LabeledFormField(
          label: _labelWithRequired(context),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final option in field.options)
                  ButtonSegment<String>(
                    value: option['value']!,
                    label: Text(option['label'] ?? option['value']!),
                  ),
              ],
              selected: value is String ? {value} : const <String>{},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) {
                onChanged(selection.isEmpty ? null : selection.first);
              },
            ),
          ),
        );

      case 'multiple_choice':
        final selected = value is List
            ? List<String>.from(value.map((e) => e.toString()))
            : <String>[];
        return LabeledFormField(
          label: _labelWithRequired(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final option in field.options)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: selected.contains(option['value']),
                  title: Text(option['label'] ?? option['value']!),
                  onChanged: (checked) {
                    final next = [...selected];
                    if (checked == true) {
                      next.add(option['value']!);
                    } else {
                      next.remove(option['value']);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        );

      case 'checkbox':
      case 'consent':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _labelWithRequired(context),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            AppSwitch(value: value == true, onChanged: (v) => onChanged(v)),
          ],
        );

      default: // short_text, number, email, phone
        return _textField(context);
    }
  }

  Widget _dateField(BuildContext context) {
    final selected = _parseDateValue(value);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final displayValue = selected == null
        ? ''
        : DateFormat.yMd(locale).format(selected);
    return LabeledFormField(
      label: _labelWithRequired(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: selected ?? now,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked == null) return;
          onChanged(_formatDateValue(picked));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: field.helpText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Text(displayValue),
        ),
      ),
    );
  }

  Widget _textField(BuildContext context, {int maxLines = 1}) {
    return LabeledFormField(
      label: _labelWithRequired(context),
      child: TextFormField(
        initialValue: value is String ? value : '',
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: field.helpText,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

DateTime? _parseDateValue(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  final parts = trimmed.split('-');
  if (parts.length != 3) return DateTime.tryParse(trimmed);
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String _formatDateValue(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
