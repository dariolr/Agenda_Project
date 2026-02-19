import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/date_time_formats.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/popular_service.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service_package.dart';
import '../../../../core/models/service_variant.dart';
import '../../../../core/models/staff.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/config/layout_config.dart';
import '../../domain/service_item_data.dart';
import 'service_picker_field.dart';

String _formatExtraDuration(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (mins == 0) {
    return '$hours h';
  }
  return '$hours h $mins min';
}

/// Card per visualizzare e modificare un singolo servizio nella prenotazione.
class ServiceItemCard extends ConsumerStatefulWidget {
  const ServiceItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.services,
    required this.categories,
    required this.variants,
    required this.eligibleStaff,
    required this.allStaff,
    required this.formFactor,
    required this.onChanged,
    required this.onRemove,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onDurationChanged,
    this.packages,
    this.popularServices,
    this.onPackageSelected,
    this.suggestedStartTime,
    this.canRemove = true,
    this.isServiceRequired = true,
    this.autoOpenServicePicker = false,
    this.onServicePickerAutoOpened,
    this.onServicePickerAutoCompleted,
    this.onAutoOpenStaffPickerCompleted,
    this.availabilityWarningMessage,
    this.staffEligibilityWarningMessage,
    this.preselectedStaffServiceIds,
    this.canSelectStaff = true,
  });

  final ServiceItemData item;
  final int index;
  final List<Service> services;
  final List<ServiceCategory> categories;
  final List<ServiceVariant> variants;
  final List<int> eligibleStaff; // Staff IDs abilitati per il servizio corrente
  final List<Staff> allStaff;
  final AppFormFactor formFactor;
  final ValueChanged<ServiceItemData> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final ValueChanged<int> onDurationChanged;

  /// Optional packages to show in the service picker.
  final List<ServicePackage>? packages;

  /// Servizi più prenotati (top 5) per la location corrente.
  final PopularServicesResult? popularServices;

  /// Callback when a package is selected from the picker.
  final ValueChanged<ServicePackage>? onPackageSelected;

  final TimeOfDay? suggestedStartTime;
  final bool canRemove;

  /// Se true, la selezione del servizio è obbligatoria (mostra errore di validazione).
  final bool isServiceRequired;
  final bool autoOpenServicePicker;
  final VoidCallback? onServicePickerAutoOpened;
  final VoidCallback? onServicePickerAutoCompleted;
  final VoidCallback? onAutoOpenStaffPickerCompleted;
  final String? availabilityWarningMessage;
  final String? staffEligibilityWarningMessage;

  /// IDs dei servizi abilitati per lo staff preselezionato.
  /// Se fornito, il picker mostrerà di default solo questi servizi.
  final List<int>? preselectedStaffServiceIds;
  final bool canSelectStaff;

  @override
  ConsumerState<ServiceItemCard> createState() => _ServiceItemCardState();
}

class _ServiceItemCardState extends ConsumerState<ServiceItemCard> {
  static const int _startTimeStepMinutes = 5;

  bool _autoOpenStaffRequested = false;
  bool _shouldAutoOpenStaff = false;

