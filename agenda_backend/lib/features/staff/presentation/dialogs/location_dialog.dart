import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../../agenda/providers/location_providers.dart';
import '../../../auth/providers/auth_provider.dart';

Future<void> showLocationDialog(
  BuildContext context,
  WidgetRef ref, {
  Location? initial,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final dialog = _LocationDialog(initial: initial);

  await AppForm.show(
    context: context,
    builder: (_) => dialog,
    formFactor: formFactor,
    useRootNavigator: true,
    padding: EdgeInsets.zero,
    heightFactor: AppForm.defaultBottomSheetHeightFactor,
  );
}

class _LocationDialog extends ConsumerStatefulWidget {
  const _LocationDialog({this.initial});

  final Location? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends ConsumerState<_LocationDialog> {
  static const int _neverCancellationHours = 100000;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final Map<String, TextEditingController> _nomenclatureControllers = {};
  bool _isActive = true;
  int _minBookingNoticeHours = 1;
  int _maxBookingAdvanceDays = 90;
  int? _cancellationHours;
  bool _allowCustomerChooseStaff = true;
  String _staffIconKey = 'person';

  // Smart Slot Display Settings
  int _onlineBookingSlotIntervalMinutes = 15;
  String _slotDisplayMode = 'all';
  int _minGapMinutes = 30;

  // Opzioni disponibili per i dropdown
  static const _noticeHoursOptions = [1, 2, 4, 6, 12, 24, 48];
  static const _advanceDaysOptions = [7, 14, 30, 60, 90, 180, 365];
  static const List<int?> _cancellationHoursOptions = [
    null,
    0,
    1,
    2,
    4,
    8,
    12,
    24,
    48,
    72,
    96,
    120,
    168,
    _neverCancellationHours,
  ];

  String _formatCancellationPolicyValue(BuildContext context, int hours) {
    final l10n = context.l10n;
    if (hours == 0) {
      return l10n.teamLocationCancellationHoursAlways;
    }
    if (hours == _neverCancellationHours) {
      return l10n.teamLocationCancellationHoursNever;
    }
    if (hours >= 24 && hours % 24 == 0) {
      return l10n.teamLocationDays(hours ~/ 24);
    }
    return l10n.teamLocationHours(hours);
  }

  Widget _buildComboText(String text, {bool selected = false}) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: selected ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    final bleed = ref.read(formFactorProvider) == AppFormFactor.desktop
        ? 20.0
        : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform.translate(
          offset: Offset(-bleed, 0),
          child: SizedBox(
            width: constraints.maxWidth + (bleed * 2),
            child: const AppDivider(),
          ),
        );
      },
    );
  }

  static final List<int> _onlineBookingSlotIntervalOptions = [
    for (int minutes = 5; minutes <= 120; minutes += 5) minutes,
  ];
  static final List<int> _minGapOptions = [
    for (int minutes = 5; minutes <= 120; minutes += 5) minutes,
  ];
  static const List<String> _allowedNomenclatureKeys = [
    'location_step_label',
    'services_step_label',
    'staff_step_label',
    'location_title',
    'location_subtitle',
    'location_empty',
    'services_title',
    'services_subtitle',
    'services_empty_title',
    'services_empty_subtitle',
    'services_selected_none',
    'services_selected_one',
    'summary_services_label',
    'staff_title',
    'staff_subtitle',
    'staff_any_label',
    'staff_any_subtitle',
    'staff_empty',
    'no_staff_for_services',
    'error_invalid_service',
    'error_invalid_staff',
    'error_invalid_location',
    'error_staff_unavailable',
    'error_missing_services',
    'error_service_unavailable',
  ];

  static const List<String> _nomenclatureFieldOrder = _allowedNomenclatureKeys;
  static const List<String> _staffIconKeys = [
    'person',
    'door',
    'team',
    'tennis',
    'soccer',
    'resource',
    'room',
    'court',
    'equipment',
    'wellness',
    'medical',
    'beauty',
    'education',
    'pet',
    'generic',
  ];

  IconData _staffIconForKey(String key) {
    switch (key) {
      case 'person':
        return Icons.person;
      case 'door':
        return Icons.meeting_room_outlined;
      case 'team':
        return Icons.groups_outlined;
      case 'tennis':
        return Icons.sports_tennis_outlined;
      case 'soccer':
        return Icons.sports_soccer_outlined;
      case 'resource':
        return Icons.category_outlined;
      case 'room':
        return Icons.fitness_center_outlined;
      case 'court':
        return Icons.sports_tennis_outlined;
      case 'equipment':
        return Icons.handyman_outlined;
      case 'wellness':
        return Icons.spa_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'beauty':
        return Icons.auto_awesome_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'pet':
        return Icons.pets_outlined;
      case 'generic':
        return Icons.widgets_outlined;
      default:
        return Icons.person;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _addressController.text = widget.initial!.address ?? '';
      _emailController.text = widget.initial!.email ?? '';
      final defaultMap = widget.initial!.bookingTextOverrides?['default'];
      for (final key in _nomenclatureFieldOrder) {
        _nomenclatureControllers[key] = TextEditingController(
          text: defaultMap?[key] ?? '',
        );
      }
      // Retrocompatibilità: se esiste il vecchio campo "services_selected_many"
      // ma il nuovo campo unico è vuoto, riusa il suo valore.
      final legacyMany = defaultMap?['services_selected_many']?.trim();
      final summaryCtrl = _nomenclatureControllers['summary_services_label'];
      if (summaryCtrl != null &&
          summaryCtrl.text.trim().isEmpty &&
          legacyMany != null &&
          legacyMany.isNotEmpty) {
        summaryCtrl.text = legacyMany;
      }
      _isActive = widget.initial!.isActive;
      _minBookingNoticeHours = widget.initial!.minBookingNoticeHours;
      _maxBookingAdvanceDays = widget.initial!.maxBookingAdvanceDays;
      _cancellationHours = widget.initial!.cancellationHours;
      _allowCustomerChooseStaff = widget.initial!.allowCustomerChooseStaff;
      _staffIconKey = widget.initial!.staffIconKey;
      _onlineBookingSlotIntervalMinutes =
          widget.initial!.onlineBookingSlotIntervalMinutes;
      _slotDisplayMode = widget.initial!.slotDisplayMode;
      _minGapMinutes = widget.initial!.minGapMinutes;
    } else {
      // Nuova sede: nome volutamente vuoto (campo obbligatorio).
      _nameController.text = '';

      // Se esistono già sedi, usa come default i valori dell'ultima sede creata.
      final existingLocations = ref.read(locationsProvider);
      final lastLocation = existingLocations.isEmpty
          ? null
          : existingLocations.reduce((a, b) => a.id > b.id ? a : b);

      final defaultMap = lastLocation?.bookingTextOverrides?['default'];
      for (final key in _nomenclatureFieldOrder) {
        _nomenclatureControllers[key] = TextEditingController(
          text: defaultMap?[key] ?? '',
        );
      }

      if (lastLocation != null) {
        _isActive = lastLocation.isActive;
        _minBookingNoticeHours = lastLocation.minBookingNoticeHours;
        _maxBookingAdvanceDays = lastLocation.maxBookingAdvanceDays;
        _cancellationHours = lastLocation.cancellationHours;
        _allowCustomerChooseStaff = lastLocation.allowCustomerChooseStaff;
        _staffIconKey = lastLocation.staffIconKey;
        _onlineBookingSlotIntervalMinutes =
            lastLocation.onlineBookingSlotIntervalMinutes;
        _slotDisplayMode = lastLocation.slotDisplayMode;
        _minGapMinutes = lastLocation.minGapMinutes;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    for (final controller in _nomenclatureControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSuperadmin = ref.watch(
      authProvider.select((s) => s.user?.isSuperadmin ?? false),
    );
    final currentBusiness = ref.watch(currentBusinessProvider);
    final businessNotificationEmail = currentBusiness
        .onlineBookingsNotificationEmail
        ?.trim();
    final hasBusinessNotificationEmail =
        businessNotificationEmail != null &&
        businessNotificationEmail.isNotEmpty;
    final locationEmailHint = hasBusinessNotificationEmail
        ? businessNotificationEmail
        : l10n.teamLocationEmailHint;
    final isLocationEmailEmpty = _emailController.text.trim().isEmpty;
    final locationEmailLabel =
        isLocationEmailEmpty && !hasBusinessNotificationEmail
        ? l10n.teamLocationEmailLabel
        : l10n.teamLocationEmailHint;
    final title = widget.isEditing
        ? l10n.teamEditLocationTitle
        : l10n.teamNewLocationTitle;

    final actions = [
      AppOutlinedActionButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _isLoading ? null : _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    final nameField = LabeledFormField(
      label: l10n.teamLocationNameLabel,
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? l10n.validationRequired : null,
      ),
    );

    final addressField = LabeledFormField(
      label: l10n.teamLocationAddressLabel,
      child: TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );

    final emailField = LabeledFormField(
      label: locationEmailLabel,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: locationEmailHint,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null; // Optional
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(v.trim())) {
            return l10n.validationInvalidEmail;
          }
          return null;
        },
      ),
    );

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nameField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          addressField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          emailField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          _buildSectionDivider(context),
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamLocationOnlineBookingSettingsSection,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(l10n.teamLocationIsActiveLabel),
            subtitle: Text(
              l10n.teamLocationIsActiveHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isActive) ...[
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Sezione Limiti Prenotazione Online
            Text(
              l10n.teamLocationBookingLimitsSection,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l10n.teamLocationAllowCustomerChooseStaffLabel),
              subtitle: Text(
                l10n.teamLocationAllowCustomerChooseStaffHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _allowCustomerChooseStaff,
              onChanged: (v) => setState(() => _allowCustomerChooseStaff = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_allowCustomerChooseStaff) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              if (isSuperadmin)
                LabeledFormField(
                  label: l10n.teamLocationStaffIconKeyLabel,
                  child: DropdownButtonFormField<String>(
                    value: _staffIconKey,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: l10n.teamLocationStaffIconKeyHint,
                    ),
                    items: _staffIconKeys
                        .map(
                          (key) => DropdownMenuItem<String>(
                            value: key,
                            child: Center(
                              child: Icon(_staffIconForKey(key), size: 20),
                            ),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) {
                      return _staffIconKeys
                          .map(
                            (key) => Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(_staffIconForKey(key), size: 20),
                            ),
                          )
                          .toList();
                    },
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _staffIconKey = value);
                      }
                    },
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Preavviso minimo
            LabeledFormField(
              label: l10n.teamLocationMinBookingNoticeLabel,
              child: DropdownButtonFormField<int>(
                value: _minBookingNoticeHours,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationMinBookingNoticeHint,
                ),
                items: _noticeHoursOptions.map((hours) {
                  return DropdownMenuItem(
                    value: hours,
                    child: Text(l10n.teamLocationHours(hours)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _minBookingNoticeHours = v);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Anticipo massimo
            LabeledFormField(
              label: l10n.teamLocationMaxBookingAdvanceLabel,
              child: DropdownButtonFormField<int>(
                value: _maxBookingAdvanceDays,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationMaxBookingAdvanceHint,
                ),
                items: _advanceDaysOptions.map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text(l10n.teamLocationDays(days)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _maxBookingAdvanceDays = v);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            LabeledFormField(
              label: l10n.teamLocationCancellationHoursLabel,
              child: DropdownButtonFormField<int?>(
                value: _cancellationHours,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationCancellationHoursHint,
                ),
                items: _cancellationHoursOptions.map((hours) {
                  String label;
                  if (hours == null) {
                    final businessCancellationHours = ref
                        .read(currentBusinessProvider)
                        .cancellationHours;
                    if (businessCancellationHours != null) {
                      final businessPolicy = _formatCancellationPolicyValue(
                        context,
                        businessCancellationHours,
                      );
                      label = l10n
                          .teamLocationCancellationHoursUseBusinessWithValue(
                            businessPolicy,
                          );
                    } else {
                      label = l10n.teamLocationCancellationHoursUseBusiness;
                    }
                  } else if (hours == 0) {
                    label = l10n.teamLocationCancellationHoursAlways;
                  } else if (hours == _neverCancellationHours) {
                    label = l10n.teamLocationCancellationHoursNever;
                  } else if (hours >= 24 && hours % 24 == 0) {
                    label = l10n.teamLocationDays(hours ~/ 24);
                  } else {
                    label = l10n.teamLocationHours(hours);
                  }
                  return DropdownMenuItem<int?>(
                    value: hours,
                    child: _buildComboText(label),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return _cancellationHoursOptions.map((hours) {
                    String label;
                    if (hours == null) {
                      final businessCancellationHours = ref
                          .read(currentBusinessProvider)
                          .cancellationHours;
                      if (businessCancellationHours != null) {
                        final businessPolicy = _formatCancellationPolicyValue(
                          context,
                          businessCancellationHours,
                        );
                        label = l10n
                            .teamLocationCancellationHoursUseBusinessWithValue(
                              businessPolicy,
                            );
                      } else {
                        label = l10n.teamLocationCancellationHoursUseBusiness;
                      }
                    } else if (hours == 0) {
                      label = l10n.teamLocationCancellationHoursAlways;
                    } else if (hours == _neverCancellationHours) {
                      label = l10n.teamLocationCancellationHoursNever;
                    } else if (hours >= 24 && hours % 24 == 0) {
                      label = l10n.teamLocationDays(hours ~/ 24);
                    } else {
                      label = l10n.teamLocationHours(hours);
                    }
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: _buildComboText(label, selected: true),
                    );
                  }).toList();
                },
                onChanged: (v) {
                  setState(() => _cancellationHours = v);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            _buildSectionDivider(context),
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Sezione Smart Slot Display
            Text(
              l10n.teamLocationSmartSlotSection,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teamLocationSmartSlotDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            // Intervallo slot
            LabeledFormField(
              label: l10n.teamLocationSlotIntervalLabel,
              child: DropdownButtonFormField<int>(
                value: _onlineBookingSlotIntervalMinutes,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: l10n.teamLocationSlotIntervalHint,
                ),
                items: _onlineBookingSlotIntervalOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(l10n.teamLocationMinutes(minutes)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _onlineBookingSlotIntervalMinutes = v);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            // Modalità visualizzazione slot
            LabeledFormField(
              label: l10n.teamLocationSlotDisplayModeLabel,
              child: DropdownButtonFormField<String>(
                value: _slotDisplayMode,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText: _slotDisplayMode == 'all'
                      ? l10n.teamLocationSlotDisplayModeAllHint
                      : l10n.teamLocationSlotDisplayModeMinGapHint,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(l10n.teamLocationSlotDisplayModeAll),
                  ),
                  DropdownMenuItem(
                    value: 'min_gap',
                    child: Text(l10n.teamLocationSlotDisplayModeMinGap),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _slotDisplayMode = v);
                },
              ),
            ),
            // Gap minimo (visibile solo se min_gap mode)
            if (_slotDisplayMode == 'min_gap') ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              LabeledFormField(
                label: l10n.teamLocationMinGapLabel,
                child: DropdownButtonFormField<int>(
                  value: _minGapMinutes,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    helperText: l10n.teamLocationMinGapHint,
                  ),
                  items: _minGapOptions.map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text(l10n.teamLocationMinutes(minutes)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _minGapMinutes = v);
                  },
                ),
              ),
            ],
            if (isSuperadmin) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              _buildSectionDivider(context),
              const SizedBox(height: AppSpacing.formRowSpacing),
              Text(
                l10n.teamLocationNomenclatureSection,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.teamLocationNomenclatureEditorIntro,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ..._nomenclatureFieldOrder.map((key) {
                final controller = _nomenclatureControllers[key]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText: _nomenclatureDefaultHint(context, key),
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.formRowSpacing),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.formRowSpacing),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );

    if (ref.read(formFactorProvider) == AppFormFactor.desktop) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
          child: LocalLoadingOverlay(
            isLoading: _isLoading,
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
                      for (int i = 0; i < bottomActions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        bottomActions[i],
                      ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return LocalLoadingOverlay(
            isLoading: _isLoading,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            content,
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
                    const AppDivider(),
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
  }

  bool _isLoading = false;
  String? _error;

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final notifier = ref.read(locationsProvider.notifier);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    final bookingTextOverrides = isSuperadmin
        ? _buildBookingTextOverrides(context.l10n)
        : null;
    if (isSuperadmin && bookingTextOverrides == null && _error != null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.initial != null) {
        // Aggiorna location esistente
        await notifier.updateLocation(
          locationId: widget.initial!.id,
          name: name,
          address: address.isEmpty ? null : address,
          email: email.isEmpty ? null : email,
          isActive: _isActive,
          minBookingNoticeHours: _minBookingNoticeHours,
          maxBookingAdvanceDays: _maxBookingAdvanceDays,
          bookingTextOverrides: bookingTextOverrides,
          staffIconKey: isSuperadmin ? _staffIconKey : null,
          cancellationHours: _cancellationHours,
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
          onlineBookingSlotIntervalMinutes: _onlineBookingSlotIntervalMinutes,
          slotDisplayMode: _slotDisplayMode,
          minGapMinutes: _minGapMinutes,
        );
      } else {
        // Crea nuova location
        await notifier.create(
          name: name,
          address: address.isEmpty ? null : address,
          email: email.isEmpty ? null : email,
          isActive: _isActive,
          minBookingNoticeHours: _minBookingNoticeHours,
          maxBookingAdvanceDays: _maxBookingAdvanceDays,
          bookingTextOverrides: bookingTextOverrides,
          staffIconKey: isSuperadmin ? _staffIconKey : null,
          cancellationHours: _cancellationHours,
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _buildBookingTextOverrides(L10n l10n) {
    final normalized = <String, String>{};
    for (final entry in _nomenclatureControllers.entries) {
      final key = entry.key;
      final rawValue = entry.value.text;
      if (rawValue.trim().isEmpty) {
        continue;
      }
      // Preserve operator-entered casing exactly as typed.
      normalized[key] = rawValue;
    }

    if (normalized.isEmpty) {
      return null;
    }

    return {'default': normalized};
  }

  static const Map<String, Map<String, String>>
  _nomenclatureDefaultHintsByLanguage = {
    'it': {
      'location_step_label': 'Sede',
      'services_step_label': 'Servizi',
      'staff_step_label': 'Fornitore dei servizi',
      'location_title': 'Scegli la sede',
      'location_subtitle': 'Seleziona dove vuoi effettuare la prenotazione',
      'location_empty': 'Nessuna sede disponibile',
      'services_title': 'Scegli i servizi',
      'services_subtitle': 'Puoi selezionare uno o più servizi',
      'services_empty_title': 'Nessun servizio disponibile al momento',
      'services_empty_subtitle':
          'Non ci sono servizi prenotabili online per questa attività',
      'services_selected_none': 'Nessun servizio selezionato',
      'services_selected_one': '1 servizio selezionato',
      'summary_services_label': 'Servizi selezionati',
      'staff_title': 'Scegli il fornitore dei servizi',
      'staff_subtitle': 'Seleziona con chi desideri essere servito',
      'staff_any_label': 'Qualsiasi fornitore dei servizi disponibile',
      'staff_any_subtitle':
          'Ti assegneremo il primo fornitore dei servizi libero',
      'staff_empty': 'Nessun fornitore dei servizi disponibile al momento',
      'no_staff_for_services':
          'Nessun fornitore dei servizi può eseguire tutti i servizi selezionati. Prova a selezionare meno servizi o servizi diversi.',
      'error_invalid_service':
          'Uno o più servizi selezionati non sono disponibili',
      'error_invalid_staff':
          'Il fornitore dei servizi selezionato non è disponibile per questi servizi',
      'error_invalid_location': 'La sede selezionata non è disponibile',
      'error_staff_unavailable':
          'Il fornitore dei servizi selezionato non è disponibile in questo orario',
      'error_missing_services':
          'Impossibile recuperare i servizi della prenotazione',
      'error_service_unavailable': 'Servizio temporaneamente non disponibile',
    },
    'en': {
      'location_step_label': 'Location',
      'services_step_label': 'Services',
      'staff_step_label': 'Service provider',
      'location_title': 'Choose location',
      'location_subtitle': 'Select where you want to book',
      'location_empty': 'No location available',
      'services_title': 'Choose services',
      'services_subtitle': 'You can select one or more services',
      'services_empty_title': 'No services available at the moment',
      'services_empty_subtitle':
          'There are no services available for online booking at this business',
      'services_selected_none': 'No service selected',
      'services_selected_one': '1 service selected',
      'summary_services_label': 'Selected services',
      'staff_title': 'Choose service provider',
      'staff_subtitle': 'Select who you want to be served by',
      'staff_any_label': 'Any available service provider',
      'staff_any_subtitle':
          'We\'ll assign you the first available service provider',
      'staff_empty': 'No service provider available at the moment',
      'no_staff_for_services':
          'No service provider can perform all selected services. Try selecting fewer or different services.',
      'error_invalid_service':
          'One or more selected services are not available',
      'error_invalid_staff':
          'The selected service provider is not available for these services',
      'error_invalid_location': 'The selected location is not available',
      'error_staff_unavailable':
          'The selected service provider is not available at this time',
      'error_missing_services': 'Unable to load booking services',
      'error_service_unavailable': 'Service temporarily unavailable',
    },
  };

  String _nomenclatureDefaultHint(BuildContext context, String key) {
    final languageCode = _resolveDefaultLanguageCode(context);
    final defaults =
        _nomenclatureDefaultHintsByLanguage[languageCode] ??
        _nomenclatureDefaultHintsByLanguage['en']!;
    return defaults[key] ?? key;
  }

  String _resolveDefaultLanguageCode(BuildContext context) {
    // Fonte primaria: locale della location (derivato dal country code).
    final country = widget.initial?.country?.trim().toUpperCase();
    final locationLanguage = switch (country) {
      'IT' || 'SM' || 'VA' => 'it',
      'US' || 'GB' || 'IE' || 'AU' || 'CA' || 'NZ' => 'en',
      _ => null,
    };

    final supported = L10n.delegate.supportedLocales
        .map((l) => l.languageCode.toLowerCase())
        .toSet();

    if (locationLanguage != null && supported.contains(locationLanguage)) {
      return locationLanguage;
    }

    // Fallback: locale corrente dell'app.
    final appLanguage = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (supported.contains(appLanguage)) {
      return appLanguage;
    }

    // Ultimo fallback: prima lingua disponibile.
    return L10n.delegate.supportedLocales.first.languageCode.toLowerCase();
  }
}
