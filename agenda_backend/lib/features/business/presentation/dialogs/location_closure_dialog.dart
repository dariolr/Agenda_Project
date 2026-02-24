import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/location_closure.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/business/providers/location_closures_provider.dart';

/// Dialog per creare o modificare una chiusura (multi-location)
class LocationClosureDialog extends ConsumerStatefulWidget {
  final LocationClosure? closure;

  const LocationClosureDialog({super.key, this.closure});

  static Future<bool?> show(BuildContext context, {LocationClosure? closure}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => LocationClosureDialog(closure: closure),
    );
  }

  @override
  ConsumerState<LocationClosureDialog> createState() =>
      _LocationClosureDialogState();
}

class _LocationClosureDialogState extends ConsumerState<LocationClosureDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;

  late DateTime _startDate;
  late DateTime _endDate;
  late Set<int> _selectedLocationIds;
  bool _isSaving = false;

  bool get isEditing => widget.closure != null;

  @override
  void initState() {
    super.initState();
    final today = ref.read(tenantTodayProvider);
    _startDate = widget.closure?.startDate ?? today;
    _endDate = widget.closure?.endDate ?? today;
    _reasonController = TextEditingController(
      text: widget.closure?.reason ?? '',
    );

    // Initialize selected locations from existing closure or empty
    _selectedLocationIds = widget.closure?.locationIds.toSet() ?? {};
    // Auto-select single location will be done in build() after we have the locations list
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await _showAutoCloseDatePicker(
      initialDate: _startDate,
      firstDate: ref.read(tenantNowProvider).subtract(const Duration(days: 365)),
      lastDate: ref.read(tenantNowProvider).add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        // Se la data fine è prima della nuova data inizio, aggiornala
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await _showAutoCloseDatePicker(
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: ref.read(tenantNowProvider).add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  /// Mostra un date picker che si chiude automaticamente alla selezione
  Future<DateTime?> _showAutoCloseDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => _AutoCloseDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  void _toggleLocation(int locationId) {
    setState(() {
      if (_selectedLocationIds.contains(locationId)) {
        _selectedLocationIds.remove(locationId);
      } else {
        _selectedLocationIds.add(locationId);
      }
    });
  }

  void _selectAllLocations(List<int> allLocationIds) {
    setState(() {
      _selectedLocationIds = allLocationIds.toSet();
    });
  }

  void _deselectAllLocations() {
    setState(() {
      _selectedLocationIds.clear();
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validazione date
    if (_endDate.isBefore(_startDate)) {
      FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.closuresInvalidDateRange,
      );
      return;
    }

    // Validazione location
    if (_selectedLocationIds.isEmpty) {
      FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.closuresSelectAtLeastOneLocation,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(locationClosuresProvider.notifier);

      if (isEditing) {
        await notifier.updateClosure(
          closureId: widget.closure!.id,
          locationIds: _selectedLocationIds.toList(),
          startDate: _startDate,
          endDate: _endDate,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        );
      } else {
        await notifier.addClosure(
          locationIds: _selectedLocationIds.toList(),
          startDate: _startDate,
          endDate: _endDate,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Gestisci errore overlap
        if (errorMessage.contains('409') ||
            errorMessage.toLowerCase().contains('overlap')) {
          errorMessage = context.l10n.closuresOverlapError;
        }
        FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );
    final locations = ref.watch(locationsProvider);
    final hasMultipleLocations = locations.length > 1;

    // Auto-select single location for new closures
    if (!isEditing && locations.length == 1 && _selectedLocationIds.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedLocationIds.isEmpty) {
          setState(() {
            _selectedLocationIds.add(locations.first.id);
          });
        }
      });
    }

    final durationDays = _endDate.difference(_startDate).inDays + 1;

    // Build location selection widget (only if multiple locations)
    Widget? locationSelectionWidget;
    if (locations.isEmpty) {
      locationSelectionWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.closuresNoLocations,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    } else if (hasMultipleLocations) {
      final allLocationIds = locations.map((l) => l.id).toList();
      final allSelected = _selectedLocationIds.length == locations.length;

      locationSelectionWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with select all/none
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.closuresLocations,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: allSelected
                    ? _deselectAllLocations
                    : () => _selectAllLocations(allLocationIds),
                child: Text(
                  allSelected
                      ? l10n.closuresDeselectAll
                      : l10n.closuresSelectAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location checkboxes
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedLocationIds.isEmpty
                    ? theme.colorScheme.error
                    : theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: locations.map((location) {
                final isSelected = _selectedLocationIds.contains(location.id);
                return CheckboxListTile(
                  title: Text(location.name),
                  subtitle: (location.address?.isNotEmpty ?? false)
                      ? Text(
                          location.address!,
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  value: isSelected,
                  onChanged: (_) => _toggleLocation(location.id),
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_selectedLocationIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                l10n.closuresSelectAtLeastOneLocation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      );
    }

    return AlertDialog(
      title: Text(isEditing ? l10n.closuresEditTitle : l10n.closuresNewTitle),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker row
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: l10n.closuresStartDate,
                        value: _startDate,
                        dateFormat: dateFormat,
                        onTap: _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DatePickerField(
                        label: l10n.closuresEndDate,
                        value: _endDate,
                        dateFormat: dateFormat,
                        onTap: _selectEndDate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Duration info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.closuresDays(durationDays),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Location selection (only if multiple locations)
                if (locationSelectionWidget != null) ...[
                  locationSelectionWidget,
                  const SizedBox(height: 24),
                ],

                // Reason field
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.closuresReason,
                    hintText: l10n.closuresReasonHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppAsyncFilledButton(
          onPressed: _isSaving ? null : _onSave,
          isLoading: _isSaving,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateFormat.format(value), style: theme.textTheme.bodyLarge),
            Icon(
              Icons.calendar_month,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog con CalendarDatePicker che si chiude automaticamente alla selezione
class _AutoCloseDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AutoCloseDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_AutoCloseDatePickerDialog> createState() =>
      _AutoCloseDatePickerDialogState();
}

class _AutoCloseDatePickerDialogState
    extends State<_AutoCloseDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onDateChanged: (date) {
                // Chiudi il dialog e ritorna la data selezionata
                Navigator.of(context).pop(date);
              },
            ),
            // Pulsante Annulla
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
