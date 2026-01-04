import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart'; // 🌍
import '../providers/clients_providers.dart';
import 'widgets/client_list.dart';
import 'widgets/clients_search_field.dart';
import 'widgets/clients_sort_dropdown.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOption = ref.watch(clientSortOptionProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final searchQuery = ref.watch(clientSearchQueryProvider);

    return Scaffold(
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (_) {
          final filteredClients = ref.watch(filteredClientsProvider);
          final totalClients = ref.watch(totalClientsCountProvider);
          final hasSearch = searchQuery.trim().isNotEmpty;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientsSearchField(
                  hintText: context.l10n.clientsTitle,
                  initialValue: searchQuery,
                  onChanged: (v) =>
                      ref.read(clientSearchQueryProvider.notifier).set(v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ClientsSortDropdown(
                      value: sortOption,
                      onChanged: (v) =>
                          ref.read(clientSortOptionProvider.notifier).set(v),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        hasSearch
                            ? '${filteredClients.length}/$totalClients ${context.l10n.navClients.toLowerCase()}'
                            : '$totalClients ${context.l10n.navClients.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Expanded(child: ClientList()),
              ],
            ),
          );
        },
      ),
    );
  }
}
