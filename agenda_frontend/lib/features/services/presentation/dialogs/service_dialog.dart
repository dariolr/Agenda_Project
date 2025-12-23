import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/theme/app_spacing.dart';
import 'package:agenda_frontend/features/agenda/providers/business_providers.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_variant.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../providers/service_categories_provider.dart';
import '../../providers/services_provider.dart';
import '../../utils/service_validators.dart';

enum _AdditionalTimeSelection { none, processing, blocked }

const List<Color> _serviceColorPalette = [
  // Reds
  Color(0xFFFFCDD2),
  Color(0xFFFFC1C9),
  Color(0xFFFFB4BC),
  // Oranges
  Color(0xFFFFD6B3),
  Color(0xFFFFC9A3),
  Color(0xFFFFBD93),
  // Yellows
  Color(0xFFFFF0B3),
  Color(0xFFFFE6A3),
  Color(0xFFFFDC93),
  // Yellow-greens
  Color(0xFFEAF2B3),
  Color(0xFFDFEAA3),
  Color(0xFFD4E293),
  // Greens
  Color(0xFFCDECCF),
  Color(0xFFC1E4C4),
  Color(0xFFB6DCB9),
  // Teals
  Color(0xFFBFE8E0),
  Color(0xFFB1DFD6),
  Color(0xFFA3D6CB),
  // Cyans
  Color(0xFFBDEFF4),
  Color(0xFFB0E6EF),
  Color(0xFFA3DDEA),
  // Blues
  Color(0xFFBFD9FF),
  Color(0xFFB0CEFF),
  Color(0xFFA1C3FF),
  // Indigos
  Color(0xFFC7D0FF),
  Color(0xFFBAC4FF),
  Color(0xFFADB8FF),
  // Purples
  Color(0xFFDCC9FF),
  Color(0xFFD0BDFF),
  Color(0xFFC4B1FF),
  // Pinks
  Color(0xFFFFC7E3),
  Color(0xFFFFB7D9),
  Color(0xFFFFA8CF),
];

