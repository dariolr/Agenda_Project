import 'package:flutter/material.dart';

import '../../../../core/widgets/app_buttons.dart';
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
    final displayIndex = currentIndex + 1;
    final canApplyToThisAndFuture =
        displayIndex > 1 && displayIndex < totalCount;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cancelButton = AppOutlinedActionButton(
      onPressed: () => Navigator.pop(context),
      borderColor: theme.colorScheme.outline,
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      child: Text(l10n.actionCancel),
    );
    final onlyThisButton = AppOutlinedActionButton(
      onPressed: () => Navigator.pop(
        context,
        const RecurringDeleteResult(scope: RecurringActionScope.single),
      ),
      child: Text(l10n.recurringScopeOnlyThis),
    );
    final thisAndFutureButton = AppFilledButton(
      onPressed: () => Navigator.pop(
        context,
        const RecurringDeleteResult(
          scope: RecurringActionScope.thisAndFuture,
        ),
      ),
      child: Text(l10n.recurringScopeThisAndFuture),
    );
    final allButton = AppDangerButton(
      onPressed: () => Navigator.pop(
        context,
        const RecurringDeleteResult(scope: RecurringActionScope.all),
      ),
      child: Text(l10n.recurringScopeAll),
    );

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
            l10n.recurringDeleteMessage(displayIndex, totalCount),
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
      actions: isMobile
          ? [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: onlyThisButton),
                        const SizedBox(width: 8),
                        Expanded(
                          child: canApplyToThisAndFuture
                              ? thisAndFutureButton
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: cancelButton),
                        const SizedBox(width: 8),
                        Expanded(child: allButton),
                      ],
                    ),
                  ],
                ),
              ),
            ]
          : [
              cancelButton,
              onlyThisButton,
              if (canApplyToThisAndFuture) thisAndFutureButton,
              allButton,
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
    final displayIndex = currentIndex + 1;
    final canApplyToThisAndFuture =
        displayIndex > 1 && displayIndex < totalCount;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cancelButton = AppOutlinedActionButton(
      onPressed: () => Navigator.pop(context),
      borderColor: theme.colorScheme.outline,
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      child: Text(l10n.actionCancel),
    );
    final onlyThisButton = AppOutlinedActionButton(
      onPressed: () => Navigator.pop(
        context,
        const RecurringEditResult(scope: RecurringActionScope.single),
      ),
      child: Text(l10n.recurringScopeOnlyThis),
    );
    final thisAndFutureButton = AppFilledButton(
      onPressed: () => Navigator.pop(
        context,
        const RecurringEditResult(
          scope: RecurringActionScope.thisAndFuture,
        ),
      ),
      child: Text(l10n.recurringScopeThisAndFuture),
    );
    final allButton = AppOutlinedActionButton(
      onPressed: () => Navigator.pop(
        context,
        const RecurringEditResult(scope: RecurringActionScope.all),
      ),
      child: Text(l10n.recurringScopeAll),
    );

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
            l10n.recurringEditMessage(displayIndex, totalCount),
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
      actions: isMobile
          ? [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: onlyThisButton),
                        const SizedBox(width: 8),
                        Expanded(
                          child: canApplyToThisAndFuture
                              ? thisAndFutureButton
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: cancelButton),
                        const SizedBox(width: 8),
                        Expanded(child: allButton),
                      ],
                    ),
                  ],
                ),
              ),
            ]
          : [
              cancelButton,
              onlyThisButton,
              if (canApplyToThisAndFuture) thisAndFutureButton,
              allButton,
            ],
    );
  }
}
