import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/location.dart';
import '/core/models/location_closure.dart';
import '/core/widgets/app_buttons.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/business/domain/public_holidays.dart';
import '/features/business/providers/location_closures_provider.dart';

/// Dialog per inserire automaticamente le festività nazionali.
class ImportHolidaysDialog extends ConsumerStatefulWidget {
  const ImportHolidaysDialog({
    super.key,
    required this.locations,
    required this.existingClosures,
  });

  final List<Location> locations;
  final List<LocationClosure> existingClosures;

  static Future<int?> show(
    BuildContext context, {
    required List<Location> locations,
    required List<LocationClosure> existingClosures,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImportHolidaysDialog(
        locations: locations,
        existingClosures: existingClosures,
      ),
    );
  }

  @override
  ConsumerState<ImportHolidaysDialog> createState() =>
      _ImportHolidaysDialogState();
}

class _ImportHolidaysDialogState extends ConsumerState<ImportHolidaysDialog> {
  static const int _minYearCount = 1;
  static const int _maxYearCount = 10;
  static const String _holidaysSourceUrl = 'https://date.nager.at';

  late int _baseYear;
  int _selectedYearCount = 1;
  final Set<int> _selectedLocationIds = {};
  final Set<int> _selectedHolidayIndices = {};
  bool _isSaving = false;
  bool _isLoadingHolidays = false;
  int _holidaysRequestId = 0;

  List<PublicHoliday> _holidays = const [];
  PublicHolidaysProvider? _localHolidaysProvider;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _baseYear = ref.read(tenantTodayProvider).year;

    // Seleziona tutte le location di default
    _selectedLocationIds.addAll(widget.locations.map((l) => l.id));

    // Determina il provider di festività dal paese della prima location
    final country = widget.locations.firstOrNull?.country;
    _countryCode = PublicHolidaysFactory.normalizeCountryCode(country);
    _localHolidaysProvider = PublicHolidaysFactory.getProvider(country);

    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    final countryCode = _countryCode;
    final localHolidaysProvider = _localHolidaysProvider;
    final years = List<int>.generate(
      _selectedYearCount,
      (index) => _baseYear + index,
    );

    final requestId = ++_holidaysRequestId;
    if (mounted) {
      setState(() => _isLoadingHolidays = true);
    }

    var loadedHolidays = <PublicHoliday>[];
    if (countryCode != null) {
      try {
        loadedHolidays = await PublicHolidaysFactory.fetchHolidaysFromApi(
          countryCode: countryCode,
          years: years,
        );
      } catch (_) {
        // Fallback locale sotto.
      }
    }

    if (loadedHolidays.isEmpty && localHolidaysProvider != null) {
      loadedHolidays = [
        for (final year in years) ...localHolidaysProvider.getHolidays(year),
      ]..sort((a, b) => a.date.compareTo(b.date));
    }

    if (!mounted || requestId != _holidaysRequestId) return;