Color _contrastFor(Color color) {
  return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}

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
  Color? preselectedColor,
  bool requireCategorySelection = false,
}) async {
  final notifier = ref.read(servicesProvider.notifier);
  final allServices = ref.read(servicesProvider);
  final categories = ref.read(serviceCategoriesProvider);
  final existingVariant = service != null
      ? ref.read(serviceVariantByServiceIdProvider(service.id))
      : null;
  final currencyCode = ref.read(effectiveCurrencyProvider);
  final currencySymbol = NumberFormat.currency(
    name: currencyCode,
  ).currencySymbol;
  final isDesktop = ref.read(formFactorProvider) == AppFormFactor.desktop;
  final colorScrollController = ScrollController();
  bool didAutoScroll = false;

  final nameController = TextEditingController(text: service?.name ?? '');
  final priceController = TextEditingController(
    text: (existingVariant != null && existingVariant.price > 0)
        ? PriceFormatter.format(
            context: context,
            amount: existingVariant.price,
            currencyCode: existingVariant.currency ?? currencyCode,
          )
        : '',
  );
  final descController = TextEditingController(
    text: service?.description ?? '',
  );

  int? selectedCategory = requireCategorySelection
      ? (service?.categoryId ?? preselectedCategoryId)
      : (service?.categoryId ?? preselectedCategoryId ?? categories.first.id);
  int? selectedDuration = existingVariant?.durationMinutes;
  int selectedProcessingTime = existingVariant?.processingTime ?? 0;
  int selectedBlockedTime = existingVariant?.blockedTime ?? 0;
  final palette = <Color>[..._serviceColorPalette];
  final seen = <int>{};
  final uniquePalette = <Color>[
    for (final c in palette)
      if (seen.add(c.value)) c,
  ];
  final serviceColor = existingVariant?.colorHex != null
      ? ColorUtils.fromHex(existingVariant!.colorHex!)
      : null;
  final hasPreselectedColor =
      preselectedColor != null &&
      uniquePalette.any((c) => c.value == preselectedColor.value);
  final hasServiceColor =
      serviceColor != null &&
      uniquePalette.any((c) => c.value == serviceColor.value);
  Color selectedColor = hasServiceColor
      ? serviceColor
      : (hasPreselectedColor ? preselectedColor : uniquePalette.first);

  if (selectedProcessingTime > 0 && selectedBlockedTime > 0) {
    selectedBlockedTime = 0;
  }

  _AdditionalTimeSelection additionalSelection = selectedProcessingTime > 0
      ? _AdditionalTimeSelection.processing
      : (selectedBlockedTime > 0
            ? _AdditionalTimeSelection.blocked
            : _AdditionalTimeSelection.none);
  int additionalMinutes = selectedProcessingTime > 0
      ? selectedProcessingTime
      : selectedBlockedTime;

  bool isBookableOnline = existingVariant?.isBookableOnline ?? true;
  bool isFree = existingVariant?.isFree ?? false;
  bool isPriceStartingFrom = existingVariant?.isPriceStartingFrom ?? false;

  bool nameError = false;
  bool durationError = false;
  bool categoryError = false;

  void scrollToSelected({required bool animate}) {
    if (!colorScrollController.hasClients) return;
    final index = uniquePalette.indexWhere(
      (c) => c.value == selectedColor.value,
    );
    if (index < 0) return;
    const double colorItemSize = 36;
    const double colorItemSpacing = 10;
    const double colorListPadding = 4;
    final viewport = colorScrollController.position.viewportDimension;
    final target =
        index * (colorItemSize + colorItemSpacing) -
        (viewport - colorItemSize) / 2 -
        colorListPadding;
    final maxExtent = colorScrollController.position.maxScrollExtent;
    final clamped = target.clamp(0.0, maxExtent);
    if (animate) {
      colorScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      colorScrollController.jumpTo(clamped);
    }
  }

  Future<void> handleSave() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      nameError = true;
      return;
    }
    final normalizedName = StringUtils.toTitleCase(name);
    final isDuplicate = ServiceValidators.isDuplicateServiceName(
      allServices,
      normalizedName,
      excludeId: service?.id,
    );
    if (selectedDuration == null) {
      durationError = true;
      return;
    }
    if (selectedCategory == null) {
      categoryError = true;
      return;
    }

    final parsedPrice = PriceFormatter.parse(priceController.text);
    final effectiveIsFree = isFree;
    final double? finalPrice = effectiveIsFree ? null : parsedPrice;
    final bool finalIsPriceStartingFrom =
        (effectiveIsFree || finalPrice == null) ? false : isPriceStartingFrom;

    Future<void> doSave() async {
      int processingToSave = 0;
      int blockedToSave = 0;
      if (additionalSelection == _AdditionalTimeSelection.processing &&
          additionalMinutes > 0) {
        processingToSave = additionalMinutes;
      } else if (additionalSelection == _AdditionalTimeSelection.blocked &&
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
        sortOrder: service?.sortOrder ?? 0,
      );

      final newVariant = ServiceVariant(
        id: existingVariant?.id ?? (900000 + newService.id),
        serviceId: newService.id,
        locationId: ref.read(currentLocationProvider).id,
        durationMinutes: selectedDuration!,
        processingTime: processingToSave,
        blockedTime: blockedToSave,
        price: finalPrice ?? 0,
        colorHex: ColorUtils.toHex(selectedColor),
        currency: currencyCode,
        isBookableOnline: isBookableOnline,
        isFree: effectiveIsFree,
        isPriceStartingFrom: finalIsPriceStartingFrom,
        resourceRequirements: existingVariant?.resourceRequirements ?? const [],
      );

      if (service == null) {
        notifier.add(newService);
      } else {
        notifier.update(newService);
      }
      ref.read(serviceVariantsProvider.notifier).upsert(newVariant);

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
  }

  Widget buildBody(BuildContext context, void Function(VoidCallback) setState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormField(
          label: context.l10n.fieldCategoryRequiredLabel,
          child: DropdownButtonFormField<int>(
            value: selectedCategory,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: categoryError ? context.l10n.validationRequired : null,
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
        ),
        const SizedBox(height: AppSpacing.formRowSpacing),
        LabeledFormField(
          label: context.l10n.fieldNameRequiredLabel,
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: nameError ? context.l10n.fieldNameRequiredError : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.formRowSpacing),
        LabeledFormField(
          label: context.l10n.fieldDescriptionLabel,
          child: TextField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.formRowSpacing),
        LabeledFormField(
          label: context.l10n.serviceColorLabel,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.01, 0.99, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: ListView.separated(
                        controller: colorScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: uniquePalette.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final color = uniquePalette[index];
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedColor = color;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor.value == color.value
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.black.withOpacity(0.08),
                                  width: selectedColor.value == color.value
                                      ? 2
                                      : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: selectedColor.value == color.value
                                  ? Icon(
                                      Icons.check,
                                      color: _contrastFor(color),
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '09:00 - 10:00  ${context.l10n.formClient}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nameController.text.trim().isEmpty
                          ? context.l10n.formService
                          : nameController.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.formRowSpacing),
        LabeledFormField(
          label: context.l10n.fieldDurationRequiredLabel,
          child: DropdownButtonFormField<int>(
            value: selectedDuration,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
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
        ),
        if ((selectedDuration ?? 0) > 0) ...[
          const SizedBox(height: AppSpacing.formRowSpacing),
          LabeledFormField(
            label: context.l10n.additionalTimeSwitch,
            child: DropdownButtonFormField<_AdditionalTimeSelection>(
              value: additionalSelection == _AdditionalTimeSelection.none
                  ? null
                  : additionalSelection,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              hint: const Text(''),
              items: [
                DropdownMenuItem(
                  value: _AdditionalTimeSelection.none,
                  child: const Text(''),
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
          ),
          if (additionalSelection != _AdditionalTimeSelection.none) ...[
            const SizedBox(height: AppSpacing.formRowSpacing),
            LabeledFormField(
              label:
                  (additionalSelection == _AdditionalTimeSelection.processing)
                  ? context.l10n.fieldProcessingTimeLabel
                  : context.l10n.fieldBlockedTimeLabel,
              child: DropdownButtonFormField<int>(
                value: additionalMinutes,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final (minutes, label) in _bufferOptions(context))
                    DropdownMenuItem(value: minutes, child: Text(label)),
                ],
                onChanged: (v) => setState(() {
                  additionalMinutes = v ?? 0;
                }),
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.formRowSpacing),
        LabeledFormField(
          label: context.l10n.fieldPriceLabel,
          child: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
            ],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              prefixText: '$currencySymbol ',
            ),
            enabled: !isFree,
            onChanged: (_) {
              if (priceController.text.trim().isEmpty && isPriceStartingFrom) {
                setState(() => isPriceStartingFrom = false);
              }
            },
          ),
        ),
        const SizedBox(height: AppSpacing.formRowSpacing),
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
    );
  }

  final dialogTitle = service == null
      ? context.l10n.newServiceTitle
      : context.l10n.editServiceTitle;

  final builder = StatefulBuilder(
    builder: (context, setState) {
      if (!didAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToSelected(animate: false);
        });
        didAutoScroll = true;
      }
      final body = buildBody(context, setState);

      final cancelButton = SizedBox(
        width: AppButtonStyles.dialogButtonWidth,
        child: AppOutlinedActionButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(context.l10n.actionCancel),
        ),
      );

      final saveButton = SizedBox(
        width: AppButtonStyles.dialogButtonWidth,
        child: AppFilledButton(
          onPressed: () async {
            await handleSave();
            setState(() {});
          },
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(context.l10n.actionSave),
        ),
      );

      if (isDesktop) {
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
                    Text(
                      dialogTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Flexible(child: SingleChildScrollView(child: body)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        cancelButton,
                        const SizedBox(width: 8),
                        saveButton,
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
                child: Text(
                  dialogTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              body,
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [cancelButton, saveButton],
                ),
              ),
              SizedBox(height: 32 + MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        ),
      );
    },
  );

  if (isDesktop) {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => builder,
    );
  } else {
    await AppBottomSheet.show(
      context: context,
      builder: (_) => builder,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    );
  }
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
