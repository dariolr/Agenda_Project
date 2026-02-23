import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../domain/crm_models.dart';
import '../../providers/crm_providers.dart';

class CrmTasksScreen extends ConsumerWidget {
  const CrmTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final overdueAsync = ref.watch(overdueTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.crmTasksTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: overdueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      size: 36,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.crmTasksEmpty,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tutti i task sono in ordine',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: Color(0xFFC62828)),
                            const SizedBox(width: 5),
                            Text(
                              '${tasks.length} in ritardo',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFFC62828),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Task list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _OverdueTaskCard(
                    task: tasks[i],
                    ref: ref,
                    l10n: l10n,
                    onClientTap: () =>
                        context.go('/altro/crm/clienti/${tasks[i].clientId}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverdueTaskCard extends StatelessWidget {
  final CrmTask task;
  final WidgetRef ref;
  final dynamic l10n;
  final VoidCallback onClientTap;

  const _OverdueTaskCard({
    required this.task,
    required this.ref,
    required this.l10n,
    required this.onClientTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priorityColor = _priorityColor(task.priority);
    final isDone = task.status == 'done';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: task.isOverdue && !isDone
              ? const Color(0xFFC62828).withOpacity(0.25)
              : cs.outline.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority indicator bar
                Container(
                  width: 4,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: isDone
                        ? cs.onSurfaceVariant.withOpacity(0.2)
                        : priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? cs.onSurfaceVariant : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(_priorityLabel(task.priority), priorityColor),
                          const SizedBox(width: 6),
                          if (task.isOverdue && !isDone)
                            _Badge('In ritardo', const Color(0xFFC62828)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Client link
                InkWell(
                  onTap: onClientTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline,
                            size: 13, color: cs.primary),
                        const SizedBox(width: 3),
                        Text(
                          'Cliente #${task.clientId}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (task.dueAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.schedule_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(task.dueAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.isOverdue && !isDone
                          ? const Color(0xFFC62828)
                          : cs.onSurfaceVariant,
                      fontWeight: task.isOverdue && !isDone
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ],
                const Spacer(),
                if (!isDone)
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(clientTaskControllerProvider.notifier)
                        .complete(task.clientId, task.id),
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: Text(l10n.crmTaskComplete),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared atoms ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return const Color(0xFFC62828);
    case 'medium':
      return const Color(0xFFF9A825);
    case 'low':
      return const Color(0xFF546E7A);
    default:
      return const Color(0xFF546E7A);
  }
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'high':
      return 'Alta';
    case 'medium':
      return 'Media';
    case 'low':
      return 'Bassa';
    default:
      return priority;
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
