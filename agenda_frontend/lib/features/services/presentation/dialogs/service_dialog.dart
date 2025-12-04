import 'package:agenda_frontend/features/agenda/providers/business_providers.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../providers/service_categories_provider.dart';
import '../../providers/services_provider.dart';
import '../../utils/service_validators.dart';

enum _AdditionalTimeSelection { none, processing, blocked }

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseColor = textTheme.bodyLarge?.color;
    final titleStyle = enabled
        ? textTheme.bodyLarge
        : textTheme.bodyLarge?.copyWith(color: baseColor?.withOpacity(0.6));
    final subtitleStyle = enabled
        ? textTheme.bodyMedium
        : textTheme.bodyMedium?.copyWith(color: baseColor?.withOpacity(0.6));

    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(subtitle!, style: subtitleStyle),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
                // Forza colore ON al primary anche su Cupertino (verde di default)
                activeColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showServiceDialog(
  BuildContext context,
  WidgetRef ref, {
  Service? service,
  int? preselectedCategoryId,
  bool requireCategorySelection = false,
}) async {
  final notifier = ref.read(servicesProvider.notifier);
  final allServices = ref.read(servicesProvider);
  final categories = ref.read(serviceCategoriesProvider);
  final currencyCode = ref.read(effectiveCurrencyProvider);
  final currencySymbol = NumberFormat.currency(
    name: currencyCode,
  ).currencySymbol;

  final nameController = TextEditingController(text: service?.name ?? '');
  final priceController = TextEditingController(
    text: service?.price != null
        ? PriceFormatter.format(
            context: context,
            amount: service!.price!,
            currencyCode: currencyCode,
          )
        : '',
  );
  final descController = TextEditingController(
    text: service?.description ?? '',
  );

  int? selectedCategory = requireCategorySelection
      ? (service?.categoryId ?? preselectedCategoryId)
      : (service?.categoryId ?? preselectedCategoryId ?? categories.first.id);
  int? selectedDuration = service?.duration;
  int selectedProcessingTime = service?.processingTime ?? 0;
  int selectedBlockedTime = service?.blockedTime ?? 0;

  // Enforce mutual exclusivity at init: prefer processingTime if both set
  if (selectedProcessingTime > 0 && selectedBlockedTime > 0) {
    selectedBlockedTime = 0;
  }

  // Inizializzazione selezione tempo aggiuntivo: nessuno/elaborazione/bloccato
  _AdditionalTimeSelection additionalSelection = selectedProcessingTime > 0
      ? _AdditionalTimeSelection.processing
      : (selectedBlockedTime > 0
            ? _AdditionalTimeSelection.blocked
            : _AdditionalTimeSelection.none);
  int additionalMinutes = selectedProcessingTime > 0
      ? selectedProcessingTime
      : selectedBlockedTime;

  bool isBookableOnline = service?.isBookableOnline ?? true;
  bool isFree = service?.isFree ?? false;
  bool isPriceStartingFrom = service?.isPriceStartingFrom ?? false;

  bool nameError = false;
  // duplicateError rimosso: ora gestito con conferma non bloccante
  bool durationError = false;
  bool categoryError = false;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return AppFormDialog(
          title: Text(
            service == null
                ? context.l10n.newServiceTitle
                : context.l10n.editServiceTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldCategoryRequiredLabel,
                  errorText: categoryError
                      ? context.l10n.validationRequired
                      : null,
                ),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() {
                  selectedCategory = v;
                  categoryError = false;
                }),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldNameRequiredLabel,
                  errorText: nameError
                      ? context.l10n.fieldNameRequiredError
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldDescriptionLabel,
                  alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: selectedDuration,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldDurationRequiredLabel,
                  errorText: durationError
                      ? context.l10n.fieldDurationRequiredError
                      : null,
                ),
                items: [
                  for (final (minutes, label) in _durationOptions(context))
                    DropdownMenuItem(value: minutes, child: Text(label)),
                ],
                onChanged: (v) => setState(() {
                  selectedDuration = v;
                  durationError = false;
                  if ((selectedDuration ?? 0) <= 0) {
                    additionalSelection = _AdditionalTimeSelection.none;
                    additionalMinutes = 0;
                  }
                }),
              ),
              const SizedBox(height: 10),
              // Tempo aggiuntivo (visibile solo se Durata > 0)
              if ((selectedDuration ?? 0) > 0) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<_AdditionalTimeSelection>(
                  value: additionalSelection,
                  decoration: InputDecoration(
                    labelText: context.l10n.additionalTimeSwitch,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: _AdditionalTimeSelection.none,
                      child: Text(context.l10n.additionalTimeOptionNone),
                    ),
                    DropdownMenuItem(
                      value: _AdditionalTimeSelection.processing,
                      child: Text(context.l10n.additionalTimeOptionProcessing),
                    ),
                    DropdownMenuItem(
                      value: _AdditionalTimeSelection.blocked,
                      child: Text(context.l10n.additionalTimeOptionBlocked),
                    ),
                  ],
                  onChanged: (sel) => setState(() {
                    additionalSelection = sel ?? _AdditionalTimeSelection.none;
                    if (additionalSelection == _AdditionalTimeSelection.none) {
                      additionalMinutes = 0;
                    }
                  }),
                ),
                if (additionalSelection != _AdditionalTimeSelection.none) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: additionalMinutes,
                    decoration: InputDecoration(
                      labelText:
                          (additionalSelection ==
                              _AdditionalTimeSelection.processing)
                          ? context.l10n.fieldProcessingTimeLabel
                          : context.l10n.fieldBlockedTimeLabel,
                    ),
                    items: [
                      for (final (minutes, label) in _bufferOptions(context))
                        DropdownMenuItem(value: minutes, child: Text(label)),
                    ],
                    onChanged: (v) => setState(() {
                      additionalMinutes = v ?? 0;
                    }),
                  ),
                ],
              ],
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.fieldPriceLabel,
                  prefixText: '$currencySymbol ',
                ),
                enabled: !isFree,
                onChanged: (_) {
                  if (priceController.text.trim().isEmpty &&
                      isPriceStartingFrom) {
                    setState(() => isPriceStartingFrom = false);
                  }
                },
              ),
              const SizedBox(height: 10),

              _SwitchTile(
                title: context.l10n.freeServiceSwitch,
                value: isFree,
                onChanged: (v) {
                  setState(() {
                    isFree = v;
                    if (isFree) {
                      priceController.clear();
                      isPriceStartingFrom = false;
                    }
                  });
                },
              ),
              _SwitchTile(
                title: context.l10n.priceStartingFromSwitch,
                subtitle: (isFree || priceController.text.trim().isEmpty)
                    ? context.l10n.setPriceToEnable
                    : null,
                value: isPriceStartingFrom,
                onChanged: (!isFree && priceController.text.trim().isNotEmpty)
                    ? (v) => setState(() => isPriceStartingFrom = v)
                    : null,
                enabled: (!isFree && priceController.text.trim().isNotEmpty),
              ),
              const SizedBox(height: 40),
              _SwitchTile(
                title: context.l10n.bookableOnlineSwitch,
                value: isBookableOnline,
                onChanged: (v) => setState(() => isBookableOnline = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(context.l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setState(() => nameError = true);
                  return;
                }
                final normalizedName = StringUtils.toTitleCase(name);
                final isDuplicate = ServiceValidators.isDuplicateServiceName(
                  allServices,
                  normalizedName,
                  excludeId: service?.id,
                );
                if (selectedDuration == null) {
                  setState(() => durationError = true);
                  return;
                }

                if (selectedCategory == null) {
                  setState(() => categoryError = true);
                  return;
                }

                final parsedPrice = PriceFormatter.parse(priceController.text);
                final effectiveIsFree = isFree;
                final double? finalPrice = effectiveIsFree ? null : parsedPrice;
                final bool finalIsPriceStartingFrom =
                    (effectiveIsFree || finalPrice == null)
                    ? false
                    : isPriceStartingFrom;

                Future<void> doSave() async {
                  // Mappa i campi aggiuntivi dalla selezione
                  int processingToSave = 0;
                  int blockedToSave = 0;
                  if (additionalSelection ==
                          _AdditionalTimeSelection.processing &&
                      additionalMinutes > 0) {
                    processingToSave = additionalMinutes;
                  } else if (additionalSelection ==
                          _AdditionalTimeSelection.blocked &&
                      additionalMinutes > 0) {
                    blockedToSave = additionalMinutes;
                  }
                  final newService = Service(
                    id: service?.id ?? DateTime.now().millisecondsSinceEpoch,
                    businessId: ref.read(currentBusinessProvider).id,
                    categoryId: selectedCategory!,
                    name: normalizedName,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    duration: selectedDuration,
                    processingTime: processingToSave,
                    blockedTime: blockedToSave,
                    price: finalPrice,
                    color: service?.color,
                    isBookableOnline: isBookableOnline,
                    isFree: effectiveIsFree,
                    isPriceStartingFrom: finalIsPriceStartingFrom,
                    currency: service?.currency ?? currencyCode,
                    // Mantiene l'ordinamento per i servizi esistenti
                    sortOrder: service?.sortOrder ?? 0,
                  );

                  if (service == null) {
                    notifier.add(newService);
                  } else {
                    notifier.update(newService);
                  }

                  Navigator.of(context, rootNavigator: true).pop();
                }

                if (isDuplicate) {
                  await showAppConfirmDialog(
                    context,
                    title: Text(context.l10n.serviceDuplicateError),
                    confirmLabel: context.l10n.actionConfirm,
                    cancelLabel: context.l10n.actionCancel,
                    danger: false,
                    onConfirm: doSave,
                  );
                } else {
                  await doSave();
                }
              },
              child: Text(context.l10n.actionSave),
            ),
          ],
        );
      },
    ),
  );
}

List<(int, String)> _durationOptions(BuildContext context) {
  final List<(int, String)> options = [];
  for (int i = 5; i <= 240; i += 5) {
    options.add((i, context.localizedDurationLabel(i)));
  }
  return options;
}

List<(int, String)> _bufferOptions(BuildContext context) {
  final List<(int, String)> options = [];
  final steps = <int>[0, 5, 10, 15, 20, 30, 45, 60];
  for (final m in steps) {
    options.add((m, context.localizedDurationLabel(m)));
  }
  return options;
}
