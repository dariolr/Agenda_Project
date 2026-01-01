import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../network/network_providers.dart';
import 'app_dialogs.dart';

/// Widget che ascolta il provider sessionExpiredProvider e
/// esegue logout automatico quando la sessione scade.
class SessionExpiredListener extends ConsumerWidget {
  const SessionExpiredListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (previous != null && next > previous) {
        _handleSessionExpired(context, ref);
      }
    });

    return child;
  }

  void _handleSessionExpired(BuildContext context, WidgetRef ref) {
    // Esegui logout silenzioso (senza chiamata API, sessione già scaduta)
    ref.read(authProvider.notifier).logout(silent: true);

    // Mostra dialog informativo
    if (context.mounted) {
      showAppInfoDialog(
        context,
        title: const Text('Sessione scaduta'),
        content: const Text(
          'La tua sessione è scaduta. Effettua nuovamente il login per continuare.',
        ),
        closeLabel: 'OK',
      ).then((_) {
        // Redirect a login dopo chiusura dialog
        if (context.mounted) {
          context.go('/login');
        }
      });
    }
  }
}
