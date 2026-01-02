import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart'; // 🌍
import '../providers/clients_providers.dart';
import 'widgets/client_list.dart';
import 'widgets/clients_search_field.dart';
import 'widgets/clients_sort_dropdown.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';
  // int _filterIndex = 0; // 0=all,1=VIP,2=Inactive,3=New

  @override
  void initState() {
    super.initState();
    // Ricarica i clienti dal DB quando si entra nella schermata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortOption = ref.watch(clientSortOptionProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (clients) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClientsSearchField(
                hintText: context.l10n.clientsTitle,
                onChanged: (v) => setState(() => _query = v),
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
                      '${clients.length} clienti',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: ClientList(query: _query)),
            ],
          ),
        ),
      ),
    );
  }
}
