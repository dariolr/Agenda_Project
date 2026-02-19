import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../../agenda/providers/location_providers.dart';

Future<void> showLocationDialog(
  BuildContext context,
  WidgetRef ref, {
  Location? initial,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _LocationDialog(initial: initial);

  if (isDesktop) {
    await showDialog(context: context, builder: (_) => dialog);
  } else {
    await AppBottomSheet.show(
      context: context,
      builder: (_) => dialog,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

class _LocationDialog extends ConsumerStatefulWidget {
  const _LocationDialog({this.initial});

  final Location? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends ConsumerState<_LocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isActive = true;
  int _minBookingNoticeHours = 1;
  int _maxBookingAdvanceDays = 90;
  bool _allowCustomerChooseStaff = false;

  // Smart Slot Display Settings
  int _slotIntervalMinutes = 15;
  String _slotDisplayMode = 'all';
  int _minGapMinutes = 30;

  // Opzioni disponibili per i dropdown
  static const _noticeHoursOptions = [1, 2, 4, 6, 12, 24, 48];
  static const _advanceDaysOptions = [7, 14, 30, 60, 90, 180, 365];
  static final List<int> _slotIntervalOptions = [
    for (int minutes = 5; minutes <= 120; minutes += 5) minutes,
  ];
  static final List<int> _minGapOptions = [
    for (int minutes = 5; minutes <= 120; minutes += 5) minutes,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _addressController.text = widget.initial!.address ?? '';
      _emailController.text = widget.initial!.email ?? '';
      _isActive = widget.initial!.isActive;
      _minBookingNoticeHours = widget.initial!.minBookingNoticeHours;
      _maxBookingAdvanceDays = widget.initial!.maxBookingAdvanceDays;
      _allowCustomerChooseStaff = widget.initial!.allowCustomerChooseStaff;
      _slotIntervalMinutes = widget.initial!.slotIntervalMinutes;
      _slotDisplayMode = widget.initial!.slotDisplayMode;
      _minGapMinutes = widget.initial!.minGapMinutes;
    } else {
      // Pre-popola con il nome del business per nuove sedi
      final businessName = ref.read(currentBusinessProvider).name;
      _nameController.text = businessName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
      label: l10n.teamLocationEmailLabel,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: l10n.teamLocationEmailHint,
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
          const SizedBox(height: AppSpacing.formRowSpacing * 2),
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
              value: _slotIntervalMinutes,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: l10n.teamLocationSlotIntervalHint,
              ),
              items: _slotIntervalOptions.map((minutes) {
                return DropdownMenuItem(
                  value: minutes,
                  child: Text(l10n.teamLocationMinutes(minutes)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _slotIntervalMinutes = v);
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
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
          slotIntervalMinutes: _slotIntervalMinutes,
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
}
