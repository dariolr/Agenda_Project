import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/utils/price_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service_package.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../providers/service_packages_provider.dart';
import '../widgets/service_eligibility_selector.dart';

Future<void> showServicePackageDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<Service> services,
  required List<ServiceCategory> categories,
  ServicePackage? package,
  int? preselectedCategoryId,
}) async {
  final formFactor = ref.read(formFactorProvider);

  final dialog = _ServicePackageDialog(
    services: services,
    categories: categories,
    package: package,
    preselectedCategoryId: preselectedCategoryId,
  );

  if (formFactor == AppFormFactor.mobile) {
    await AppBottomSheet.show<void>(
      context: context,
      useRootNavigator: true,
      heightFactor: 0.94,
      padding: EdgeInsets.zero,
      builder: (_) => dialog,
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (_) => dialog,
    );
  }
}

class _ServicePackageDialog extends ConsumerStatefulWidget {
  const _ServicePackageDialog({
    required this.services,
    required this.categories,
    this.package,
    this.preselectedCategoryId,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final ServicePackage? package;
  final int? preselectedCategoryId;

  @override
  ConsumerState<_ServicePackageDialog> createState() =>
      _ServicePackageDialogState();
}

class _ServicePackageDialogState extends ConsumerState<_ServicePackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _overridePriceController;
  late final TextEditingController _overrideDurationController;

  bool _isActive = true;
  bool _isSaving = false;
  int? _selectedCategoryId;
  String? _servicesError;
  List<int> _orderedServiceIds = [];

  Set<int> get _selectedServiceIds => _orderedServiceIds.toSet();

  @override
  void initState() {
    super.initState();
    final pkg = widget.package;
    _nameController = TextEditingController(text: pkg?.name ?? '');
    _descriptionController = TextEditingController(
      text: pkg?.description ?? '',
    );
    _overridePriceController = TextEditingController(
      text: pkg?.overridePrice?.toStringAsFixed(2) ?? '',
    );
    _overrideDurationController = TextEditingController(
      text: pkg?.overrideDurationMinutes?.toString() ?? '',
    );
    _isActive = pkg?.isActive ?? true;
    _selectedCategoryId =
        pkg?.categoryId ?? widget.preselectedCategoryId;
    if (_selectedCategoryId == null && widget.categories.length == 1) {
      _selectedCategoryId = widget.categories.first.id;
    }
    if (pkg != null) {
      final sortedItems = [...pkg.items]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _orderedServiceIds = sortedItems.map((item) => item.serviceId).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _overridePriceController.dispose();
    _overrideDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.package != null;
    final selectedCategoryId = _selectedCategoryId;
    final filteredCategories = selectedCategoryId == null
        ? widget.categories
        : widget.categories
            .where((c) => c.id == selectedCategoryId)
            .toList();
    final filteredServices = selectedCategoryId == null
        ? widget.services
        : widget.services
            .where((s) => s.categoryId == selectedCategoryId)
            .toList();

    return LocalLoadingOverlay(
      isLoading: _isSaving,
      child: AppFormDialog(
        title: Text(
          isEditing ? l10n.servicePackageEditTitle : l10n.servicePackageNewTitle,
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledFormField(
                label: l10n.servicePackageNameLabel,
                child: TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? l10n.validationRequired
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              LabeledFormField(
                label: l10n.fieldCategoryRequiredLabel,
                child: DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final category in widget.categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      final allowedIds = widget.services
                          .where((s) => s.categoryId == value)
                          .map((s) => s.id)
                          .toSet();
                      _orderedServiceIds = _orderedServiceIds
                          .where(allowedIds.contains)
                          .toList();
                      _servicesError = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? l10n.validationRequired : null,
                ),
              ),
              const SizedBox(height: 16),
              LabeledFormField(
                label: l10n.servicePackageDescriptionLabel,
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LabeledFormField(
                      label: l10n.servicePackageOverridePriceLabel,
                      child: TextFormField(
                        controller: _overridePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = PriceFormatter.parse(value);
                          if (parsed == null) {
                            return l10n.validationInvalidNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LabeledFormField(
                      label: l10n.servicePackageOverrideDurationLabel,
                      child: TextFormField(
                        controller: _overrideDurationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null) {
                            return l10n.validationInvalidNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: Text(l10n.servicePackageActiveLabel),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.servicePackageServicesLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: ServiceEligibilitySelector(
                        services: filteredServices,
                        categories: filteredCategories,
                        selectedServiceIds: _selectedServiceIds,
                        onChanged: _onServiceSelectionChanged,
                        showSelectAll: false,
                      ),
                    ),
                  ),
                ),
              ),
              if (_servicesError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _servicesError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.servicePackageOrderLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildOrderList(context, widget.services),
              const SizedBox(height: 24),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: AppButtonStyles.dialogButtonWidth,
            child: AppOutlinedActionButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(l10n.actionCancel),
            ),
          ),
          SizedBox(
            width: AppButtonStyles.dialogButtonWidth,
            child: AppFilledButton(
              onPressed: _isSaving ? null : _onSave,
              child: Text(l10n.actionSave),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Service> services) {
    if (_orderedServiceIds.isEmpty) {
      return Text(
        context.l10n.servicePackageNoServices,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final serviceMap = {for (final s in services) s.id: s};

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final moved = _orderedServiceIds.removeAt(oldIndex);
          _orderedServiceIds.insert(newIndex, moved);
        });
      },
      itemCount: _orderedServiceIds.length,
      itemBuilder: (context, index) {
        final serviceId = _orderedServiceIds[index];
        final serviceName = serviceMap[serviceId]?.name ?? '#$serviceId';
        return ListTile(
          key: ValueKey('pkg-$serviceId'),
          title: Text(serviceName),
          leading: const Icon(Icons.drag_indicator),
        );
      },
    );
  }

  void _onServiceSelectionChanged(Set<int> selected) {
    setState(() {
      final nextOrder = <int>[];
      for (final id in _orderedServiceIds) {
        if (selected.contains(id)) {
          nextOrder.add(id);
        }
      }
      for (final id in selected) {
        if (!nextOrder.contains(id)) {
          nextOrder.add(id);
        }
      }
      _orderedServiceIds = nextOrder;
      _servicesError = null;
    });
  }

  Future<void> _onSave() async {
    final l10n = context.l10n;
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) return;
    if (_selectedCategoryId == null) return;
    if (_orderedServiceIds.isEmpty) {
      setState(() {
        _servicesError = l10n.servicePackageServicesRequired;
      });
      return;
    }

    final overridePriceText = _overridePriceController.text.trim();
    final overrideDurationText = _overrideDurationController.text.trim();

    final overridePrice = overridePriceText.isEmpty
        ? null
        : PriceFormatter.parse(overridePriceText);
    final overrideDuration = overrideDurationText.isEmpty
        ? null
        : int.tryParse(overrideDurationText);

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(servicePackagesProvider.notifier);
      if (widget.package == null) {
        await notifier.createPackage(
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          serviceIds: _orderedServiceIds,
          overridePrice: overridePrice,
          overrideDurationMinutes: overrideDuration,
          isActive: _isActive,
        );
        if (mounted) {
          setState(() => _isSaving = false);
          await FeedbackDialog.showSuccess(
            context,
            title: l10n.servicePackageCreatedTitle,
            message: l10n.servicePackageCreatedMessage,
          );
        }
      } else {
        await notifier.updatePackage(
          packageId: widget.package!.id,
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          serviceIds: _orderedServiceIds,
          overridePrice: overridePrice,
          overrideDurationMinutes: overrideDuration,
          setOverridePriceNull: overridePriceText.isEmpty,
          setOverrideDurationNull: overrideDurationText.isEmpty,
          isActive: _isActive,
        );
        if (mounted) {
          setState(() => _isSaving = false);
          await FeedbackDialog.showSuccess(
            context,
            title: l10n.servicePackageUpdatedTitle,
            message: l10n.servicePackageUpdatedMessage,
          );
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        await FeedbackDialog.showError(
          context,
          title: l10n.errorTitle,
          message: l10n.servicePackageSaveError,
        );
      }
    }
  }
}
