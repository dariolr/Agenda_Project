import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/business.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/feedback_dialog.dart';

/// Dialog per sincronizzare i dati di un business da produzione a staging.
/// DISPONIBILE SOLO SU STAGING.
class SyncFromProductionDialog extends ConsumerStatefulWidget {
  const SyncFromProductionDialog({super.key, required this.business});

  final Business business;

  @override
  ConsumerState<SyncFromProductionDialog> createState() =>
      _SyncFromProductionDialogState();
}

class _SyncFromProductionDialogState
    extends ConsumerState<SyncFromProductionDialog> {
  bool _isSyncing = false;
  String? _statusMessage;
  Map<String, dynamic>? _result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync, size: 24),
          SizedBox(width: 8),
          Text('Sincronizza da Produzione'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questa operazione sovrascriverà TUTTI i dati del business '
                      '"${widget.business.name}" su staging con i dati di produzione.\n\n'
                      '• Tutti gli appuntamenti esistenti su staging saranno eliminati\n'
                      '• Tutti i clienti, servizi, staff saranno sostituiti\n'
                      '• Le sessioni di login NON saranno copiate\n'
                      '• Le email andranno a dariolarosa@romeolab.it',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info business
            Text(
              'Business da sincronizzare:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      widget.business.name.isNotEmpty
                          ? widget.business.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.business.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.business.slug != null)
                          Text(
                            'Slug: ${widget.business.slug}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: ${widget.business.id}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Status / Progress
            if (_isSyncing || _statusMessage != null || _result != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              if (_isSyncing) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _statusMessage ?? 'Sincronizzazione in corso...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ] else if (_result != null) ...[
                _buildResultSummary(context),
              ] else if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSyncing ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        if (_result == null)
          FilledButton(
            onPressed: _isSyncing ? null : _startSync,
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sincronizza'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Chiudi'),
          ),
      ],
    );
  }

  Widget _buildResultSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imported = _result!['imported'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sincronizzazione completata!',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record importati:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (imported['locations'] != null)
                    _statChip(context, 'Sedi', imported['locations']),
                  if (imported['staff'] != null)
                    _statChip(context, 'Staff', imported['staff']),
                  if (imported['services'] != null)
                    _statChip(context, 'Servizi', imported['services']),
                  if (imported['clients'] != null)
                    _statChip(context, 'Clienti', imported['clients']),
                  if (imported['appointments'] != null)
                    _statChip(
                      context,
                      'Appuntamenti',
                      imported['appointments'],
                    ),
                  if (imported['bookings'] != null)
                    _statChip(context, 'Prenotazioni', imported['bookings']),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(BuildContext context, String label, dynamic count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Future<void> _startSync() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Recupero dati da produzione...';
      _result = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      setState(() {
        _statusMessage = 'Import dati su staging...';
      });

      // Chiama l'endpoint sync-from-production
      final result = await apiClient.syncBusinessFromProduction(
        businessId: widget.business.id,
      );

      setState(() {
        _isSyncing = false;
        _result = result;
        _statusMessage = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Errore: ${e.message}';
      });

      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.message,
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Errore: $e';
      });

      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.toString(),
        );
      }
    }
  }
}

/// Mostra il dialog per sincronizzare un business da produzione.
/// Ritorna `true` se la sincronizzazione è avvenuta con successo.
Future<bool?> showSyncFromProductionDialog(
  BuildContext context,
  Business business,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SyncFromProductionDialog(business: business),
  );
}
