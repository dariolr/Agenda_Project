import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../domain/crm_models.dart';
import '../../providers/crm_providers.dart';

class CrmClientDetailScreen extends ConsumerStatefulWidget {
  final int clientId;

  const CrmClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<CrmClientDetailScreen> createState() =>
      _CrmClientDetailScreenState();
}

class _CrmClientDetailScreenState extends ConsumerState<CrmClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(clientDetailProvider(widget.clientId));
    final eventsAsync = ref.watch(clientEventsProvider(widget.clientId));
    final tasksAsync = ref.watch(clientTasksProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.fullName.isEmpty ? '#${c.id}' : c.fullName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                c.status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _statusColor(c.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          orElse: () => Text(l10n.crmClientDetailTitle),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard_outlined, size: 18), text: l10n.crmOverviewTab),
            Tab(icon: const Icon(Icons.timeline_outlined, size: 18), text: l10n.crmTimelineTab),
            Tab(icon: const Icon(Icons.calendar_today_outlined, size: 18), text: l10n.crmBookingsTab),
            Tab(icon: const Icon(Icons.task_alt_outlined, size: 18), text: l10n.crmTasksTab),
            Tab(icon: const Icon(Icons.contacts_outlined, size: 18), text: l10n.crmContactsTab),
            Tab(icon: const Icon(Icons.stars_outlined, size: 18), text: l10n.crmLoyaltyTab),
            Tab(icon: const Icon(Icons.security_outlined, size: 18), text: l10n.crmGdprTab),
          ],
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (client) => TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(clientId: widget.clientId),
            _TimelineTab(eventsAsync: eventsAsync),
            _BookingsPlaceholder(l10n: l10n),
            _TasksTab(
              tasksAsync: tasksAsync,
              clientId: widget.clientId,
              l10n: l10n,
              ref: ref,
            ),
            _ContactsTab(client: client, ref: ref),
            _LoyaltyTab(client: client, ref: ref, l10n: l10n),
            _GdprTab(
              client: client,
              ref: ref,
              l10n: l10n,
              onDeleted: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final int clientId;

  const _OverviewTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detailAsync = ref.watch(clientDetailProvider(clientId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (client) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final name = client.fullName.isEmpty ? '#${client.id}' : client.fullName;
        final avatarColor = _avatarColor(client.id);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // Header card
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: avatarColor.withOpacity(0.18),
                      child: Text(
                        _initials(name),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: avatarColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _StatusBadge(client.status),
                              if (client.isArchived) ...[
                                const SizedBox(width: 6),
                                _Badge(
                                  'Archiviato',
                                  const Color(0xFF546E7A),
                                ),
                              ],
                            ],
                          ),
                          if ((client.email ?? '').isNotEmpty ||
                              (client.phone ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              [
                                if ((client.email ?? '').isNotEmpty)
                                  client.email!,
                                if ((client.phone ?? '').isNotEmpty)
                                  client.phone!,
                              ].join('\n'),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                          if ((client.city ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13, color: cs.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Text(
                                  client.city!,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // KPI grid
            Text(
              'KPI',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _KpiCard(
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF009688),
                  label: l10n.crmKpiVisits,
                  value: '${client.kpi.visitsCount}',
                ),
                _KpiCard(
                  icon: Icons.euro_rounded,
                  color: const Color(0xFF2E7D32),
                  label: l10n.crmKpiSpent,
                  value: '€${client.kpi.totalSpent.toStringAsFixed(0)}',
                ),
                _KpiCard(
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF1565C0),
                  label: l10n.crmKpiAvgTicket,
                  value: '€${client.kpi.avgTicket.toStringAsFixed(0)}',
                ),
                _KpiCard(
                  icon: Icons.person_off_outlined,
                  color: const Color(0xFFEF6C00),
                  label: l10n.crmKpiNoShow,
                  value: '${client.kpi.noShowCount}',
                ),
              ],
            ),
            // Tags
            if (client.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Tag',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: client.tags
                    .map((t) => Chip(
                          label: Text(t),
                          labelStyle: theme.textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                              color: cs.outline.withOpacity(0.2)),
                        ))
                    .toList(),
              ),
            ],
            // Last visit
            if (client.kpi.lastVisit != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Ultima visita: ${_formatDate(client.kpi.lastVisit)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Tab ─────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final AsyncValue<List<CrmEvent>> eventsAsync;

  const _TimelineTab({required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (events) {
        if (events.isEmpty) {
          return const _EmptyState(
            icon: Icons.timeline_outlined,
            label: 'Nessun evento registrato',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: events.length,
          itemBuilder: (_, i) => _EventItem(
            event: events[i],
            isLast: i == events.length - 1,
          ),
        );
      },
    );
  }
}

class _EventItem extends StatelessWidget {
  final CrmEvent event;
  final bool isLast;

  const _EventItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = _eventStyle(event.eventType);
    final icon = style.$1;
    final color = style.$2;
    final label = _eventLabel(event.eventType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.outline.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatDate(event.occurredAt),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (event.payload != null &&
                      event.payload!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _payloadPreview(event.payload!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tasks Tab ────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  final AsyncValue<List<CrmTask>> tasksAsync;
  final int clientId;
  final dynamic l10n;
  final WidgetRef ref;

  const _TasksTab({
    required this.tasksAsync,
    required this.clientId,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const _EmptyState(
            icon: Icons.task_alt_outlined,
            label: 'Nessun task',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _TaskCard(
            task: tasks[i],
            clientId: clientId,
            l10n: l10n,
            ref: ref,
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final CrmTask task;
  final int clientId;
  final dynamic l10n;
  final WidgetRef ref;

  const _TaskCard({
    required this.task,
    required this.clientId,
    required this.l10n,
    required this.ref,
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.isOverdue && !isDone
              ? const Color(0xFFC62828).withOpacity(0.3)
              : cs.outline.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    color: isDone
                        ? cs.onSurfaceVariant.withOpacity(0.3)
                        : priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: isDone ? cs.onSurfaceVariant : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (task.isOverdue && !isDone)
                  _Badge('In ritardo', const Color(0xFFC62828)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Badge(
                  _priorityLabel(task.priority),
                  priorityColor,
                ),
                const SizedBox(width: 6),
                _Badge(
                  isDone ? 'Completato' : 'Aperto',
                  isDone
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF1565C0),
                ),
                const Spacer(),
                if (task.dueAt != null) ...[
                  Icon(Icons.schedule_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(task.dueAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.isOverdue && !isDone
                          ? const Color(0xFFC62828)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: isDone
                  ? OutlinedButton.icon(
                      onPressed: () => ref
                          .read(clientTaskControllerProvider.notifier)
                          .reopen(clientId, task.id),
                      icon: const Icon(Icons.replay_outlined, size: 16),
                      label: Text(l10n.crmTaskReopen),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () => ref
                          .read(clientTaskControllerProvider.notifier)
                          .complete(clientId, task.id),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(l10n.crmTaskComplete),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bookings Placeholder ─────────────────────────────────────────────────────

class _BookingsPlaceholder extends StatelessWidget {
  final dynamic l10n;

  const _BookingsPlaceholder({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              l10n.crmBookingsReuseHint,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contacts Tab ─────────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  final CrmClient client;
  final WidgetRef ref;

  const _ContactsTab({required this.client, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(apiClientProvider).get(
          '/v1/businesses/${client.businessId}/clients/${client.id}'),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final contacts =
            (snap.data!['contacts'] as List? ?? const []);
        if (contacts.isEmpty) {
          return const _EmptyState(
            icon: Icons.contacts_outlined,
            label: 'Nessun contatto aggiuntivo',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = contacts[i] as Map;
            final type = (c['type'] ?? '').toString();
            final value = (c['value'] ?? '').toString();
            final isPrimary = c['is_primary'] == 1 || c['is_primary'] == true;
            final style = _contactTypeStyle(type);

            return Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.$2.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(style.$1, size: 20, color: style.$2),
                ),
                title: Text(
                  value,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _contactTypeLabel(type),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                trailing: isPrimary
                    ? _Badge('Principale', const Color(0xFF009688))
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Loyalty Tab ──────────────────────────────────────────────────────────────

class _LoyaltyTab extends StatelessWidget {
  final CrmClient client;
  final WidgetRef ref;
  final dynamic l10n;

  const _LoyaltyTab(
      {required this.client, required this.ref, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(apiClientProvider).get(
          '/v1/businesses/${client.businessId}/clients/${client.id}/loyalty'),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final points = (snap.data!['points'] ?? 0).toString();
        final ledger = (snap.data!['ledger'] as List? ?? const []);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Points balance card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF009688).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded,
                      size: 40, color: Colors.white70),
                  const SizedBox(height: 10),
                  Text(
                    points,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'punti loyalty',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (ledger.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Storico movimenti',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              ...ledger.map((entry) {
                final e = entry as Map;
                final delta = (e['delta_points'] as num?)?.toInt() ?? 0;
                final isPositive = delta >= 0;
                return ListTile(
                  leading: Icon(
                    isPositive
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    color: isPositive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                  title: Text(
                    (e['reason'] ?? '').toString(),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    '${isPositive ? '+' : ''}$delta pt',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isPositive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

// ── GDPR Tab ─────────────────────────────────────────────────────────────────

class _GdprTab extends StatelessWidget {
  final CrmClient client;
  final WidgetRef ref;
  final dynamic l10n;
  final VoidCallback onDeleted;

  const _GdprTab({
    required this.client,
    required this.ref,
    required this.l10n,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.errorContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.error.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security_outlined, color: cs.error, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'GDPR & Privacy',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onErrorContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'L\'anonimizzazione rimuove tutti i dati personali identificativi del cliente (nome, email, telefono, indirizzi). L\'operazione è irreversibile.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onErrorContainer.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.crmGdprDeleteTitle),
                            content: Text(l10n.crmGdprDeleteConfirm),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text(l10n.actionCancel)),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: cs.error),
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: Text(l10n.actionConfirm),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!ok) return;
                    await ref
                        .read(crmRepositoryProvider)
                        .gdprDelete(client.businessId, client.id);
                    if (!context.mounted) return;
                    await FeedbackDialog.showSuccess(
                      context,
                      title: l10n.crmTitle,
                      message: l10n.crmGdprDeleted,
                    );
                    onDeleted();
                  },
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.crmGdprDeleteTitle),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared atoms ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return _Badge(status, color);
  }
}

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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: cs.onSurfaceVariant.withOpacity(0.35)),
          const SizedBox(height: 14),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'lead':
      return const Color(0xFF1565C0);
    case 'active':
      return const Color(0xFF2E7D32);
    case 'inactive':
      return const Color(0xFFEF6C00);
    case 'lost':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF546E7A);
  }
}

Color _avatarColor(int id) {
  const colors = [
    Color(0xFF009688),
    Color(0xFF1565C0),
    Color(0xFF8E24AA),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFF0288D1),
  ];
  return colors[id % colors.length];
}

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

String _eventLabel(String type) {
  switch (type) {
    case 'booking_created':
      return 'Prenotazione creata';
    case 'booking_cancelled':
      return 'Prenotazione cancellata';
    case 'booking_no_show':
      return 'No-show';
    case 'payment':
      return 'Pagamento';
    case 'note':
      return 'Nota';
    case 'task':
      return 'Task';
    case 'message':
      return 'Messaggio';
    case 'campaign':
      return 'Campagna';
    case 'merge':
      return 'Merge cliente';
    case 'gdpr_export':
      return 'Export GDPR';
    case 'gdpr_delete':
      return 'Eliminazione GDPR';
    default:
      return type;
  }
}

(IconData, Color) _eventStyle(String type) {
  switch (type) {
    case 'booking_created':
      return (Icons.calendar_today_rounded, const Color(0xFF2E7D32));
    case 'booking_cancelled':
      return (Icons.event_busy_rounded, const Color(0xFFC62828));
    case 'booking_no_show':
      return (Icons.person_off_rounded, const Color(0xFFEF6C00));
    case 'payment':
      return (Icons.payments_rounded, const Color(0xFF1565C0));
    case 'note':
      return (Icons.sticky_note_2_rounded, const Color(0xFF5C6BC0));
    case 'task':
      return (Icons.task_alt_rounded, const Color(0xFF009688));
    case 'message':
      return (Icons.message_rounded, const Color(0xFF0288D1));
    case 'campaign':
      return (Icons.campaign_rounded, const Color(0xFF8E24AA));
    case 'merge':
      return (Icons.merge_rounded, const Color(0xFF546E7A));
    case 'gdpr_export':
      return (Icons.download_rounded, const Color(0xFF546E7A));
    case 'gdpr_delete':
      return (Icons.delete_forever_rounded, const Color(0xFFC62828));
    default:
      return (Icons.history_rounded, const Color(0xFF546E7A));
  }
}

(IconData, Color) _contactTypeStyle(String type) {
  switch (type) {
    case 'email':
      return (Icons.email_outlined, const Color(0xFF1565C0));
    case 'phone':
      return (Icons.phone_outlined, const Color(0xFF2E7D32));
    case 'whatsapp':
      return (Icons.chat_outlined, const Color(0xFF2E7D32));
    case 'instagram':
      return (Icons.photo_camera_outlined, const Color(0xFF8E24AA));
    case 'facebook':
      return (Icons.facebook_outlined, const Color(0xFF1565C0));
    default:
      return (Icons.link_outlined, const Color(0xFF546E7A));
  }
}

String _contactTypeLabel(String type) {
  switch (type) {
    case 'email':
      return 'Email';
    case 'phone':
      return 'Telefono';
    case 'whatsapp':
      return 'WhatsApp';
    case 'instagram':
      return 'Instagram';
    case 'facebook':
      return 'Facebook';
    default:
      return type;
  }
}

String _payloadPreview(Map<String, dynamic> payload) {
  final parts = payload.entries
      .where((e) => e.value != null && e.value.toString().isNotEmpty)
      .take(3)
      .map((e) => '${e.key}: ${e.value}')
      .toList();
  return parts.join(' · ');
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}
