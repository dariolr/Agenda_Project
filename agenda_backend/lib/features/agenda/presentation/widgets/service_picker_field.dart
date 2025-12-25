import 'package:flutter/material.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/extensions.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dividers.dart';

/// A form field for selecting a service, with services grouped by category.
///
/// On mobile: opens a bottom sheet with grouped services.
/// On desktop: opens a dialog with grouped services.
class ServicePickerField extends StatefulWidget {
  const ServicePickerField({
    super.key,
    required this.services,
    required this.categories,
    required this.formFactor,
    this.value,
    this.onChanged,
    this.onClear,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.autoOpenPicker = false,
    this.onAutoOpenPickerTriggered,
    this.onAutoOpenPickerCompleted,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final AppFormFactor formFactor;
  final int? value;
  final ValueChanged<int?>? onChanged;

  /// Callback chiamato quando l'utente preme l'icona di rimozione.
  /// Se null, l'icona non viene mostrata.
  final VoidCallback? onClear;
  final FormFieldValidator<int>? validator;
  final bool autoOpenPicker;
  final VoidCallback? onAutoOpenPickerTriggered;
  final VoidCallback? onAutoOpenPickerCompleted;

  /// Modalità di autovalidazione. Default: disabled (valida solo su submit).
  final AutovalidateMode autovalidateMode;

  @override
  State<ServicePickerField> createState() => _ServicePickerFieldState();
}

class _ServicePickerFieldState extends State<ServicePickerField> {
  final _formFieldKey = GlobalKey<FormFieldState<int>>();
  bool _autoPickerInvoked = false;
  bool _autoOpenInProgress = false;

  Service? get _selectedService {
    if (widget.value == null) return null;
    return widget.services.where((s) => s.id == widget.value).firstOrNull;
  }

  @override
  void didUpdateWidget(ServicePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aggiorna lo stato del FormField quando il valore cambia
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = _formFieldKey.currentState;
        if (state != null) {
          state.didChange(widget.value);
        }
      });
    }
    if (oldWidget.autoOpenPicker != widget.autoOpenPicker) {
      _autoPickerInvoked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      key: _formFieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (field) {
        final theme = Theme.of(context);
        final hasError = field.hasError;
        final borderColor = hasError
            ? theme.colorScheme.error
            : theme.colorScheme.outline;

        if (widget.autoOpenPicker && !_autoPickerInvoked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _autoPickerInvoked) return;
            _autoPickerInvoked = true;
            _autoOpenInProgress = true;
            _openPicker(field);
            widget.onAutoOpenPickerTriggered?.call();
          });
        }

        return InkWell(
          onTap: () => _openPicker(field),
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _selectedService != null
                  ? context.l10n.formService
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor),
              ),
              errorText: field.errorText,
              suffixIcon: _selectedService != null && widget.onClear != null
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      onPressed: widget.onClear,
                      tooltip: context.l10n.actionDelete,
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _selectedService?.name ?? context.l10n.selectService,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _selectedService == null
                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPicker(FormFieldState<int> field) async {
    if (widget.formFactor == AppFormFactor.desktop) {
      await _openDesktopDialogWithField(field);
    } else {
      await _openBottomSheetWithField(field);
    }
  }

  Future<void> _openBottomSheetWithField(FormFieldState<int> field) async {
    await AppBottomSheet.show<int>(
      context: context,
      heightFactor: AppBottomSheet.defaultHeightFactor,
      padding: EdgeInsets.zero,
      builder: (ctx) => _ServicePickerContent(
        services: widget.services,
        categories: widget.categories,
        selectedId: widget.value,
        onSelected: (id) {
          final wasAutoOpen = _autoOpenInProgress;
          Navigator.of(ctx).pop();
          field.didChange(id);
          field.validate(); // Ri-valida per rimuovere l'errore
          widget.onChanged?.call(id);
          if (wasAutoOpen) {
            _autoOpenInProgress = false;
            widget.onAutoOpenPickerCompleted?.call();
          }
        },
      ),
    );
    _autoOpenInProgress = false;
  }

  Future<void> _openDesktopDialogWithField(FormFieldState<int> field) async {
    await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 600,
            maxWidth: 720,
            maxHeight: 500,
          ),
          child: _ServicePickerContent(
            services: widget.services,
            categories: widget.categories,
            selectedId: widget.value,
            onSelected: (id) {
              final wasAutoOpen = _autoOpenInProgress;
              Navigator.of(ctx).pop();
              field.didChange(id);
              field.validate(); // Ri-valida per rimuovere l'errore
              widget.onChanged?.call(id);
              if (wasAutoOpen) {
                _autoOpenInProgress = false;
                widget.onAutoOpenPickerCompleted?.call();
              }
            },
          ),
        ),
      ),
    );
    _autoOpenInProgress = false;
  }
}

/// Content widget for the service picker (used in both bottom sheet and popup).
class _ServicePickerContent extends StatelessWidget {
  const _ServicePickerContent({
    required this.services,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final servicesByCategory = <int, List<Service>>{};
    for (final service in services) {
      (servicesByCategory[service.categoryId] ??= []).add(service);
    }

    final hasServicesMap = <int, bool>{
      for (final category in categories)
        category.id: (servicesByCategory[category.id]?.isNotEmpty ?? false),
    };

    // Sort categories like services section:
    // 1) non-empty before empty, 2) sortOrder, 3) name
    final sortedCategories = [...categories]
      ..sort((a, b) {
        final aEmpty = !(hasServicesMap[a.id] ?? false);
        final bEmpty = !(hasServicesMap[b.id] ?? false);
        if (aEmpty != bEmpty) return aEmpty ? 1 : -1;
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0
            ? so
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            l10n.formService,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const AppBottomSheetDivider(),
        // Service list
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedCategories.length,
            itemBuilder: (ctx, index) {
              final category = sortedCategories[index];
              final categoryServices =
                  (servicesByCategory[category.id] ?? []).toList()
                    ..sort((a, b) {
                      final so = a.sortOrder.compareTo(b.sortOrder);
                      return so != 0
                          ? so
                          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });

              if (categoryServices.isEmpty) {
                return const SizedBox.shrink();
              }

              return _CategorySection(
                category: category,
                services: categoryServices,
                selectedId: selectedId,
                onSelected: onSelected,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A section showing a category header and its services.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.services,
    required this.selectedId,
    required this.onSelected,
  });

  final ServiceCategory category;
  final List<Service> services;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colore di sfondo leggero per i servizi con indice pari (even)
    final interactionColors = theme.extension<AppInteractionColors>();
    final evenBackgroundColor =
        interactionColors?.alternatingRowFill ??
        theme.colorScheme.onSurface.withOpacity(0.04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category header with full-width background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          color: theme.colorScheme.primary,
          child: Center(
            child: Text(
              category.name.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Services con sfondo alternato (even)
        for (int i = 0; i < services.length; i++)
          _buildServiceTile(
            context,
            services[i],
            isEven: i.isEven,
            evenBackgroundColor: evenBackgroundColor,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    Service service, {
    required bool isEven,
    required Color evenBackgroundColor,
    required ThemeData theme,
  }) {
    final isSelected = service.id == selectedId;
    return Material(
      color: isEven ? evenBackgroundColor : Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(service.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(service.name)),
              if (isSelected)
                Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
