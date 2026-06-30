import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10_extension.dart';
import '../models/booking_form.dart';

/// Renderer di un singolo campo dinamico di un modulo (booking form).
/// Condiviso tra prenotazione, registrazione e moduli per-cliente.
class BookingFormFieldWidget extends StatelessWidget {
  const BookingFormFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.showRequiredError,
    required this.onChanged,
  });

  final BookingFormField field;
  final dynamic value;
  final bool showRequiredError;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (field.fieldType == 'info_text') {
      return Text(field.label, style: theme.textTheme.bodyMedium);
    }

    final label = field.isRequired
        ? l10n.bookingFormsRequiredLabel(field.label)
        : field.label;
    final errorText = showRequiredError ? l10n.bookingFormsRequiredError : null;

    switch (field.fieldType) {
      case 'long_text':
        return TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            hintText: field.placeholder,
            helperText: field.helpText,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        );
      case 'date':
        return _dateField(context, label, errorText);
      case 'single_choice':
      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: value as String?,
          decoration: InputDecoration(
            labelText: label,
            helperText: field.helpText,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: onChanged,
        );
      case 'segmented_choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final option in field.options)
                    ButtonSegment<String>(
                      value: option.value,
                      label: Text(option.label),
                    ),
                ],
                selected: value is String ? {value} : const <String>{},
                emptySelectionAllowed: true,
                onSelectionChanged: (selection) {
                  onChanged(selection.isEmpty ? null : selection.first);
                },
              ),
            ),
            if (field.helpText != null && field.helpText!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(field.helpText!, style: theme.textTheme.bodySmall),
              ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  errorText,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        );
      case 'multiple_choice':
        final selected = value is Set<String>
            ? value as Set<String>
            : <String>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            for (final option in field.options)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.contains(option.value),
                title: Text(option.label),
                onChanged: (checked) {
                  final next = Set<String>.from(selected);
                  if (checked ?? false) {
                    next.add(option.value);
                  } else {
                    next.remove(option.value);
                  }
                  onChanged(next);
                },
              ),
            if (errorText != null)
              Text(errorText, style: TextStyle(color: theme.colorScheme.error)),
          ],
        );
      case 'consent':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value == true,
                onChanged: (checked) => onChanged(checked ?? false),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.verified_user_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (field.consentUrl != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () => _openConsentUrl(field.consentUrl!),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(field.consentUrl!),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (field.helpText != null &&
                        field.helpText!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(field.helpText!),
                      ),
                    if (errorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorText,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      case 'checkbox':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: value == true,
              title: Text(label),
              subtitle: field.helpText == null ? null : Text(field.helpText!),
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            if (errorText != null)
              Text(errorText, style: TextStyle(color: theme.colorScheme.error)),
          ],
        );
      default:
        return TextField(
          keyboardType: field.fieldType == 'number'
              ? TextInputType.number
              : (field.fieldType == 'email'
                    ? TextInputType.emailAddress
                    : (field.fieldType == 'phone'
                          ? TextInputType.phone
                          : TextInputType.text)),
          decoration: InputDecoration(
            labelText: label,
            hintText: field.placeholder,
            helperText: field.helpText,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        );
    }
  }

  Widget _dateField(BuildContext context, String label, String? errorText) {
    final selected = _parseDateValue(value);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final displayValue = selected == null
        ? ''
        : DateFormat.yMd(locale).format(selected);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
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
          labelText: label,
          helperText: field.helpText,
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Text(displayValue),
      ),
    );
  }
}

/// Utility per validare e serializzare le risposte ai moduli dinamici.
/// Le risposte sono mappate per `field_id`.
class BookingFormAnswers {
  const BookingFormAnswers._();

  static bool hasValue(BookingFormField field, dynamic value) {
    if (field.fieldType == 'checkbox' || field.fieldType == 'consent') {
      return value == true;
    }
    if (field.fieldType == 'multiple_choice') {
      return value is Set<String> && value.isNotEmpty;
    }
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  /// Restituisce gli id dei campi obbligatori non compilati.
  static Set<int> invalidRequired(
    List<BookingForm> forms,
    Map<int, dynamic> answers,
  ) {
    final invalid = <int>{};
    for (final form in forms) {
      for (final field in form.fields) {
        if (!field.isRequired || !field.isInput) continue;
        if (!hasValue(field, answers[field.id])) {
          invalid.add(field.id);
        }
      }
    }
    return invalid;
  }

  /// Costruisce il payload `[{form_id, answers: [{field_id, value}]}]`.
  static List<Map<String, dynamic>> buildSubmissions(
    List<BookingForm> forms,
    Map<int, dynamic> answers,
  ) {
    final submissions = <Map<String, dynamic>>[];
    for (final form in forms) {
      final formAnswers = <Map<String, dynamic>>[];
      for (final field in form.fields) {
        if (!field.isInput) continue;
        final value = answers[field.id];
        if (!hasValue(field, value)) continue;
        formAnswers.add({
          'field_id': field.id,
          'value': value is Set<String> ? value.toList() : value,
        });
      }
      if (formAnswers.isNotEmpty) {
        submissions.add({'form_id': form.id, 'answers': formAnswers});
      }
    }
    return submissions;
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

void _openConsentUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !uri.hasScheme) return;
  unawaited(
    launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    ),
  );
}
