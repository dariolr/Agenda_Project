import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../agenda/providers/business_providers.dart';

/// Schermata impostazioni business.
///
/// Permette di accedere alle impostazioni del business corrente:
/// - Gestione operatori
/// - Altre impostazioni future...
class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(business.name)),
      body: ListView(
        children: [
          // Gestione Operatori
          ListTile(
            leading: const Icon(Icons.supervisor_account_outlined),
            title: Text(l10n.operatorsTitle),
            subtitle: Text(l10n.operatorsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/operatori/${business.id}'),
          ),
          const Divider(),
          // Placeholder per future impostazioni
          // ListTile(
          //   leading: const Icon(Icons.settings_outlined),
          //   title: Text('Impostazioni'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }
}
