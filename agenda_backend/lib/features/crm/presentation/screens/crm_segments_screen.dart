import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../domain/crm_models.dart';
import '../../providers/crm_providers.dart';
import '../../../agenda/providers/business_providers.dart';

class CrmSegmentsScreen extends ConsumerWidget {
  const CrmSegmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final segmentsAsync = ref.watch(crmSegmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.crmSegmentsTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.crmCreateSegmentTitle),
      ),
      body: segmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (segments) {
          if (segments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.filter_alt_outlined,
                      size: 36,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.crmSegmentsEmpty,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea un segmento per raggruppare clienti con filtri salvati',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: segments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _SegmentCard(
              segment: segments[i],
              onDelete: () async {
                final businessId = ref.read(currentBusinessIdProvider);
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title:
                            Text('Elimina "${segments[i].name}"'),
                        content: const Text(
                            'Il segmento verrà eliminato definitivamente.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.actionCancel)),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.actionConfirm),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (!confirmed) return;
                await ref
                    .read(crmRepositoryProvider)
                    .deleteSegment(businessId, segments[i].id);
                ref.invalidate(crmSegmentsProvider);
                if (context.mounted) {
                  await FeedbackDialog.showSuccess(
                    context,
                    title: l10n.crmTitle,
                    message: l10n.crmSegmentDeleted,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final queryCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.crmCreateSegmentTitle),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.crmSegmentNameLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.label_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: queryCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.crmSegmentQueryLabel,
                      hintText: 'es. status=active&tag_ids=1,2',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_outlined),
                    ),
                  ),
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
    final businessId = ref.read(currentBusinessIdProvider);
    await ref.read(crmRepositoryProvider).createSegment(
          businessId,
          nameCtrl.text.trim(),
          {'q': queryCtrl.text.trim()},
        );
    ref.invalidate(crmSegmentsProvider);
  }
}

class _SegmentCard extends StatelessWidget {
  final CrmSegment segment;
  final Future<void> Function() onDelete;

  const _SegmentCard({required this.segment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filterChips = _formatFilters(segment.filters);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.filter_alt_outlined,
                size: 22,
                color: Color(0xFF5C6BC0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (filterChips.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: filterChips
                          .map((f) => _FilterChipWidget(f))
                          .toList(),
                    )
                  else
                    Text(
                      'Nessun filtro configurato',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: cs.onSurfaceVariant),
              onPressed: onDelete,
              tooltip: 'Elimina segmento',
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;

  const _FilterChipWidget(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

List<String> _formatFilters(Map<String, dynamic> filters) {
  return filters.entries
      .where((e) => e.value != null && e.value.toString().isNotEmpty)
      .map((e) {
    final key = _filterKeyLabel(e.key);
    final value = e.value.toString();
    return '$key: $value';
  }).toList();
}

String _filterKeyLabel(String key) {
  switch (key) {
    case 'q':
      return 'Cerca';
    case 'status':
      return 'Stato';
    case 'tag_ids':
      return 'Tag';
    case 'tag_names':
      return 'Tag';
    case 'last_visit_from':
      return 'Ultima visita da';
    case 'last_visit_to':
      return 'Ultima visita a';
    case 'spent_from':
      return 'Spesa minima';
    case 'spent_to':
      return 'Spesa massima';
    case 'visits_from':
      return 'Visite min';
    case 'visits_to':
      return 'Visite max';
    case 'birthday_month':
      return 'Mese compleanno';
    case 'marketing_opt_in':
      return 'Marketing';
    case 'profiling_opt_in':
      return 'Profilazione';
    case 'is_archived':
      return 'Archiviati';
    default:
      return key;
  }
}