  ServiceItemData get item => widget.item;
  int get index => widget.index;
  List<Service> get services => widget.services;
  List<ServiceCategory> get categories => widget.categories;
  List<ServiceVariant> get variants => widget.variants;
  List<int> get eligibleStaff => widget.eligibleStaff;
  List<Staff> get allStaff => widget.allStaff;
  AppFormFactor get formFactor => widget.formFactor;
  ValueChanged<ServiceItemData> get onChanged => widget.onChanged;
  VoidCallback get onRemove => widget.onRemove;
  ValueChanged<TimeOfDay> get onStartTimeChanged => widget.onStartTimeChanged;
  ValueChanged<TimeOfDay> get onEndTimeChanged => widget.onEndTimeChanged;
  ValueChanged<int> get onDurationChanged => widget.onDurationChanged;
  List<ServicePackage>? get packages => widget.packages;
  PopularServicesResult? get popularServices => widget.popularServices;
  ValueChanged<ServicePackage>? get onPackageSelected =>
      widget.onPackageSelected;
  TimeOfDay? get suggestedStartTime => widget.suggestedStartTime;
  bool get canRemove => widget.canRemove;
  bool get isServiceRequired => widget.isServiceRequired;
  bool get autoOpenServicePicker => widget.autoOpenServicePicker;
  VoidCallback? get onServicePickerAutoOpened =>
      widget.onServicePickerAutoOpened;
  VoidCallback? get onServicePickerAutoCompleted =>
      widget.onServicePickerAutoCompleted;
  VoidCallback? get onAutoOpenStaffPickerCompleted =>
      widget.onAutoOpenStaffPickerCompleted;
  String? get availabilityWarningMessage => widget.availabilityWarningMessage;
  String? get staffEligibilityWarningMessage =>
      widget.staffEligibilityWarningMessage;
  List<int>? get preselectedStaffServiceIds =>
      widget.preselectedStaffServiceIds;
  bool get canSelectStaff => widget.canSelectStaff;

