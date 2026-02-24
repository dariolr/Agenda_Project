import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/location_closure.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/agenda/providers/location_providers.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '/features/business/providers/closures_filter_provider.dart';
import '/features/business/providers/location_closures_provider.dart';
import '/features/business/widgets/closures_header.dart';
import 'dialogs/location_closure_dialog.dart' show LocationClosureDialog;

/// Schermata per gestire le chiusure della sede.
class LocationClosuresScreen extends ConsumerStatefulWidget {
  const LocationClosuresScreen({super.key});

  @override
  ConsumerState<LocationClosuresScreen> createState() =>
      _LocationClosuresScreenState();
}

class _LocationClosuresScreenState
    extends ConsumerState<LocationClosuresScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh al caricamento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(locationClosuresProvider);
    });
  }

  Future<void> _deleteClosure(LocationClosure closure) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.closuresDeleteConfirm),
        content: Text(l10n.closuresDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(locationClosuresProvider.notifier)
            .deleteClosure(closure.id);
      } catch (e) {
        if (mounted) {
          FeedbackDialog.showError(
            context,
            title: l10n.errorTitle,
            message: e.toString(),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final closuresAsync = ref.watch(locationClosuresProvider);
    final filterState = ref.watch(closuresFilterProvider);

    return Column(
      children: [
        // Header with period controls (closures-specific)
        const ClosuresHeader(),

        // Content
        Expanded(
          child: closuresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(error.toString()),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(locationClosuresProvider),
                    child: Text(l10n.actionRetry),
                  ),
                ],
              ),
            ),
            data: (closures) {
              // Filtra per range di date
              final filteredClosures = closures.where((c) {
                // Una chiusura è nel range se si sovrappone con il periodo filtro
                return !c.endDate.isBefore(filterState.startDate) &&
                    !c.startDate.isAfter(filterState.endDate);
              }).toList();

              if (filteredClosures.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildClosuresList(context, filteredClosures);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final filterState = ref.watch(closuresFilterProvider);
    final isAllSelected = filterState.selectedPreset == 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              isAllSelected ? l10n.closuresEmpty : l10n.closuresEmptyForPeriod,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.closuresEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosuresList(
    BuildContext context,
    List<LocationClosure> closures,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final todayOnly = ref.read(tenantTodayProvider);

    // Separa chiusure future e passate
    final futureClosures = closures
        .where((c) => !c.endDate.isBefore(todayOnly))
        .toList();
    final pastClosures = closures
        .where((c) => c.endDate.isBefore(todayOnly))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Chiusure future/in corso
        if (futureClosures.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.closuresUpcoming,
            totalDays: futureClosures.fold<int>(
              0,
              (sum, c) => sum + c.durationDays,
            ),
            icon: Icons.event,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          ...futureClosures.map(
            (c) => _ClosureCard(
              closure: c,
              isActive: c.containsDate(todayOnly),
              onEdit: () => LocationClosureDialog.show(context, closure: c),
              onDelete: () => _deleteClosure(c),
            ),
          ),
        ],

        // Chiusure precedenti
        if (pastClosures.isNotEmpty) ...[
          if (futureClosures.isNotEmpty) const SizedBox(height: 24),
          _SectionHeader(
            title: l10n.closuresPast,
            totalDays: pastClosures.fold<int>(
              0,
              (sum, c) => sum + c.durationDays,
            ),
            icon: Icons.history,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          ...pastClosures.map(
            (c) => _ClosureCard(
              closure: c,
              isPast: true,
              onEdit: () => LocationClosureDialog.show(context, closure: c),
              onDelete: () => _deleteClosure(c),
            ),
          ),
        ],

        // Padding per FAB
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int totalDays;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.totalDays,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.closuresTotalDays(totalDays),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureCard extends ConsumerWidget {
  final LocationClosure closure;
  final bool isPast;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClosureCard({
    required this.closure,
    this.isPast = false,
    this.isActive = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat.yMMMd(locale);

    // Get locations to display their names
    final locations = ref.watch(locationsProvider);

    final isSingleDay =
        closure.startDate.year == closure.endDate.year &&
        closure.startDate.month == closure.endDate.month &&
        closure.startDate.day == closure.endDate.day;

    final cardColor = isPast
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
        : null;

    // Build location names string
    String locationNames = '';
    if (locations.isNotEmpty) {
      final names = closure.locationIds
          .map(
            (id) => locations
                .firstWhere((l) => l.id == id, orElse: () => locations.first)
                .name,
          )
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.length == locations.length && locations.length > 1) {
        locationNames = l10n.closuresAllLocations;
      } else {
        locationNames = names.join(', ');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date icon/indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.error
                      : isPast
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      closure.startDate.day.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isActive || isPast
                            ? Colors.white
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      DateFormat.MMM(
                        locale,
                      ).format(closure.startDate).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            (isActive || isPast
                                    ? Colors.white
                                    : theme.colorScheme.onPrimaryContainer)
                                .withOpacity(0.8),
                        fontSize: 10,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSingleDay
                                ? dateFormat.format(closure.startDate)
                                : '${dateFormat.format(closure.startDate)} — ${dateFormat.format(closure.endDate)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPast ? theme.colorScheme.outline : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Duration and reason
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.closuresDays(closure.durationDays),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (closure.reason != null &&
                            closure.reason!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.notes,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              closure.reason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Location names
                    if (locationNames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationNames,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.outline),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 12),
                        Text(l10n.actionEdit),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.actionDelete,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
