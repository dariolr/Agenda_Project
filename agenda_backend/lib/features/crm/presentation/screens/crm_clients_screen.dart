import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../domain/crm_models.dart';
import '../../providers/crm_providers.dart';

class CrmClientsScreen extends ConsumerWidget {
  const CrmClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(crmClientsProvider);
    final currentFilter = state.value?.statusFilter ?? '';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.crmClientsTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: l10n.actionRefresh,
            onPressed: () => ref.read(crmClientsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClientUpsertDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.crmCreateClientTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.crmSearchHint,
                prefixIcon: const Icon(Icons.search_outlined),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => ref.read(crmClientsProvider.notifier).setSearch(v),
            ),
          ),
          // Status filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _filterChip(context, ref, l10n.crmFilterAll, '', currentFilter, null),
                const SizedBox(width: 8),
                _filterChip(context, ref, l10n.crmStatusLead, 'lead', currentFilter, const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                _filterChip(context, ref, l10n.crmStatusActive, 'active', currentFilter, const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                _filterChip(context, ref, l10n.crmStatusInactive, 'inactive', currentFilter, const Color(0xFFEF6C00)),
                const SizedBox(width: 8),
                _filterChip(context, ref, l10n.crmStatusLost, 'lost', currentFilter, const Color(0xFFC62828)),
              ],
            ),
          ),
          // Count
          if (state.hasValue && (state.value?.total ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 6),
              child: Text(
                '${state.value!.total} clienti',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (data) {
                if (data.clients.isEmpty) {
                  return _EmptyState(
                    icon: Icons.people_outline,
                    label: l10n.crmClientsEmpty,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: data.clients.length + (data.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == data.clients.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: data.loadingMore
                              ? const CircularProgressIndicator()
                              : OutlinedButton.icon(
                                  onPressed: () =>
                                      ref.read(crmClientsProvider.notifier).loadMore(),
                                  icon: const Icon(Icons.expand_more),
                                  label: Text(l10n.crmLoadMore),
                                ),
                        ),
                      );
                    }
                    final c = data.clients[index];
                    return _ClientCard(
                      client: c,
                      onTap: () => context.go('/altro/crm/clienti/${c.id}'),
                      archiveLabel: l10n.crmArchiveAction,
                      gdprLabel: l10n.crmGdprDeleteTitle,
                      onArchive: () async {
                        await ref
                            .read(crmRepositoryProvider)
                            .archiveClient(c.businessId, c.id, true);
                        ref.invalidate(crmClientsProvider);
                      },
                      onGdprDelete: () async {
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.crmGdprDeleteTitle),
                                content: Text(l10n.crmGdprDeleteConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(l10n.actionCancel),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: cs.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l10n.actionConfirm),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!ok) return;
                        await ref
                            .read(crmRepositoryProvider)
                            .gdprDelete(c.businessId, c.id);
                        ref.invalidate(crmClientsProvider);
                        if (context.mounted) {
                          await FeedbackDialog.showSuccess(
                            context,
                            title: l10n.crmTitle,
                            message: l10n.crmGdprDeleted,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    String current,
    Color? color,
  ) {
    final isSelected = current == value;
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: resolvedColor.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? resolvedColor : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (v) {
        if (v) ref.read(crmClientsProvider.notifier).setStatusFilter(value);
      },
    );
  }

  Future<void> _openClientUpsertDialog(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.crmCreateClientTitle),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(firstNameCtrl, l10n.authFirstName),
                  const SizedBox(height: 12),
                  _dialogField(lastNameCtrl, l10n.authLastName),
                  const SizedBox(height: 12),
                  _dialogField(emailCtrl, l10n.authEmail,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _dialogField(phoneCtrl, l10n.authPhone,
                      keyboard: TextInputType.phone),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.actionCancel)),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.actionConfirm)),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await ref.read(clientUpsertControllerProvider.notifier).submit({
      'first_name': firstNameCtrl.text.trim(),
      'last_name': lastNameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    });

    ref.invalidate(crmClientsProvider);
  }

  Widget _dialogField(TextEditingController ctrl, String label,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ── Client Card ─────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final CrmClient client;
  final VoidCallback onTap;
  final String archiveLabel;
  final String gdprLabel;
  final Future<void> Function() onArchive;
  final Future<void> Function() onGdprDelete;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.archiveLabel,
    required this.gdprLabel,
    required this.onArchive,
    required this.onGdprDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = client.fullName.isEmpty ? '#${client.id}' : client.fullName;
    final initials = _initials(name);
    final avatarColor = _avatarColor(client.id);

    return Card(
      elevation: 1,
      shadowColor: avatarColor.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor.withOpacity(0.14),
                child: Text(
                  initials,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: avatarColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(client.status),
                      ],
                    ),
                    if ((client.email ?? '').isNotEmpty ||
                        (client.phone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((client.email ?? '').isNotEmpty) client.email!,
                          if ((client.phone ?? '').isNotEmpty) client.phone!,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${client.kpi.visitsCount} visite',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (client.kpi.lastVisit != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.schedule_outlined,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(client.kpi.lastVisit),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                        if (client.kpi.totalSpent > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.euro_outlined,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            client.kpi.totalSpent.toStringAsFixed(0),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                    if (client.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: client.tags
                            .take(4)
                            .map((t) => _InlineTag(t))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                onSelected: (v) async {
                  if (v == 'archive') await onArchive();
                  if (v == 'gdpr') await onGdprDelete();
                },
                itemBuilder: (ctx) {
                  final errorColor = Theme.of(ctx).colorScheme.error;
                  return [
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(children: [
                        const Icon(Icons.archive_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(archiveLabel),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'gdpr',
                      child: Row(children: [
                        Icon(Icons.delete_forever_outlined,
                            size: 18, color: errorColor),
                        const SizedBox(width: 10),
                        Text(gdprLabel,
                            style: TextStyle(color: errorColor)),
                      ]),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared visual atoms ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  final String tag;

  const _InlineTag(this.tag);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Text(
        tag,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: cs.onSurfaceVariant),
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
          Icon(icon, size: 56, color: cs.onSurfaceVariant.withOpacity(0.35)),
          const SizedBox(height: 16),
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

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