  @override
  void didUpdateWidget(covariant ServiceItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.serviceId != widget.item.serviceId) {
      _autoOpenStaffRequested = false;
      _shouldAutoOpenStaff =
          widget.item.serviceId != null && widget.item.staffId == null;
    }
    if (widget.item.staffId != null) {
      _autoOpenStaffRequested = false;
      _shouldAutoOpenStaff = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final selectedService = item.serviceId != null
        ? services.where((s) => s.id == item.serviceId).firstOrNull
        : null;

    final selectedStaff = item.staffId != null
        ? allStaff.where((s) => s.id == item.staffId).firstOrNull
        : null;

    // Trova la variante corrente per mostrare il prezzo di default
    final selectedVariant = item.serviceId != null
        ? variants.where((v) => v.serviceId == item.serviceId).firstOrNull
        : null;

    // Staff disponibili per la selezione: sempre tutto lo staff della location
    // eligibleStaff serve solo per la selezione automatica, non per filtrare la lista
    final availableStaff = allStaff;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Servizio
            _buildServiceSelector(context, l10n, selectedService),

            const SizedBox(height: 12),

            // Staff
            _buildStaffSelector(
              context,
              l10n,
              selectedStaff,
              availableStaff,
              theme,
            ),

            const SizedBox(height: 12),

            // Orario
            _buildTimeSelector(context, l10n, theme),

            // Prezzo (solo se servizio selezionato)
            if (item.serviceId != null) ...[
              const SizedBox(height: 12),
              _buildPriceSelector(context, l10n, theme, selectedVariant),
            ],

            if (availabilityWarningMessage != null) ...[
              const SizedBox(height: 12),
              _buildAvailabilityWarning(availabilityWarningMessage!),
            ],
            if (staffEligibilityWarningMessage != null) ...[
              const SizedBox(height: 12),
              _buildAvailabilityWarning(staffEligibilityWarningMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelector(
    BuildContext context,
    dynamic l10n,
    Service? selectedService,
  ) {
    return ServicePickerField(
      services: services,
      categories: categories,
      packages: packages,
      popularServices: popularServices,
      formFactor: formFactor,
      value: item.serviceId,
      preselectedStaffServiceIds: preselectedStaffServiceIds,
      onChanged: (serviceId) {
        if (serviceId != null) {
          // Trova la variante di default per il servizio
          final variant = variants
              .where((v) => v.serviceId == serviceId)
              .firstOrNull;
          final duration = variant?.durationMinutes ?? 30;
          onChanged(
            item.copyWith(
              serviceId: serviceId,
              serviceVariantId: variant?.id,
              durationMinutes: duration,
              // Mantieni lo staff selezionato se presente
              staffId: item.staffId,
              blockedExtraMinutes: variant?.blockedTime ?? 0,
              processingExtraMinutes: variant?.processingTime ?? 0,
            ),
          );
        }
      },
      onPackageSelected: onPackageSelected,
      // Mostra icona rimuovi solo se canRemove e servizio selezionato
      onClear: canRemove && item.serviceId != null ? onRemove : null,
      validator: isServiceRequired
          ? (v) => v == null ? l10n.validationRequired : null
          : null,
      autoOpenPicker: autoOpenServicePicker,
      onAutoOpenPickerTriggered: onServicePickerAutoOpened,
      onAutoOpenPickerCompleted: onServicePickerAutoCompleted,
    );
  }

  Widget _buildAvailabilityWarning(String message) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8A4D00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSelector(
    BuildContext context,
    dynamic l10n,
    Staff? selectedStaff,
    List<Staff> availableStaff,
    ThemeData theme,
  ) {
    // Staff è obbligatorio se c'è un servizio selezionato in questa card
    final isStaffRequired = item.serviceId != null;

    return FormField<int>(
      initialValue: item.staffId,
      validator: isStaffRequired
          ? (v) => v == null ? l10n.validationRequired : null
          : null,
      builder: (field) {
        if (canSelectStaff &&
            _shouldAutoOpenStaff &&
            !_autoOpenStaffRequested) {
          _autoOpenStaffRequested = true;
          _shouldAutoOpenStaff = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showStaffPicker(context, availableStaff, field).whenComplete(() {
              if (!mounted) return;
              onAutoOpenStaffPickerCompleted?.call();
            });
          });
        }

        final hasError = field.hasError;
        final borderColor = hasError
            ? theme.colorScheme.error
            : theme.colorScheme.outline;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: canSelectStaff
                  ? () => _showStaffPicker(context, availableStaff, field)
                  : null,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.formStaff,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  suffixIcon: canSelectStaff
                      ? const Icon(Icons.arrow_drop_down)
                      : const Icon(Icons.lock_outline, size: 18),
                  enabled: canSelectStaff,
                ),
                child: Row(
                  children: [
                    if (selectedStaff != null) ...[
                      StaffCircleAvatar(
                        height: 32,
                        color: selectedStaff.color,
                        isHighlighted: false,
                        initials: selectedStaff.initials,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        selectedStaff?.name ?? l10n.selectStaffTitle,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError && field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    dynamic l10n,
    ThemeData theme,
  ) {
    final selectedService = item.serviceId != null
        ? services.where((s) => s.id == item.serviceId).firstOrNull
        : null;
    // Usa la durata dalla variante solo se item.durationMinutes non è impostato
    final variant = item.serviceVariantId != null
        ? variants.where((v) => v.id == item.serviceVariantId).firstOrNull
        : (item.serviceId != null
              ? variants.where((v) => v.serviceId == item.serviceId).firstOrNull
              : null);
    // Priorità: item.durationMinutes > variant.durationMinutes > 30
    final baseDuration = item.durationMinutes > 0
        ? item.durationMinutes
        : (variant?.durationMinutes ?? 30);
    final endTime = item.getEndTime(baseDuration);

    // Costruiamo sempre tre colonne (Start, End, Duration) in modo che
    // l'elemento "Start" assuma sempre le dimensioni che avrebbe quando
    // End e Duration sono visibili. Quando il servizio non è selezionato,
    // gli ultimi due vengono resi invisibili e non interattivi, ma mantengono
    // lo spazio.
    Widget buildInvisibleIfNoService(Widget w) {
      if (selectedService != null) return w;
      return IgnorePointer(child: Opacity(opacity: 0.0, child: w));
    }

    return Row(
      children: [
        // Start - sempre visibile
        Expanded(
          child: _TimeField(
            label: l10n.blockStartTime,
            time: item.startTime,
            onTap: () => _showStartTimePicker(context),
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),

        // End - visibile solo se servizio selezionato (non modificabile, si calcola dalla durata)
        Expanded(
          child: buildInvisibleIfNoService(
            _TimeField(
              label: l10n.blockEndTime,
              time: endTime,
              onTap:
                  null, // Disabilitato: l'orario di fine si calcola da inizio + durata
              theme: theme,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Duration - visibile/interattivo solo se servizio selezionato
        Expanded(
          child: buildInvisibleIfNoService(
            _DurationField(
              label: l10n.fieldDurationRequiredLabel.replaceAll(' *', ''),
              durationMinutes: baseDuration,
              onTap: () => _showDurationPicker(context, baseDuration),
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSelector(
    BuildContext context,
    dynamic l10n,
    ThemeData theme,
    ServiceVariant? selectedVariant,
  ) {
    // Prezzo di default dalla variante
    final defaultPrice = selectedVariant?.isFree == true
        ? 0.0
        : (selectedVariant?.price ?? 0.0);
    // Prezzo corrente: personalizzato o default
    final currentPrice = item.price ?? defaultPrice;
    final hasCustomPrice = item.price != null;

    return InkWell(
      onTap: () => _showPriceEditor(context, l10n, currentPrice, defaultPrice),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.appointmentPriceLabel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          isDense: true,
          suffixIcon: hasCustomPrice
              ? IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: l10n.appointmentPriceResetTooltip,
                  onPressed: () {
                    // Resetta al prezzo di default
                    onChanged(item.copyWithPriceCleared());
                  },
                )
              : null,
        ),
        child: Text(
          currentPrice == 0
              ? l10n.appointmentPriceFree
              : '€ ${currentPrice.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasCustomPrice ? theme.colorScheme.primary : null,
            fontWeight: hasCustomPrice ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showPriceEditor(
    BuildContext context,
    dynamic l10n,
    double currentPrice,
    double defaultPrice,
  ) {
    final controller = TextEditingController(
      text: currentPrice == 0 ? '' : currentPrice.toStringAsFixed(2),
    );

    if (formFactor != AppFormFactor.desktop) {
      AppBottomSheet.show(
        context: context,
        padding: EdgeInsets.zero,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appointmentPriceLabel,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.appointmentPriceHint,
                    prefixText: '€ ',
                    border: const OutlineInputBorder(),
                    helperText:
                        'Prezzo servizio: €${defaultPrice.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.actionCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final text = controller.text.trim().replaceAll(
                          ',',
                          '.',
                        );
                        final newPrice = text.isEmpty
                            ? 0.0
                            : (double.tryParse(text) ?? currentPrice);
                        Navigator.of(ctx).pop();
                        onChanged(item.copyWith(price: newPrice));
                      },
                      child: Text(l10n.actionConfirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.appointmentPriceLabel),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.appointmentPriceHint,
                prefixText: '€ ',
                border: const OutlineInputBorder(),
                helperText:
                    'Prezzo servizio: €${defaultPrice.toStringAsFixed(2)}',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim().replaceAll(',', '.');
                final newPrice = text.isEmpty
                    ? 0.0
                    : (double.tryParse(text) ?? currentPrice);
                Navigator.of(ctx).pop();
                onChanged(item.copyWith(price: newPrice));
              },
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );
    }
  }

  void _showStartTimePicker(BuildContext context) async {
    final l10n = context.l10n;

    if (formFactor != AppFormFactor.desktop) {
      final picked = await AppBottomSheet.show<TimeOfDay>(
        context: context,
        padding: EdgeInsets.zero,
        heightFactor: AppBottomSheet.defaultHeightFactor,
        builder: (ctx) => _TimeGridPicker(
          initial: item.startTime,
          includeTime: suggestedStartTime,
          stepMinutes: _startTimeStepMinutes,
          title: l10n.blockStartTime,
        ),
      );

      if (picked != null) {
        onStartTimeChanged(picked);
      }
    } else {
      final picked = await showDialog<TimeOfDay>(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _TimeGridPicker(
                initial: item.startTime,
                includeTime: suggestedStartTime,
                stepMinutes: _startTimeStepMinutes,
                title: l10n.blockStartTime,
                useSafeArea: false,
              ),
            ),
          ),
        ),
      );

      if (picked != null) {
        onStartTimeChanged(picked);
      }
    }
  }

  void _showDurationPicker(BuildContext context, int currentDuration) {
    final l10n = context.l10n;

    // Calcola i minuti disponibili fino a mezzanotte (24:00)
    final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
    final maxMinutesAvailable = (24 * 60) - startMinutes;

    // Durate selezionabili da 5 minuti a 6 ore con step fisso di 5 minuti.
    final allDurations = <int>[
      for (int m = 5; m <= 360; m += 5) m,
    ];
    final durations = allDurations
        .where((d) => d <= maxMinutesAvailable)
        .toList();

    // Se la durata corrente non è nella lista ma è valida, aggiungila
    if (currentDuration > 0 &&
        currentDuration <= maxMinutesAvailable &&
        !durations.contains(currentDuration)) {
      durations.add(currentDuration);
      durations.sort();
    }

    if (formFactor != AppFormFactor.desktop) {
      AppBottomSheet.show(
        context: context,
        padding: EdgeInsets.zero,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.fieldDurationRequiredLabel.replaceAll(' *', ''),
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...durations.map(
                  (d) => ListTile(
                    title: Text(_formatExtraDuration(d)),
                    trailing: d == currentDuration
                        ? Icon(
                            Icons.check,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onDurationChanged(d);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.fieldDurationRequiredLabel.replaceAll(' *', '')),
          content: SizedBox(
            width: 300,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: durations
                      .map(
                        (d) => ListTile(
                          title: Text(_formatDuration(d)),
                          trailing: d == currentDuration
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(ctx).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onDurationChanged(d);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours h';
    }
    return '$hours h $mins min';
  }

  Future<void> _showStaffPicker(
    BuildContext context,
    List<Staff> availableStaff,
    FormFieldState<int> field,
  ) async {
    final l10n = context.l10n;

    if (formFactor != AppFormFactor.desktop) {
      await AppBottomSheet.show(
        context: context,
        padding: EdgeInsets.zero,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.selectStaffTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                _StaffPickerContent(
                  staff: availableStaff,
                  selectedId: item.staffId,
                  onSelected: (staffId) {
                    Navigator.of(ctx).pop();
                    field.didChange(staffId);
                    field.validate();
                    onChanged(item.copyWith(staffId: staffId));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } else {
      // Per desktop, usa un dialog semplice con scroll
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.selectStaffTitle),
          content: SizedBox(
            width: 300,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: _StaffPickerContent(
                  staff: availableStaff,
                  selectedId: item.staffId,
                  onSelected: (staffId) {
                    Navigator.of(ctx).pop();
                    field.didChange(staffId);
                    field.validate();
                    onChanged(item.copyWith(staffId: staffId));
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

/// Widget per mostrare un campo orario cliccabile
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          isDense: true,
          enabled: !isDisabled,
        ),
        child: Text(
          '$hour:$minute',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDisabled
                ? theme.colorScheme.onSurface.withOpacity(0.5)
                : null,
          ),
        ),
      ),
    );
  }
}

class ExtraTimeCard extends StatefulWidget {
  const ExtraTimeCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.durationMinutes,
    required this.onStartTimeChanged,
    required this.onDurationChanged,
    required this.onRemove,
    required this.formFactor,
  });

  final String title;
  final TimeOfDay startTime;
  final int durationMinutes;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onRemove;
  final AppFormFactor formFactor;

  @override
  State<ExtraTimeCard> createState() => _ExtraTimeCardState();
}

class _ExtraTimeCardState extends State<ExtraTimeCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final endTime = _addMinutes(widget.startTime, widget.durationMinutes);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionClose,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: l10n.blockStartTime,
                    time: widget.startTime,
                    onTap: null,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeField(
                    label: l10n.blockEndTime,
                    time: endTime,
                    onTap: null,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DurationField(
                    label: l10n.fieldDurationRequiredLabel.replaceAll(' *', ''),
                    durationMinutes: widget.durationMinutes,
                    onTap: () =>
                        _showDurationPicker(context, widget.durationMinutes),
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  void _showDurationPicker(BuildContext context, int currentDuration) {
    final l10n = context.l10n;

    // Calcola i minuti disponibili fino a mezzanotte (24:00)
    final startMinutes = widget.startTime.hour * 60 + widget.startTime.minute;
    final maxMinutesAvailable = (24 * 60) - startMinutes;

    // Durate selezionabili da 5 minuti a 6 ore con step fisso di 5 minuti.
    final allDurations = <int>[
      for (int m = 5; m <= 360; m += 5) m,
    ];
    final durations = allDurations
        .where((d) => d <= maxMinutesAvailable)
        .toList();

    if (currentDuration > 0 &&
        currentDuration <= maxMinutesAvailable &&
        !durations.contains(currentDuration)) {
      durations.add(currentDuration);
      durations.sort();
    }

    if (widget.formFactor != AppFormFactor.desktop) {
      AppBottomSheet.show(
        context: context,
        padding: EdgeInsets.zero,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.fieldDurationRequiredLabel.replaceAll(' *', ''),
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...durations.map(
                  (d) => ListTile(
                    title: Text(_formatExtraDuration(d)),
                    trailing: d == currentDuration
                        ? Icon(
                            Icons.check,
                            color: Theme.of(ctx).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      widget.onDurationChanged(d);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.fieldDurationRequiredLabel.replaceAll(' *', '')),
          content: SizedBox(
            width: 320,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: durations.length,
              itemBuilder: (_, index) {
                final d = durations[index];
                return ListTile(
                  title: Text(_formatExtraDuration(d)),
                  trailing: d == currentDuration
                      ? Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onDurationChanged(d);
                  },
                );
              },
            ),
          ),
        ),
      );
    }
  }
}

/// Widget per mostrare un campo durata cliccabile
class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.label,
    required this.durationMinutes,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final int durationMinutes;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    String formatted;
    if (durationMinutes < 60) {
      formatted = '$durationMinutes min';
    } else {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      if (mins == 0) {
        formatted = '${hours}h';
      } else {
        formatted = '${hours}h ${mins}m';
      }
    }

    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          isDense: true,
          enabled: !isDisabled,
        ),
        child: Text(
          formatted,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDisabled
                ? theme.colorScheme.onSurface.withOpacity(0.5)
                : null,
          ),
        ),
      ),
    );
  }
}

class _TimeGridPicker extends StatefulWidget {
  const _TimeGridPicker({
    required this.initial,
    this.includeTime,
    required this.stepMinutes,
    required this.title,
    this.useSafeArea = true,
  });

  final TimeOfDay initial;
  final TimeOfDay? includeTime;
  final int stepMinutes;
  final String title;
  final bool useSafeArea;

  @override
  State<_TimeGridPicker> createState() => _TimeGridPickerState();
}

class _TimeGridPickerState extends State<_TimeGridPicker> {
  late final ScrollController _scrollController;
  late final List<TimeOfDay?> _entries;
  late int _scrollToIndex;
  int? _selectedIndex; // Index dell'orario da evidenziare (null se nessuno)

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _entries = <TimeOfDay?>[];
    for (int m = 0; m < LayoutConfig.hoursInDay * 60; m += widget.stepMinutes) {
      final h = m ~/ 60;
      final mm = m % 60;
      _entries.add(TimeOfDay(hour: h, minute: mm));
    }

    // Determina l'orario verso cui scrollare e se evidenziare
    final hasValidInitial =
        widget.initial.hour != 0 || widget.initial.minute != 0;
    final targetTime = _getTargetScrollTime();
    _scrollToIndex = _ensureTimeInEntries(targetTime);

    // Evidenzia solo se l'orario iniziale è valido (non 00:00)
    _selectedIndex = hasValidInitial ? _scrollToIndex : null;

    if (widget.includeTime != null &&
        !_isSameTime(widget.includeTime!, targetTime)) {
      _ensureTimeInEntries(widget.includeTime!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  /// Determina l'orario verso cui scrollare
  TimeOfDay _getTargetScrollTime() {
    // Se l'orario iniziale è diverso da 00:00, usalo
    if (widget.initial.hour != 0 || widget.initial.minute != 0) {
      return widget.initial;
    }

    // Altrimenti usa l'orario attuale arrotondato al prossimo step
    final now = TimeOfDay.now();
    final totalMinutes = now.hour * 60 + now.minute;
    final roundedMinutes =
        ((totalMinutes + widget.stepMinutes - 1) ~/ widget.stepMinutes) *
        widget.stepMinutes;

    // Limita a 23:45 massimo (o ultimo step valido)
    final maxMinutes =
        (LayoutConfig.hoursInDay - 1) * 60 + (60 - widget.stepMinutes);
    final clampedMinutes = roundedMinutes.clamp(0, maxMinutes);

    return TimeOfDay(hour: clampedMinutes ~/ 60, minute: clampedMinutes % 60);
  }

  bool _isSameTime(TimeOfDay a, TimeOfDay b) =>
      a.hour == b.hour && a.minute == b.minute;

  int _ensureTimeInEntries(TimeOfDay time) {
    final existingIndex = _entries.indexWhere(
      (t) => t != null && _isSameTime(t, time),
    );
    if (existingIndex >= 0) {
      return existingIndex;
    }

    final columnsPerRow = 60 ~/ widget.stepMinutes;
    final targetColumn = time.minute ~/ widget.stepMinutes;
    final baseIndex = (time.hour + 1) * columnsPerRow;

    final newRow = List<TimeOfDay?>.filled(columnsPerRow, null);
    newRow[targetColumn] = time;

    final insertIndex = baseIndex.clamp(0, _entries.length);
    _entries.insertAll(insertIndex, newRow);
    return insertIndex + targetColumn;
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    const crossAxisCount = 4;
    const mainAxisSpacing = 6.0;
    const childAspectRatio = 2.7;
    const padding = 12.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - padding * 2;
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * 6) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final rowHeight = itemHeight + mainAxisSpacing;

    final targetRow = _scrollToIndex ~/ crossAxisCount;

    final viewportHeight = _scrollController.position.viewportDimension;
    const headerOffset = 40.0;
    final targetOffset =
        (targetRow * rowHeight) -
        (viewportHeight / 2) +
        (rowHeight / 2) +
        headerOffset;

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
    final content = Padding(
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
                widget.title,
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
                if (t == null) {
                  return const SizedBox.shrink();
                }
                final isSelected =
                    _selectedIndex != null && index == _selectedIndex;
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.pop(context, t),
                  child: Text(DtFmt.hm(context, t.hour, t.minute)),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!widget.useSafeArea) {
      return content;
    }
    return SafeArea(child: content);
  }
}

class _StaffPickerContent extends StatelessWidget {
  const _StaffPickerContent({
    required this.staff,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Staff> staff;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (staff.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.noStaffAvailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final member in staff)
          ListTile(
            leading: StaffCircleAvatar(
              height: 36,
              color: member.color,
              isHighlighted: member.id == selectedId,
              initials: member.initials,
            ),
            title: Text('${member.name} ${member.surname}'.trim()),
            trailing: member.id == selectedId
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            selected: member.id == selectedId,
            onTap: () => onSelected(member.id),
          ),
      ],
    );
  }
}