    setState(() {
      _holidays = loadedHolidays;
      _selectedHolidayIndices.clear();
      for (var i = 0; i < _holidays.length; i++) {
        if (!_isHolidayAlreadyAdded(_holidays[i])) {
          _selectedHolidayIndices.add(i);
        }
      }
      _isLoadingHolidays = false;
    });
  }

  bool _isHolidayAlreadyAdded(PublicHoliday holiday) {
    // Una festività è già presente se esiste una chiusura con:
    // - stessa data di inizio
    // - stessa data di fine
    // - che copre tutte le location selezionate
    for (final closure in widget.existingClosures) {
      if (closure.startDate.year == holiday.date.year &&
          closure.startDate.month == holiday.date.month &&
          closure.startDate.day == holiday.date.day &&
          closure.endDate.year == holiday.date.year &&
          closure.endDate.month == holiday.date.month &&
          closure.endDate.day == holiday.date.day) {
        // Verifica che copra almeno una delle location selezionate
        final hasMatchingLocation = _selectedLocationIds.any(
          (id) => closure.locationIds.contains(id),
        );
        if (hasMatchingLocation) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _onSave() async {
    if (_selectedHolidayIndices.isEmpty || _selectedLocationIds.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(locationClosuresProvider.notifier);

      var count = 0;
      for (final index in _selectedHolidayIndices) {
        final holiday = _holidays[index];

        await notifier.addClosure(
          locationIds: _selectedLocationIds.toList(),
          startDate: holiday.date,
          endDate: holiday.date,
          reason: holiday.name,
        );
        count++;
      }

      if (mounted) {
        Navigator.of(context).pop(count);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _copySourceWebsiteLink() async {
    await Clipboard.setData(const ClipboardData(text: _holidaysSourceUrl));
    if (!mounted) return;
    await FeedbackDialog.showSuccess(
      context,
      title: context.l10n.closuresImportHolidaysLinkCopied,
      message: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final endYear = _baseYear + _selectedYearCount - 1;

    if (_countryCode == null && _localHolidaysProvider == null) {
      return AlertDialog(
        title: Text(l10n.closuresImportHolidaysTitle),
        content: Text(l10n.closuresImportHolidaysUnsupportedCountry),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      );
    }

    final dateFormat = DateFormat('EEEE d MMMM y', 'it');
    final alreadyAddedCount = _holidays.where(_isHolidayAlreadyAdded).length;

    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(l10n.closuresImportHolidaysTitle),
        content: AbsorbPointer(
          absorbing: _isSaving,
          child: SizedBox(
            width: 500,
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anno selector con pulsanti rapidi
            Row(
              children: [
                Text(l10n.closuresImportHolidaysYear),
                const SizedBox(width: 16),
                IconButton(
                  onPressed:
                      _isLoadingHolidays ||
                          _selectedYearCount <= _minYearCount
                      ? null
                      : () {
                          setState(() {
                            _selectedYearCount--;
                          });
                          _loadHolidays();
                        },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_selectedYearCount',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  onPressed:
                      _isLoadingHolidays ||
                          _selectedYearCount >= _maxYearCount
                      ? null
                      : () {
                          setState(() {
                            _selectedYearCount++;
                          });
                          _loadHolidays();
                        },
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    endYear == _baseYear
                        ? '$_baseYear'
                        : '$_baseYear - $endYear',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.closuresImportHolidaysExternalSourceInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _holidaysSourceUrl,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : _copySourceWebsiteLink,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location selector (se più di una)
            if (widget.locations.length > 1) ...[
              Text(
                l10n.closuresImportHolidaysLocations,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.locations.map((location) {
                  final isSelected = _selectedLocationIds.contains(location.id);
                  return FilterChip(
                    label: Text(location.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLocationIds.add(location.id);
                        } else {
                          _selectedLocationIds.remove(location.id);
                        }
                      });
                      _loadHolidays(); // Ricalcola quelle già aggiunte
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Info festività già presenti
            if (alreadyAddedCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.closuresImportHolidaysAlreadyAdded(
                          alreadyAddedCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Lista festività
            Text(
              l10n.closuresImportHolidaysList,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoadingHolidays
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _holidays.length,
                      itemBuilder: (context, index) {
                        final holiday = _holidays[index];
                        final isAlreadyAdded = _isHolidayAlreadyAdded(holiday);
                        final isSelected = _selectedHolidayIndices.contains(
                          index,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: isAlreadyAdded
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedHolidayIndices.add(index);
                                    } else {
                                      _selectedHolidayIndices.remove(index);
                                    }
                                  });
                                },
                          title: Text(
                            holiday.name,
                            style: TextStyle(
                              color: isAlreadyAdded
                                  ? colorScheme.outline
                                  : colorScheme.onSurface,
                              decoration: isAlreadyAdded
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            dateFormat.format(holiday.date),
                            style: TextStyle(
                              color: isAlreadyAdded
                                  ? colorScheme.outline
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          secondary: isAlreadyAdded
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    ),
            ),

            // Seleziona tutti / nessuno
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedHolidayIndices.clear();
                      for (var i = 0; i < _holidays.length; i++) {
                        if (!_isHolidayAlreadyAdded(_holidays[i])) {
                          _selectedHolidayIndices.add(i);
                        }
                      }
                    });
                  },
                  child: Text(l10n.actionSelectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedHolidayIndices.clear());
                  },
                  child: Text(l10n.actionDeselectAll),
                ),
              ],
            ),
          ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          AppAsyncFilledButton(
            onPressed:
                _selectedHolidayIndices.isEmpty ||
                    _selectedLocationIds.isEmpty ||
                    _isLoadingHolidays ||
                    _isSaving
                ? null
                : _onSave,
            isLoading: _isSaving,
            child: Text(
              l10n.closuresImportHolidaysAction(_selectedHolidayIndices.length),
            ),
          ),
        ],
      ),
    );
  }
}
