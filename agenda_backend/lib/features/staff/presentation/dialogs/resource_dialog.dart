import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/resource.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../agenda/providers/resource_providers.dart';
import '../../../services/providers/service_categories_provider.dart';
import '../../../services/providers/services_provider.dart';
import '../widgets/resource_service_picker.dart';

Future<void> showResourceDialog(
  BuildContext context,
  WidgetRef ref, {
  required int locationId,
  Resource? resource,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _ResourceDialog(locationId: locationId, resource: resource);

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

class _ResourceDialog extends ConsumerStatefulWidget {
  const _ResourceDialog({required this.locationId, this.resource});

  final int locationId;
  final Resource? resource;

  bool get isEditing => resource != null;

  @override
  ConsumerState<_ResourceDialog> createState() => _ResourceDialogState();
}

class _ResourceDialogState extends ConsumerState<_ResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _noteController = TextEditingController();
  int _quantity = 1;
  bool _isSaving = false;

  // Servizi associati
  Set<int> _selectedServiceVariantIds = {};
  Set<int> _originalServiceVariantIds = {};
  bool _isLoadingServices = false;

  @override
  void initState() {
    super.initState();
    if (widget.resource != null) {
      _nameController.text = widget.resource!.name;
      _typeController.text = widget.resource!.type ?? '';
      _noteController.text = widget.resource!.note ?? '';
      _quantity = widget.resource!.quantity;
      _loadAssociatedServices();
    }
  }

  Future<void> _loadAssociatedServices() async {
    if (!widget.isEditing) return;

    setState(() => _isLoadingServices = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getResourceServices(widget.resource!.id);
      final services = response['services'] as List? ?? [];
      final variantIds = <int>{};
      for (final s in services) {
        variantIds.add(s['service_variant_id'] as int);
      }
      setState(() {
        _selectedServiceVariantIds = variantIds;
        _originalServiceVariantIds = {...variantIds};
      });
    } catch (e) {
      // Ignora errori di caricamento
    } finally {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(resourcesProvider.notifier);
      int resourceId;

      if (widget.isEditing) {
        resourceId = widget.resource!.id;
        await notifier.updateResource(
          resourceId: resourceId,
          name: _nameController.text.trim(),
          type: _typeController.text.trim().isEmpty
              ? null
              : _typeController.text.trim(),
          quantity: _quantity,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      } else {
        final newResource = await notifier.addResource(
          locationId: widget.locationId,
          name: _nameController.text.trim(),
          type: _typeController.text.trim().isEmpty
              ? null
              : _typeController.text.trim(),
          quantity: _quantity,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
        resourceId = newResource.id;
      }

      // Salva associazione servizi se modificata
      final servicesChanged = !_setEquals(
        _selectedServiceVariantIds,
        _originalServiceVariantIds,
      );
      if (servicesChanged) {
        final apiClient = ref.read(apiClientProvider);
        final servicesList = [
          for (final variantId in _selectedServiceVariantIds)
            {'service_variant_id': variantId, 'quantity': 1},
        ];
        await apiClient.setResourceServices(
          resourceId: resourceId,
          services: servicesList,
        );
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    final servicesAsync = ref.watch(servicesProvider);
    final services = servicesAsync.value ?? [];
    final categories = ref.watch(serviceCategoriesProvider);

    final title = widget.isEditing ? l10n.resourceEdit : l10n.resourceNew;

    final body = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledFormField(
              label: l10n.resourceNameLabel,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            LabeledFormField(
              label: l10n.resourceQuantityLabel,
              child: DropdownButtonFormField<int>(
                value: _quantity,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (int i = 1; i <= 10; i++)
                    DropdownMenuItem(value: i, child: Text('$i')),
                ],
                onChanged: (v) => setState(() => _quantity = v ?? 1),
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            LabeledFormField(
              label: l10n.resourceTypeLabel,
              child: TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),
            LabeledFormField(
              label: l10n.resourceNoteLabel,
              child: TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            // Sezione servizi associati
            if (services.isNotEmpty && categories.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.large),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.medium),
              _buildServicesSection(context, services, categories, formFactor),
            ],
          ],
        ),
      ),
    );

    final actions = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: AppButtonStyles.dialogButtonWidth,
          child: AppOutlinedActionButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context, rootNavigator: true).pop(),
            padding: AppButtonStyles.dialogButtonPadding,
            child: Text(l10n.actionCancel),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: AppButtonStyles.dialogButtonWidth,
          child: AppAsyncFilledButton(
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving,
            padding: AppButtonStyles.dialogButtonPadding,
            child: Text(l10n.actionSave),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(child: body),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: actions,
              ),
            ],
          ),
        ),
      );
    }

    // Mobile bottom sheet
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(child: body),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(
    BuildContext context,
    List<Service> services,
    List<ServiceCategory> categories,
    AppFormFactor formFactor,
  ) {
    final l10n = context.l10n;

    if (_isLoadingServices) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LabeledFormField(
      label: l10n.resourceServicesLabel,
      child: ResourceServicePicker(
        services: services,
        categories: categories,
        selectedServiceVariantIds: _selectedServiceVariantIds,
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedServiceVariantIds = newSelection;
          });
        },
        formFactor: formFactor,
      ),
    );
  }
}
