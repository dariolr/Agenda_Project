import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-level dialog scaffolds to ensure consistent layout across features.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.contentPadding = const EdgeInsets.only(top: 8),
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dialogTheme = base.copyWith(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      switchTheme: base.switchTheme.copyWith(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return base.colorScheme.primary;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return base.colorScheme.primary.withOpacity(0.35);
          }
          return null;
        }),
      ),
      radioTheme: base.radioTheme.copyWith(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return base.colorScheme.primary;
          }
          return null;
        }),
      ),
    );
    return Theme(
      data: dialogTheme,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context, rootNavigator: true).pop(),
        },
        child: Focus(
          autofocus: true,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DefaultTextStyle(
                      style: dialogTheme.textTheme.titleLarge ??
                          base.textTheme.titleLarge ??
                          const TextStyle(fontSize: 18),
                      child: title,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        padding: contentPadding,
                        child: content,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: 8,
                      overflowSpacing: 4,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAppConfirmDialog(
  BuildContext context, {
  required Widget title,
  Widget? content,
  required String confirmLabel,
  required VoidCallback onConfirm,
  String? cancelLabel,
  bool danger = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  return showDialog(
    context: context,
    builder: (_) {
      final base = Theme.of(context);
      final dialogTheme = base.copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        switchTheme: base.switchTheme.copyWith(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return base.colorScheme.primary;
            }
            return null;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return base.colorScheme.primary.withOpacity(0.35);
            }
            return null;
          }),
        ),
        radioTheme: base.radioTheme.copyWith(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
      );
      return Theme(
        data: dialogTheme,
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context, rootNavigator: true).pop(),
            SingleActivator(LogicalKeyboardKey.enter): () {
              onConfirm();
              Navigator.of(context, rootNavigator: true).pop();
            },
          },
          child: Focus(
            autofocus: true,
            child: AlertDialog(
              title: title,
              content: content,
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(cancelLabel ?? 'Annulla'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onConfirm();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  style: danger
                      ? ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        )
                      : null,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showAppInfoDialog(
  BuildContext context, {
  required Widget title,
  Widget? content,
  String? closeLabel,
}) {
  return showDialog(
    context: context,
    builder: (_) {
      final base = Theme.of(context);
      final dialogTheme = base.copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        switchTheme: base.switchTheme.copyWith(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return base.colorScheme.primary;
            }
            return null;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return base.colorScheme.primary.withOpacity(0.35);
            }
            return null;
          }),
        ),
        radioTheme: base.radioTheme.copyWith(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
      );
      return Theme(
        data: dialogTheme,
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context, rootNavigator: true).pop(),
            SingleActivator(LogicalKeyboardKey.enter): () =>
                Navigator.of(context, rootNavigator: true).pop(),
          },
          child: Focus(
            autofocus: true,
            child: AlertDialog(
              title: title,
              content: content,
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(closeLabel ?? 'Chiudi'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Mostra un dialog di conferma e ritorna true se confermato, false altrimenti.
/// Utile per operazioni che richiedono conferma esplicita prima di procedere.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required Widget title,
  Widget? content,
  required String confirmLabel,
  String? cancelLabel,
  bool danger = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      final base = Theme.of(context);
      final dialogTheme = base.copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      );
      return Theme(
        data: dialogTheme,
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context, rootNavigator: true).pop(false),
          },
          child: Focus(
            autofocus: true,
            child: AlertDialog(
              title: title,
              content: content,
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(false),
                  child: Text(cancelLabel ?? 'Annulla'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(true),
                  style: danger
                      ? ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        )
                      : null,
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Wrapper per dialog che gestisce automaticamente la chiusura con ESC.
/// Wrappa qualsiasi widget dialog per aggiungere supporto ESC.
class DismissibleDialog extends StatelessWidget {
  const DismissibleDialog({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context, rootNavigator: true).pop(),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
