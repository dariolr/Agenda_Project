import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../providers/clients_providers.dart';
import '../dialogs/client_edit_dialog.dart';
import 'client_card.dart';

class ClientList extends ConsumerWidget {
  const ClientList({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsSearchProvider(query));

    if (clients.isEmpty) {
      return Center(child: Text(context.l10n.clientsEmpty));
    }

    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) {
      // Griglia responsive
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = (width / 280).floor().clamp(2, 6);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: clients.length,
            itemBuilder: (_, i) {
              final c = clients[i];
              return ClientCard(
                client: c,
                onTap: () => showClientEditDialog(context, ref, client: c),
              );
            },
          );
        },
      );
    }

    // Lista verticale
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, i) {
        final c = clients[i];
        return ClientCard(
          client: c,
          onTap: () => showClientEditDialog(context, ref, client: c),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: clients.length,
    );
  }
}
