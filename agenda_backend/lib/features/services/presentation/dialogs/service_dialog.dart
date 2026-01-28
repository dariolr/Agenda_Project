import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/theme/app_spacing.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/resource_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/resource.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_variant.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../staff/providers/staff_providers.dart';
import '../../providers/service_categories_provider.dart';
import '../../providers/services_provider.dart';
import '../../utils/service_seed_texts.dart';
import '../../utils/service_validators.dart';

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

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
              AppSwitch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              if (selected)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceQuantityRow extends StatelessWidget {
  const _ResourceQuantityRow({
    required this.resource,
    required this.quantity,
    required this.onQuantityChanged,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
  });

  final Resource resource;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;
    final maxQuantity = resource.quantity;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Toggle selezione: se non selezionato, imposta 1; se selezionato, rimuovi
          onQuantityChanged(isSelected ? 0 : 1);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Checkbox visiva
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              // Nome risorsa e quantità disponibile
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.name, style: textTheme.bodyLarge),
                    Text(
                      '${l10n.resourceQuantityLabel}: ${resource.quantity}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Selettore quantità (visibile solo se selezionato E la risorsa ha più di 1 unità)
              if (isSelected && maxQuantity > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  // Impedisce la propagazione del tap all'InkWell esterno
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsante -
                        IconButton(
                          onPressed: quantity > 1
                              ? () => onQuantityChanged(quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          color: colorScheme.primary,
                          disabledColor: colorScheme.outline.withOpacity(0.5),
                        ),
                        // Quantità
                        Container(
                          constraints: const BoxConstraints(minWidth: 32),
                          alignment: Alignment.center,
                          child: Text(
                            '$quantity',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        // Pulsante +
                        IconButton(
                          onPressed: quantity < maxQuantity
                              ? () => onQuantityChanged(quantity + 1)
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          color: colorScheme.primary,
                          disabledColor: colorScheme.outline.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
  bool duplicateFrom = false,
}) async {
  final notifier = ref.read(servicesProvider.notifier);
  final allServices = ref.read(servicesProvider).value ?? [];
  final categories = ref.read(serviceCategoriesProvider);
  final isEditing = service != null && !duplicateFrom;
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

  String makeDuplicateName(String originalName) {
    final copyWord = ServiceSeedTexts.duplicateCopyWord;
    final copyWordEscaped = RegExp.escape(copyWord);
    String base = originalName;
    int? startFrom;

    final reNew = RegExp(
      '^(.*?)(?:\\s$copyWordEscaped(?:\\s(\\d+))?)\$',
      caseSensitive: false,
    );
    final reOld = RegExp(
      '^(.*?)(?:\\s\\((?:$copyWordEscaped)(?:\\s(\\d+))?\\))\$',
      caseSensitive: false,
    );

    final match =
        reNew.firstMatch(originalName) ?? reOld.firstMatch(originalName);
    if (match != null) {
      base = (match.group(1) ?? '').trim();
      final n = match.group(2);
      if (n != null) {
        final parsed = int.tryParse(n);
        if (parsed != null) startFrom = parsed + 1;
      } else {
        startFrom = 1;
      }
    }

    final existingNames = allServices.map((s) => s.name).toSet();
    String candidate = '$base $copyWord';
    if (!existingNames.contains(candidate)) return candidate;

    int i = startFrom ?? 1;
    while (true) {
      candidate = '$base $copyWord $i';
      if (!existingNames.contains(candidate)) return candidate;
      i++;
      if (i > 9999) break;
    }
    return '$base $copyWord';
  }

  final nameController = TextEditingController(
    text: (duplicateFrom && service != null)
        ? makeDuplicateName(service.name)
        : (service?.name ?? ''),
  );
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
  final staffList = ref.read(staffForCurrentLocationProvider);
  final staffNotifier = ref.read(allStaffProvider.notifier);
  final eligibilityNotifier = ref.read(
    serviceStaffEligibilityProvider.notifier,
  );
  final locationId = ref.read(currentLocationProvider).id;
  final originalStaffIds = service != null
      ? ref.read(eligibleStaffForServiceProvider(service.id)).toSet()
      : <int>{};
  Set<int> selectedStaffIds = {...originalStaffIds};
  bool isSelectingStaff = false;

  // Risorse richieste (Map: resourceId -> quantity)
  final locationResources = ref.read(locationResourcesProvider(locationId));
  final existingResourceRequirements =
      existingVariant?.resourceRequirements ?? const [];
  final originalResourceQuantities = <int, int>{
    for (final r in existingResourceRequirements) r.resourceId: r.unitsRequired,
  };
  Map<int, int> selectedResourceQuantities = {...originalResourceQuantities};
  bool isSelectingResources = false;

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
  bool isSaving = false;

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
      excludeId: isEditing ? service.id : null,
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

      Service? savedService;

      if (!isEditing) {
        // Create new service via API
        savedService = await notifier.createServiceApi(
          name: normalizedName,
          categoryId: selectedCategory!,
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          durationMinutes: selectedDuration!,
          price: finalPrice ?? 0,
          colorHex: ColorUtils.toHex(selectedColor),
          isBookableOnline: isBookableOnline,
          isPriceStartingFrom: finalIsPriceStartingFrom,
          processingTime: processingToSave > 0 ? processingToSave : null,
          blockedTime: blockedToSave > 0 ? blockedToSave : null,
        );
      } else {
        // Update existing service via API
        savedService = await notifier.updateServiceApi(
          serviceId: service.id,
          name: normalizedName,
          categoryId: selectedCategory!,
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          durationMinutes: selectedDuration!,
          price: finalPrice ?? 0,
          colorHex: ColorUtils.toHex(selectedColor),
          isBookableOnline: isBookableOnline,
          isPriceStartingFrom: finalIsPriceStartingFrom,
          processingTime: processingToSave,
          blockedTime: blockedToSave,
        );
      }

      if (savedService == null) {
        // API call failed, don't close dialog
        return;
      }

      // Update local variant for immediate UI feedback (variant is derived from service)
      final newVariant = ServiceVariant(
        id: isEditing
            ? (existingVariant?.id ?? (900000 + savedService.id))
            : (900000 + savedService.id),
        serviceId: savedService.id,
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

      ref.read(serviceVariantsProvider.notifier).upsert(newVariant);

      // Aggiorna le associazioni staff-servizio nel database
      // Calcola quali staff sono stati aggiunti/rimossi
      final addedStaffIds = selectedStaffIds.difference(originalStaffIds);
      final removedStaffIds = originalStaffIds.difference(selectedStaffIds);

      // Aggiorna ogni staff modificato nel database
      final allStaff = ref.read(allStaffProvider).value ?? [];
      final serviceId = savedService.id;
      for (final staffId in addedStaffIds) {
        final staff = allStaff.firstWhere((s) => s.id == staffId);
        final newServiceIds = {...staff.serviceIds, serviceId}.toList();
        await staffNotifier.updateStaffApi(
          staffId: staffId,
          serviceIds: newServiceIds,
        );
      }
      for (final staffId in removedStaffIds) {
        final staff = allStaff.firstWhere((s) => s.id == staffId);
        final newServiceIds = staff.serviceIds
            .where((id) => id != serviceId)
            .toList();
        await staffNotifier.updateStaffApi(
          staffId: staffId,
          serviceIds: newServiceIds,
        );
      }

      // Aggiorna anche lo stato locale UI
      eligibilityNotifier.setEligibleStaffForService(
        serviceId: savedService.id,
        locationId: locationId,
        staffIds: selectedStaffIds,
      );

      // Aggiorna le risorse richieste per il service variant
      final variantId = savedService.serviceVariantId;
      final resourcesChanged = !_mapEquals(
        selectedResourceQuantities,
        originalResourceQuantities,
      );
      if (variantId != null && resourcesChanged) {
        final apiClient = ref.read(apiClientProvider);
        final resourcesList = [
          for (final entry in selectedResourceQuantities.entries)
            {'resource_id': entry.key, 'quantity': entry.value},
        ];
        await apiClient.setServiceVariantResources(
          serviceVariantId: variantId,
          resources: resourcesList,
        );
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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
    Future<void> openStaffSelector() async {
      if (isSelectingStaff) return;
      setState(() => isSelectingStaff = true);
      final l10n = context.l10n;
      final formFactor = ref.read(formFactorProvider);
      Set<int> current = {...selectedStaffIds};

      Widget buildStaffRows(void Function(VoidCallback) setStateLocal) {
        final allIds = [for (final s in staffList) s.id];
        final allSelected = allIds.isNotEmpty && allIds.every(current.contains);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SelectableRow(
              label: l10n.teamSelectAllServices,
              selected: allSelected,
              onTap: () {
                if (allSelected) {
                  current.clear();
                } else {
                  current
                    ..clear()
                    ..addAll(allIds);
                }
                setStateLocal(() {});
              },
            ),
            const Divider(height: 1),
            for (final member in staffList)
              _SelectableRow(
                label: member.displayName,
                selected: current.contains(member.id),
                onTap: () {
                  if (current.contains(member.id)) {
                    current.remove(member.id);
                  } else {
                    current.add(member.id);
                  }
                  setStateLocal(() {});
                },
              ),
          ],
        );
      }

      Future<void> openDialog(BuildContext ctx) async {
        await showDialog<void>(
          context: ctx,
          builder: (dialogCtx) => StatefulBuilder(
            builder: (context, setStateLocal) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 520,
                    maxWidth: 680,
                    maxHeight: 520,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          l10n.teamEligibleStaffLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          child: buildStaffRows(setStateLocal),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AppFilledButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            padding: AppButtonStyles.dialogButtonPadding,
                            child: Text(l10n.actionConfirm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }

      Future<void> openSheet(BuildContext ctx) async {
        await AppBottomSheet.show<void>(
          context: ctx,
          heightFactor: AppBottomSheet.defaultHeightFactor,
          padding: EdgeInsets.zero,
          builder: (sheetCtx) => StatefulBuilder(
            builder: (context, setStateLocal) {
              return SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        l10n.teamEligibleStaffLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        child: buildStaffRows(setStateLocal),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AppFilledButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          padding: AppButtonStyles.dialogButtonPadding,
                          child: Text(l10n.actionConfirm),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(ctx).viewPadding.bottom),
                  ],
                ),
              );
            },
          ),
        );
      }

      if (formFactor == AppFormFactor.desktop) {
        await openDialog(context);
      } else {
        await openSheet(context);
      }

      setState(() {
        selectedStaffIds = {...current};
        isSelectingStaff = false;
      });
    }

    Future<void> openResourceSelector() async {
      if (isSelectingResources) return;
      setState(() => isSelectingResources = true);
      final l10n = context.l10n;
      final formFactor = ref.read(formFactorProvider);
      Map<int, int> current = {...selectedResourceQuantities};

      Widget buildResourceRows(void Function(VoidCallback) setStateLocal) {
        if (locationResources.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.resourceNoneLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          );
        }
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final resource in locationResources)
              _ResourceQuantityRow(
                resource: resource,
                quantity: current[resource.id] ?? 0,
                onQuantityChanged: (qty) {
                  if (qty == 0) {
                    current.remove(resource.id);
                  } else {
                    current[resource.id] = qty;
                  }
                  setStateLocal(() {});
                },
                colorScheme: colorScheme,
                textTheme: textTheme,
                l10n: l10n,
              ),
          ],
        );
      }

      Future<void> openResourceDialog(BuildContext ctx) async {
        await showDialog<void>(
          context: ctx,
          builder: (dialogCtx) => StatefulBuilder(
            builder: (context, setStateLocal) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 520,
                    maxWidth: 680,
                    maxHeight: 520,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          l10n.serviceRequiredResourcesLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          child: buildResourceRows(setStateLocal),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppOutlinedActionButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              padding: AppButtonStyles.dialogButtonPadding,
                              child: Text(l10n.actionCancel),
                            ),
                            const SizedBox(width: 12),
                            AppFilledButton(
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              padding: AppButtonStyles.dialogButtonPadding,
                              child: Text(l10n.actionConfirm),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }

      Future<void> openResourceSheet(BuildContext ctx) async {
        await AppBottomSheet.show<void>(
          context: ctx,
          heightFactor: AppBottomSheet.defaultHeightFactor,
          padding: EdgeInsets.zero,
          builder: (sheetCtx) => StatefulBuilder(
            builder: (context, setStateLocal) {
              return SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        l10n.serviceRequiredResourcesLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        child: buildResourceRows(setStateLocal),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppOutlinedActionButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            padding: AppButtonStyles.dialogButtonPadding,
                            child: Text(l10n.actionCancel),
                          ),
                          const SizedBox(width: 12),
                          AppFilledButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            padding: AppButtonStyles.dialogButtonPadding,
                            child: Text(l10n.actionConfirm),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(ctx).viewPadding.bottom),
                  ],
                ),
              );
            },
          ),
        );
      }

      if (formFactor == AppFormFactor.desktop) {
        await openResourceDialog(context);
      } else {
        await openResourceSheet(context);
      }

      setState(() {
        selectedResourceQuantities = {...current};
        isSelectingResources = false;
      });
    }

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
        AppOutlinedActionButton(
          onPressed: openStaffSelector,
          expand: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(context.l10n.teamEligibleStaffLabel),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedStaffIds.length}/${staffList.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (locationResources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.formRowSpacing),
          AppOutlinedActionButton(
            onPressed: openResourceSelector,
            expand: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(context.l10n.serviceRequiredResourcesLabel),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedResourceQuantities.length}/${locationResources.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  for (final (minutes, label) in _bufferOptions(
                    context,
                    additionalMinutes,
                  ))
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

  final dialogTitle = !isEditing
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
          onPressed: isSaving
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(),
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(context.l10n.actionCancel),
        ),
      );

      final saveButton = SizedBox(
        width: AppButtonStyles.dialogButtonWidth,
        child: AppAsyncFilledButton(
          onPressed: isSaving
              ? null
              : () async {
                  setState(() => isSaving = true);
                  try {
                    await handleSave();
                    setState(() {});
                  } finally {
                    setState(() => isSaving = false);
                  }
                },
          padding: AppButtonStyles.dialogButtonPadding,
          isLoading: isSaving,
          showSpinner: false,
          child: Text(context.l10n.actionSave),
        ),
      );
      final bottomActions = [cancelButton, saveButton];

      if (isDesktop) {
        return DismissibleDialog(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
              child: LocalLoadingOverlay(
                isLoading: isSaving,
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
          ),
        );
      }

      return SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            return LocalLoadingOverlay(
              isLoading: isSaving,
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      dialogTitle,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  body,
                                  const SizedBox(height: 24),
                                  const SizedBox(
                                    height: AppSpacing.formRowSpacing,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isKeyboardOpen) ...[
                      const AppBottomSheetDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Align(
                          alignment: bottomActions.length == 3
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: Wrap(
                            alignment: bottomActions.length == 3
                                ? WrapAlignment.center
                                : WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: bottomActions,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                  ],
                ),
              ),
            );
          },
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
      padding: EdgeInsets.zero,
    );
  }
}

List<(int, String)> _durationOptions(BuildContext context) {
  final List<(int, String)> options = [];
  for (int i = 5; i <= 420; i += 5) {
    options.add((i, context.localizedDurationLabel(i)));
  }
  return options;
}

List<(int, String)> _bufferOptions(BuildContext context, [int? currentValue]) {
  final List<(int, String)> options = [];
  final steps = <int>[0, 5, 10, 15, 20, 30, 45, 60, 90, 120];

  // Se il valore corrente non è nella lista standard, aggiungilo
  if (currentValue != null &&
      currentValue > 0 &&
      !steps.contains(currentValue)) {
    steps.add(currentValue);
    steps.sort();
  }

  for (final m in steps) {
    options.add((m, context.localizedDurationLabel(m)));
  }
  return options;
}
