import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../providers/crm_providers.dart';

class CrmImportExportScreen extends ConsumerStatefulWidget {
  const CrmImportExportScreen({super.key});

  @override
  ConsumerState<CrmImportExportScreen> createState() =>
      _CrmImportExportScreenState();
}

class _CrmImportExportScreenState extends ConsumerState<CrmImportExportScreen> {
  final _csvCtrl = TextEditingController();

  @override
  void dispose() {
    _csvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final importState = ref.watch(clientImportControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.crmImportExportTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Import section ────────────────────────────────────────────
          _SectionCard(
            icon: Icons.upload_file_outlined,
            color: const Color(0xFF1565C0),
            title: l10n.crmImportCsvTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incolla o inserisci il CSV con header: first_name, last_name, email, phone, city, notes, source',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _csvCtrl,
                  minLines: 6,
                  maxLines: 12,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.crmImportCsvHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _runImport(dryRun: true),
                        icon: const Icon(Icons.preview_outlined, size: 18),
                        label: Text(l10n.crmImportPreview),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _runImport(dryRun: false),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(l10n.crmImportCommit),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
                // Loading indicator
                if (importState.isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                // Result
                if (importState.hasValue && importState.value != null) ...[
                  const SizedBox(height: 12),
                  _ImportResultCard(result: importState.value!),
                ],
                if (importState.hasError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: cs.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            importState.error.toString(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Export section ────────────────────────────────────────────
          _SectionCard(
            icon: Icons.download_outlined,
            color: const Color(0xFF2E7D32),
            title: l10n.crmExportCsvTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esporta tutti i clienti del business in formato CSV e copialo negli appunti.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final businessId = ref.read(currentBusinessIdProvider);
                      final res = await ref
                          .read(crmRepositoryProvider)
                          .exportCsv(businessId);
                      final csv = (res['csv'] ?? '').toString();
                      await Clipboard.setData(ClipboardData(text: csv));
                      if (context.mounted) {
                        await FeedbackDialog.showSuccess(
                          context,
                          title: l10n.crmTitle,
                          message: l10n.crmExportCopied,
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: Text(l10n.crmExportCsvButton),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _runImport({required bool dryRun}) async {
    final csv = _csvCtrl.text.trim();
    if (csv.isEmpty) return;

    const mapping = {
      'first_name': 'first_name',
      'last_name': 'last_name',
      'email': 'email',
      'phone': 'phone',
      'city': 'city',
      'notes': 'notes',
      'source': 'source',
    };

    if (dryRun) {
      await ref
          .read(clientImportControllerProvider.notifier)
          .preview(csv: csv, mapping: mapping);
    } else {
      await ref
          .read(clientImportControllerProvider.notifier)
          .commit(csv: csv, mapping: mapping);
    }
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Import Result ─────────────────────────────────────────────────────────────

class _ImportResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _ImportResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final imported = result['imported'] ?? result['created'] ?? result['inserted'];
    final skipped = result['skipped'] ?? result['duplicates'];
    final errors = result['errors'];
    final total = result['total'];
    final isDryRun = result['dry_run'] == true;

    // Build structured rows
    final rows = <_ResultRow>[];
    if (total != null) {
      rows.add(_ResultRow('Totale righe', total.toString(), cs.onSurfaceVariant));
    }
    if (imported != null) {
      rows.add(_ResultRow(
          isDryRun ? 'Importabili' : 'Importati',
          imported.toString(),
          const Color(0xFF2E7D32)));
    }
    if (skipped != null) {
      rows.add(_ResultRow(
          'Saltati / Duplicati', skipped.toString(), const Color(0xFFEF6C00)));
    }
    if (errors != null) {
      final errCount = errors is List ? errors.length : errors;
      rows.add(_ResultRow(
          'Errori', errCount.toString(), const Color(0xFFC62828)));
    }

    // Fallback: show raw key/value pairs
    if (rows.isEmpty) {
      rows.addAll(result.entries
          .where((e) => e.value != null)
          .map((e) => _ResultRow(e.key, e.value.toString(), cs.onSurfaceVariant))
          .toList());
    }

    final headerColor = isDryRun
        ? const Color(0xFF1565C0)
        : const Color(0xFF2E7D32);
    final headerLabel = isDryRun ? 'Preview dry-run' : 'Import completato';
    final headerIcon = isDryRun ? Icons.preview_outlined : Icons.check_circle_outline;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(headerIcon, size: 16, color: headerColor),
                const SizedBox(width: 8),
                Text(
                  headerLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: headerColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: rows
                  .map((r) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              r.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant),
                            ),
                            const Spacer(),
                            Text(
                              r.value,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: r.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Errors detail list
          if (errors is List && errors.isNotEmpty) ...[
            Divider(height: 1, color: cs.outline.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dettaglio errori',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...errors.take(5).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: Color(0xFFC62828)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.toString(),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (errors.length > 5)
                    Text(
                      '+ altri ${errors.length - 5} errori',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFC62828)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow {
  final String label;
  final String value;
  final Color color;

  const _ResultRow(this.label, this.value, this.color);
}
