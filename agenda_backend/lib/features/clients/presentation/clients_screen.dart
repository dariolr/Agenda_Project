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
  Widget build(BuildContext context) {
    final sortOption = ref.watch(clientSortOptionProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientsSearchField(
              hintText: context.l10n.clientsTitle,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            ClientsSortDropdown(
              value: sortOption,
              onChanged: (v) =>
                  ref.read(clientSortOptionProvider.notifier).set(v),
            ),
            // const SizedBox(height: 8),
            // ClientsFilterChips(
            //   selectedIndex: _filterIndex,
            //   onSelectedIndex: (i) => setState(() => _filterIndex = i),
            //   labelAll: context.l10n.filterAll,
            //   labelVIP: context.l10n.filterVIP,
            //   labelInactive: context.l10n.filterInactive,
            //   labelNew: context.l10n.filterNew,
            // ),
            const SizedBox(height: 8),
            Expanded(child: ClientList(query: _query)),
          ],
        ),
      ),
    );
  }
}
