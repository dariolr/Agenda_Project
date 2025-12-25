import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_constants.dart';
import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/widgets/staff_circle_avatar.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/staff.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../services/presentation/widgets/service_eligibility_selector.dart';
import '../../../services/providers/service_categories_provider.dart';
import '../../../services/providers/services_provider.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../../agenda/providers/location_providers.dart';
import '../../providers/staff_providers.dart';

Future<void> showStaffDialog(
  BuildContext context,
  WidgetRef ref, {
  Staff? initial,
  int? initialLocationId,
  bool duplicateFrom = false,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _StaffDialog(
    initial: initial,
    initialLocationId: initialLocationId,
    isDuplicating: duplicateFrom,
  );

  if (isDesktop) {
    await showDialog(context: context, builder: (_) => dialog);
  } else {
    await AppBottomSheet.show(
      context: context,
      builder: (_) => dialog,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

class _StaffDialog extends ConsumerStatefulWidget {
  const _StaffDialog({
    this.initial,
    this.initialLocationId,
    this.isDuplicating = false,
  });

  final Staff? initial;
  final int? initialLocationId;
  final bool isDuplicating;

  bool get isEditing => initial != null && !isDuplicating;

  @override
  ConsumerState<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();

  late Color _selectedColor;
  final ScrollController _colorScrollController = ScrollController();
  final Set<int> _selectedLocationIds = {};
  final Set<int> _selectedServiceIds = {};
  String? _locationsError;
  bool _isSelectingServices = false;
  bool _isSelectingLocations = false;
  bool _isBookableOnline = true;
  bool _didAutoScrollColor = false;

  static const List<Color> _palette = [
    // Gialli / Amber (alto contrasto)
    Color(0xFFFFC400),
    Color(0xFFFFA000),
    // Arancioni
    Color(0xFFFF6D00),
    Color(0xFFFF3D00),
    // Rossi
    Color(0xFFD50000),
    Color(0xFFB71C1C),
    // Magenta / Rosa
    Color(0xFFF50057),
    Color(0xFFC51162),
    // Viola
    Color(0xFFAA00FF),
    Color(0xFF6200EA),
    // Indaco
    Color(0xFF304FFE),
    Color(0xFF1A237E),
    // Blu
    Color(0xFF2962FF),
    Color(0xFF1565C0),
    // Azzurro
    Color(0xFF0091EA),
    Color(0xFF00B0FF),
    // Ciano
    Color(0xFF00B8D4),
    Color(0xFF00838F),
    // Teal / Turchese
    Color(0xFF00BFA5),
    Color(0xFF00796B),
    // Verdi
    Color(0xFF00C853),
    Color(0xFF2E7D32),
    // Lime / Verde acido
    Color(0xFF76FF03),
    Color(0xFFAEEA00),
    // Extra diversità
    Color(0xFFFF9100),
    Color(0xFFE65100),
    Color(0xFFAD1457),
    Color(0xFF7B1FA2),
    Color(0xFF3949AB),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF558B2F),
    Color(0xFF01579B),
    Color(0xFF006064),
    Color(0xFF4E342E),
    Color(0xFF37474F),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedColor = initial?.color ?? _palette.first;
    if (initial != null) {
      if (widget.isDuplicating) {
        final existingNames =
            ref.read(allStaffProvider).map((s) => s.displayName).toSet();
        var base = initial.displayName;
        var candidate = '$base Copia';
        var i = 1;
        while (existingNames.contains(candidate)) {
          candidate = '$base Copia $i';
          i++;
        }
        final parts = candidate.split(' ');
        _nameController.text = parts.first;
        _surnameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : initial.surname;
      } else {
        _nameController.text = initial.name;
        _surnameController.text = initial.surname;
      }
      if (kAllowStaffMultiLocationSelection) {
        _selectedLocationIds.addAll(initial.locationIds);
      } else if (initial.locationIds.isNotEmpty) {
        _selectedLocationIds.add(initial.locationIds.first);
      }
      _isBookableOnline = initial.isBookableOnline;
      _selectedServiceIds.addAll(
        ref.read(eligibleServicesForStaffProvider(initial.id)),
      );
    } else if (widget.initialLocationId != null) {
      _selectedLocationIds.add(widget.initialLocationId!);
    }
    _nameController.addListener(_handleNameChange);
    _surnameController.addListener(_handleNameChange);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChange);
    _surnameController.removeListener(_handleNameChange);
    _nameController.dispose();
    _surnameController.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  void _handleNameChange() {
    if (!mounted) return;
    setState(() {});
  }

  String _buildInitials() {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final fullName = [name, surname].where((p) => p.isNotEmpty).join(' ');
    return initialsFromName(fullName, maxChars: 3);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title =
        widget.isEditing ? l10n.teamEditStaffTitle : l10n.teamNewStaffTitle;
    final formFactor = ref.read(formFactorProvider);
    final isSingleColumn = formFactor != AppFormFactor.desktop;
    final locations = ref.watch(locationsProvider);
    final totalServicesCount = ref.watch(servicesProvider).length;
    final totalLocationsCount = locations.length;
    final selectedLocationName = !kAllowStaffMultiLocationSelection &&
            _selectedLocationIds.isNotEmpty
        ? locations
            .firstWhere(
              (loc) => loc.id == _selectedLocationIds.first,
              orElse: () => locations.first,
            )
            .name
        : null;
    if (!_didAutoScrollColor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_colorScrollController.hasClients) return;
        final index =
            _palette.indexWhere((c) => c.value == _selectedColor.value);
        if (index < 0) return;
        const double colorItemSize = 36;
        const double colorItemSpacing = 10;
        const double colorListPadding = 4;
        final viewport = _colorScrollController.position.viewportDimension;
        final target =
            index * (colorItemSize + colorItemSpacing) -
            (viewport - colorItemSize) / 2 -
            colorListPadding;
        final max = _colorScrollController.position.maxScrollExtent;
        _colorScrollController.jumpTo(target.clamp(0.0, max));
      });
      _didAutoScrollColor = true;
    }

    final actions = [
      AppOutlinedActionButton(
        onPressed: () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _onSave,
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
      label: l10n.teamStaffNameLabel,
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        validator: (v) =>
            v == null || v.trim().isEmpty ? l10n.validationRequired : null,
      ),
    );

    final surnameField = LabeledFormField(
      label: l10n.teamStaffSurnameLabel,
      child: TextFormField(
        controller: _surnameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
      ),
    );

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSingleColumn) ...[
            nameField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            surnameField,
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: nameField),
                const SizedBox(width: AppSpacing.formFieldSpacing),
                Expanded(child: surnameField),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamStaffColorLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
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
                        controller: _colorScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _palette.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final color = _palette[index];
                          final initials = _buildInitials();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              child: StaffCircleAvatar(
                                height: 36,
                                color: color,
                                isHighlighted: _selectedColor == color,
                                initials: initials,
                              ),
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
          const SizedBox(height: AppSpacing.formRowSpacing),
          if (!kAllowStaffMultiLocationSelection) ...[
            Text(
              l10n.teamLocationLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 48,
            child: AppOutlinedActionButton(
              onPressed: _openLocationsSelector,
              expand: true,
              padding: AppButtonStyles.defaultPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        kAllowStaffMultiLocationSelection
                            ? l10n.teamChooseLocationsButton
                            : (selectedLocationName ??
                                l10n.teamChooseLocationSingleButton),
                      ),
                    ),
                  ),
                  if (kAllowStaffMultiLocationSelection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedLocationIds.length}/$totalLocationsCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_locationsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _locationsError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamServicesLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: AppOutlinedActionButton(
              onPressed: _openServicesSelector,
              expand: true,
              padding: AppButtonStyles.defaultPadding,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(l10n.teamSelectedServicesButton),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.teamSelectedServicesCount(
                          _selectedServiceIds.length,
                          totalServicesCount,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          _SwitchTile(
            title: l10n.teamStaffBookableOnlineLabel,
            value: _isBookableOnline,
            onChanged: (v) => setState(() => _isBookableOnline = v),
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          if (kAllowStaffMultiLocationSelection)
            Text(
              l10n.teamStaffMultiLocationWarning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );

    if (ref.read(formFactorProvider) == AppFormFactor.desktop) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
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
      );
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
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
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          content,
                          const SizedBox(height: 24),
                          const SizedBox(height: AppSpacing.formRowSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0x1F000000),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: bottomActions,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationIds.isEmpty) {
      setState(() => _locationsError = context.l10n.validationRequired);
      return;
    }
    if (!kAllowStaffMultiLocationSelection &&
        _selectedLocationIds.length > 1) {
      final firstId = _selectedLocationIds.first;
      _selectedLocationIds
        ..clear()
        ..add(firstId);
    }
    final notifier = ref.read(allStaffProvider.notifier);
    final business = ref.read(currentBusinessProvider);
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final isEditing = widget.isEditing;
    final staffId = isEditing ? widget.initial!.id : notifier.nextId();

    if (isEditing) {
      notifier.update(
        widget.initial!.copyWith(
          name: name,
          surname: surname,
          color: _selectedColor,
          locationIds: _selectedLocationIds.toList(),
          isBookableOnline: _isBookableOnline,
        ),
      );
    } else {
      notifier.add(
        Staff(
          id: staffId,
          businessId: business.id,
          name: name,
          surname: surname,
          color: _selectedColor,
          locationIds: _selectedLocationIds.toList(),
          sortOrder: notifier.nextSortOrderForLocations(_selectedLocationIds),
          isBookableOnline: _isBookableOnline,
        ),
      );
    }
    ref.read(serviceStaffEligibilityProvider.notifier).setEligibleServicesForStaff(
          staffId: staffId,
          locationId: ref.read(currentLocationProvider).id,
          serviceIds: _selectedServiceIds,
        );
    Navigator.of(context).pop();
  }

  Future<void> _openServicesSelector() async {
    if (_isSelectingServices) return;
    setState(() => _isSelectingServices = true);
    final l10n = context.l10n;
    final services = ref.read(servicesProvider);
    final categories = ref.read(serviceCategoriesProvider);
    final formFactor = ref.read(formFactorProvider);
    Set<int> current = {..._selectedServiceIds};

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
                  minWidth: 600,
                  maxWidth: 720,
                  maxHeight: 560,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        l10n.teamEligibleServicesLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: ServiceEligibilitySelector(
                            services: services,
                            categories: categories,
                            selectedServiceIds: current,
                            onChanged: (value) => setStateLocal(() {
                              current = {...value};
                            }),
                          ),
                        ),
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
                      l10n.teamEligibleServicesLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: ServiceEligibilitySelector(
                          services: services,
                          categories: categories,
                          selectedServiceIds: current,
                          onChanged: (value) => setStateLocal(() {
                            current = {...value};
                          }),
                        ),
                      ),
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
      _selectedServiceIds
        ..clear()
        ..addAll(current);
      _isSelectingServices = false;
    });
  }

  Future<void> _openLocationsSelector() async {
    if (_isSelectingLocations) return;
    setState(() => _isSelectingLocations = true);
    final l10n = context.l10n;
    final locations = ref.read(locationsProvider);
    final formFactor = ref.read(formFactorProvider);
    Set<int> current = {..._selectedLocationIds};

    Widget buildLocationRows(void Function(VoidCallback) setStateLocal) {
      final allIds = [for (final l in locations) l.id];
      final allSelected =
          allIds.isNotEmpty && allIds.every(current.contains);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kAllowStaffMultiLocationSelection) ...[
            _SelectableRow(
              label: l10n.teamSelectAllLocations,
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
          ],
          for (final loc in locations)
            _SelectableRow(
              label: loc.name,
              selected: current.contains(loc.id),
              onTap: () {
                if (kAllowStaffMultiLocationSelection) {
                  if (current.contains(loc.id)) {
                    current.remove(loc.id);
                  } else {
                    current.add(loc.id);
                  }
                } else {
                  current
                    ..clear()
                    ..add(loc.id);
                }
                setStateLocal(() {});
                if (!kAllowStaffMultiLocationSelection) {
                  Navigator.of(context).pop();
                }
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
                  minWidth: 600,
                  maxWidth: 720,
                  maxHeight: 560,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        kAllowStaffMultiLocationSelection
                            ? l10n.teamChooseLocationsButton
                            : l10n.teamChooseLocationSingleButton,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: buildLocationRows(setStateLocal),
                        ),
                      ),
                    ),
                    if (kAllowStaffMultiLocationSelection) ...[
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
                      kAllowStaffMultiLocationSelection
                          ? l10n.teamChooseLocationsButton
                          : l10n.teamChooseLocationSingleButton,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: buildLocationRows(setStateLocal),
                      ),
                    ),
                  ),
                  if (kAllowStaffMultiLocationSelection) ...[
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
      _selectedLocationIds
        ..clear()
        ..addAll(current);
      _locationsError = null;
      _isSelectingLocations = false;
    });
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final borderRadius = AppButtonStyles.defaultBorderRadius;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: AppButtonStyles.defaultPadding,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
        borderRadius: borderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: titleStyle),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            activeTrackColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.35),
          ),
        ],
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
