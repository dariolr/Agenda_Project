import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../domain/crm_models.dart';
import '../../providers/crm_providers.dart';

class CrmTagsScreen extends ConsumerWidget {
  const CrmTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tagsAsync = ref.watch(clientTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.crmTagsTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTag(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.crmCreateTagTitle),
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E24AA).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sell_outlined,
                      size: 36,
                      color: Color(0xFF8E24AA),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.crmTagsEmpty,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea il primo tag per organizzare i clienti',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TagCard(
              tag: tags[i],
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                            'Elimina tag "${tags[i].name}"'),
                        content: const Text(
                            'Il tag verrà rimosso da tutti i clienti.'),
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
                    .read(clientTagControllerProvider.notifier)
                    .delete(tags[i].id, force: true);
                ref.invalidate(clientTagsProvider);
                if (context.mounted) {
                  await FeedbackDialog.showSuccess(
                    context,
                    title: l10n.crmTitle,
                    message: l10n.crmTagDeleted,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _createTag(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    Color selectedColor = const Color(0xFF009688);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(l10n.crmCreateTagTitle),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.crmTagNameLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.crmTagColorLabel,
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _paletteColors.map((c) {
                        final isSelected = selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(ctx).colorScheme.onSurface
                                    : Colors.transparent,
                                width: isSelected ? 3 : 0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: c.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
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
          ),
        ) ??
        false;

    if (!confirmed) return;
    await ref.read(clientTagControllerProvider.notifier).create(
          nameCtrl.text.trim(),
          color: _colorToHex(selectedColor),
        );
    ref.invalidate(clientTagsProvider);
  }
}

class _TagCard extends StatelessWidget {
  final CrmTag tag;
  final Future<void> Function() onDelete;

  const _TagCard({required this.tag, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tagColor = _parseHex(tag.color) ?? const Color(0xFF009688);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Color dot with icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tagColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tagColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.sell_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag.name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (tag.color != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tag.color!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: cs.onSurfaceVariant),
              onPressed: onDelete,
              tooltip: 'Elimina tag',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color? _parseHex(String? hex) {
  if (hex == null) return null;
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) {
    final value = int.tryParse('FF$clean', radix: 16);
    if (value != null) return Color(value);
  }
  if (clean.length == 8) {
    final value = int.tryParse(clean, radix: 16);
    if (value != null) return Color(value);
  }
  return null;
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

const _paletteColors = [
  Color(0xFF009688), // teal
  Color(0xFF1565C0), // blue
  Color(0xFF8E24AA), // purple
  Color(0xFFEF6C00), // orange
  Color(0xFF2E7D32), // green
  Color(0xFFC62828), // red
  Color(0xFF0288D1), // light blue
  Color(0xFF546E7A), // blue grey
  Color(0xFFF9A825), // amber
  Color(0xFF37474F), // dark grey
];
