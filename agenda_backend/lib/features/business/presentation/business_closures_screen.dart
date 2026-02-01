import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/business_closure.dart';
import '/core/widgets/feedback_dialog.dart';
import '/features/business/providers/business_closures_provider.dart';
import 'dialogs/business_closure_dialog.dart';

/// Schermata per gestire le chiusure dell'attività
class BusinessClosuresScreen extends ConsumerStatefulWidget {
  const BusinessClosuresScreen({super.key});

  @override
  ConsumerState<BusinessClosuresScreen> createState() =>
      _BusinessClosuresScreenState();
}

class _BusinessClosuresScreenState
    extends ConsumerState<BusinessClosuresScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh al caricamento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(businessClosuresProvider);
    });
  }

  Future<void> _deleteClosure(BusinessClosure closure) async {
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
            .read(businessClosuresProvider.notifier)
            .deleteClosure(closure.id);
        if (mounted) {
          FeedbackDialog.showSuccess(
            context,
            title: l10n.closuresDeleteSuccess,
            message: '',
          );
        }
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
    final closuresAsync = ref.watch(businessClosuresProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closuresTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(businessClosuresProvider),
            tooltip: l10n.actionRefresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BusinessClosureDialog.show(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.closuresNewTitle),
      ),
      body: closuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(error.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(businessClosuresProvider),
                child: Text(l10n.actionRetry),
              ),
            ],
          ),
        ),
        data: (closures) {
          if (closures.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildClosuresList(context, closures);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              l10n.closuresEmpty,
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
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => BusinessClosureDialog.show(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.closuresNewTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosuresList(
    BuildContext context,
    List<BusinessClosure> closures,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

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
            count: futureClosures.length,
            icon: Icons.event,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          ...futureClosures.map(
            (c) => _ClosureCard(
              closure: c,
              isActive: c.containsDate(todayOnly),
              onEdit: () => BusinessClosureDialog.show(context, closure: c),
              onDelete: () => _deleteClosure(c),
            ),
          ),
        ],

        // Chiusure passate
        if (pastClosures.isNotEmpty) ...[
          if (futureClosures.isNotEmpty) const SizedBox(height: 24),
          _SectionHeader(
            title: l10n.closuresPast,
            count: pastClosures.length,
            icon: Icons.history,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          ...pastClosures.map(
            (c) => _ClosureCard(
              closure: c,
              isPast: true,
              onEdit: () => BusinessClosureDialog.show(context, closure: c),
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
  final int count;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureCard extends StatelessWidget {
  final BusinessClosure closure;
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat.yMMMd(locale);

    final isSingleDay =
        closure.startDate.year == closure.endDate.year &&
        closure.startDate.month == closure.endDate.month &&
        closure.startDate.day == closure.endDate.day;

    final cardColor = isActive
        ? theme.colorScheme.errorContainer.withOpacity(0.5)
        : isPast
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
        : null;

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
                        // Active badge
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'CHIUSO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.bold,
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
