import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/business.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/feedback_dialog.dart';

/// Dialog per copiare un business tra ambienti.
/// Permette di scegliere la direzione: Produzione → Staging o Staging → Produzione.
class SyncToStagingDialog extends ConsumerStatefulWidget {
  const SyncToStagingDialog({super.key, required this.business});

  final Business business;

  @override
  ConsumerState<SyncToStagingDialog> createState() =>
      _SyncToStagingDialogState();
}

enum SyncDirection { prodToStaging, stagingToProd }

class _SyncToStagingDialogState extends ConsumerState<SyncToStagingDialog> {
  bool _isSyncing = false;
  String? _statusMessage;
  Map<String, dynamic>? _result;

  // Default: se su staging → prod to staging, se su prod → prod to staging
  late SyncDirection _direction;

  @override
  void initState() {
    super.initState();
    // Default sempre prod → staging
    _direction = SyncDirection.prodToStaging;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isProdToStaging = _direction == SyncDirection.prodToStaging;
    final sourceEnv = isProdToStaging ? 'Produzione' : 'Staging';
    final targetEnv = isProdToStaging ? 'Staging' : 'Produzione';
    final targetColor = isProdToStaging ? Colors.orange : Colors.blue;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync_alt, size: 24),
          SizedBox(width: 8),
          Text('Sincronizza Business'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selezione direzione
            Text(
              'Direzione sincronizzazione:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DirectionCard(
                    selected: _direction == SyncDirection.prodToStaging,
                    onTap: _isSyncing || _result != null
                        ? null
                        : () => setState(
                            () => _direction = SyncDirection.prodToStaging,
                          ),
                    sourceLabel: 'Produzione',
                    targetLabel: 'Staging',
                    sourceIcon: Icons.business,
                    targetIcon: Icons.science,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DirectionCard(
                    selected: _direction == SyncDirection.stagingToProd,
                    onTap: _isSyncing || _result != null
                        ? null
                        : () => setState(
                            () => _direction = SyncDirection.stagingToProd,
                          ),
                    sourceLabel: 'Staging',
                    targetLabel: 'Produzione',
                    sourceIcon: Icons.science,
                    targetIcon: Icons.business,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Avviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: targetColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: targetColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: targetColor.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questa operazione copierà i dati del business '
                      '"${widget.business.name}" da $sourceEnv a $targetEnv.\n\n'
                      '• Se esiste già su $targetEnv, verrà sovrascritto\n'
                      '• Le sessioni di login NON saranno copiate'
                      '${isProdToStaging ? '\n• Le email su staging andranno a dariolarosa@romeolab.it' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: targetColor.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info business
            Text('Business da copiare:', style: theme.textTheme.titleSmall),
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
                    Expanded(
                      child: Text(
                        _statusMessage ?? 'Copia in corso...',
                        style: theme.textTheme.bodyMedium,
                      ),
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
            style: FilledButton.styleFrom(
              backgroundColor: _direction == SyncDirection.prodToStaging
                  ? Colors.orange
                  : Colors.blue,
            ),
            child: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _direction == SyncDirection.prodToStaging
                        ? 'Copia su Staging'
                        : 'Copia su Produzione',
                  ),
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
              'Copia completata!',
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
              Text('Record copiati:', style: theme.textTheme.titleSmall),
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
    final isProdToStaging = _direction == SyncDirection.prodToStaging;
    final sourceEnv = isProdToStaging ? 'produzione' : 'staging';
    final targetEnv = isProdToStaging ? 'staging' : 'produzione';
    final isOnStaging = ApiConfig.isStaging;

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Esportazione business da $sourceEnv...';
      _result = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      Map<String, dynamic> exportData;

      // 1. Export business dalla sorgente
      setState(() {
        _statusMessage = 'Esportazione dati da $sourceEnv...';
      });

      if (isProdToStaging) {
        // Prod → Staging
        if (isOnStaging) {
          // Siamo su staging, export da produzione
          exportData = await apiClient.exportBusinessFromProduction(
            widget.business.id,
          );
        } else {
          // Siamo su produzione, export locale
          exportData = await apiClient.exportBusiness(widget.business.id);
        }
      } else {
        // Staging → Prod
        if (isOnStaging) {
          // Siamo su staging, export locale
          exportData = await apiClient.exportBusiness(widget.business.id);
        } else {
          // Siamo su produzione, export da staging
          exportData = await apiClient.exportBusinessFromStaging(
            widget.business.id,
          );
        }
      }

      // 2. Import sul target
      setState(() {
        _statusMessage = 'Import su $targetEnv...';
      });

      Map<String, dynamic> result;
      if (isProdToStaging) {
        // Target: staging
        if (isOnStaging) {
          // Siamo su staging, import locale
          result = await apiClient.importBusiness(exportData);
        } else {
          // Siamo su produzione, push a staging
          result = await apiClient.pushBusinessToStaging(exportData);
        }
      } else {
        // Target: produzione - skip sessioni e notifiche
        if (isOnStaging) {
          // Siamo su staging, push a produzione (skip sessioni/notifiche)
          result = await apiClient.pushBusinessToProduction(
            exportData,
            skipSessionsAndNotifications: true,
          );
        } else {
          // Siamo su produzione, import locale (skip sessioni/notifiche)
          result = await apiClient.importBusiness(
            exportData,
            skipSessionsAndNotifications: true,
          );
        }
      }

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

/// Card per selezionare la direzione della sincronizzazione
class _DirectionCard extends StatelessWidget {
  const _DirectionCard({
    required this.selected,
    required this.onTap,
    required this.sourceLabel,
    required this.targetLabel,
    required this.sourceIcon,
    required this.targetIcon,
    required this.color,
  });

  final bool selected;
  final VoidCallback? onTap;
  final String sourceLabel;
  final String targetLabel;
  final IconData sourceIcon;
  final IconData targetIcon;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? color.withValues(alpha: 0.15)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(sourceIcon, size: 20, color: colorScheme.onSurface),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                  const SizedBox(width: 4),
                  Icon(targetIcon, size: 20, color: color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$sourceLabel → $targetLabel',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? color.shade700 : colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostra il dialog per copiare un business su staging.
/// Ritorna `true` se la copia è avvenuta con successo.
Future<bool?> showSyncToStagingDialog(BuildContext context, Business business) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SyncToStagingDialog(business: business),
  );
}
