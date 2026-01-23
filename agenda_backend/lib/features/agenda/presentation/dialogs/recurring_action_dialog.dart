import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';

/// Enum che rappresenta lo scope dell'azione su una serie ricorrente
enum RecurringActionScope {
  /// Solo questo appuntamento
  single,

  /// Questo appuntamento e tutti i futuri nella serie
  thisAndFuture,

  /// Tutti gli appuntamenti nella serie
  all,
}

/// Risultato del dialog per la cancellazione di una prenotazione ricorrente
class RecurringDeleteResult {
  final RecurringActionScope scope;

  const RecurringDeleteResult({required this.scope});
}

/// Risultato del dialog per la modifica di una prenotazione ricorrente
class RecurringEditResult {
  final RecurringActionScope scope;

  const RecurringEditResult({required this.scope});
}

/// Dialog che chiede all'utente come procedere con la cancellazione
/// di una prenotazione che fa parte di una serie ricorrente.
Future<RecurringDeleteResult?> showRecurringDeleteDialog(
  BuildContext context, {
  required int currentIndex,
  required int totalCount,
}) async {
  return showDialog<RecurringDeleteResult>(
    context: context,
    builder: (context) => _RecurringDeleteDialog(
      currentIndex: currentIndex,
      totalCount: totalCount,
    ),
  );
}

/// Dialog che chiede all'utente come procedere con la modifica
/// di una prenotazione che fa parte di una serie ricorrente.
Future<RecurringEditResult?> showRecurringEditDialog(
  BuildContext context, {
  required int currentIndex,
  required int totalCount,
}) async {
  return showDialog<RecurringEditResult>(
    context: context,
    builder: (context) => _RecurringEditDialog(
      currentIndex: currentIndex,
      totalCount: totalCount,
    ),
  );
}

class _RecurringDeleteDialog extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  const _RecurringDeleteDialog({
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.repeat, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.recurringDeleteTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recurringDeleteMessage(currentIndex, totalCount),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.recurringDeleteChooseScope,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const RecurringDeleteResult(scope: RecurringActionScope.single),
          ),
          child: Text(l10n.recurringScopeOnlyThis),
        ),
        if (currentIndex < totalCount)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const RecurringDeleteResult(
                scope: RecurringActionScope.thisAndFuture,
              ),
            ),
            child: Text(l10n.recurringScopeThisAndFuture),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: () => Navigator.pop(
            context,
            const RecurringDeleteResult(scope: RecurringActionScope.all),
          ),
          child: Text(l10n.recurringScopeAll),
        ),
      ],
    );
  }
}

class _RecurringEditDialog extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  const _RecurringEditDialog({
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.repeat, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.recurringEditTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recurringEditMessage(currentIndex, totalCount),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.recurringEditChooseScope,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const RecurringEditResult(scope: RecurringActionScope.single),
          ),
          child: Text(l10n.recurringScopeOnlyThis),
        ),
        if (currentIndex < totalCount)
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              const RecurringEditResult(
                scope: RecurringActionScope.thisAndFuture,
              ),
            ),
            child: Text(l10n.recurringScopeThisAndFuture),
          ),
      ],
    );
  }
}
