import 'package:flutter/material.dart';

/// Dialog per mostrare messaggi di feedback all'utente (successo/errore).
/// Sostituisce le SnackBar per un'esperienza più consistente.
class FeedbackDialog extends StatelessWidget {
  const FeedbackDialog({
    super.key,
    required this.title,
    required this.message,
    required this.isSuccess,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final bool isSuccess;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Mostra un dialog di successo
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => FeedbackDialog(
        title: title,
        message: message,
        isSuccess: true,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Mostra un dialog di errore
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => FeedbackDialog(
        title: title,
        message: message,
        isSuccess: false,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSuccess
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return AlertDialog(
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: color,
        size: 48,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction!();
            },
            child: Text(actionLabel!),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
