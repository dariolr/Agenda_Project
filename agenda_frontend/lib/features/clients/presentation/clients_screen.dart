import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart'; // 🌍
import 'widgets/client_list.dart';
import 'widgets/clients_filter_chips.dart';
import 'widgets/clients_search_field.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';
  int _filterIndex = 0; // 0=all,1=VIP,2=Inactive,3=New

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientsSearchField(
              hintText: context.l10n.clientsTitle,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            ClientsFilterChips(
              selectedIndex: _filterIndex,
              onSelectedIndex: (i) => setState(() => _filterIndex = i),
              labelAll: context.l10n.filterAll,
              labelVIP: context.l10n.filterVIP,
              labelInactive: context.l10n.filterInactive,
              labelNew: context.l10n.filterNew,
            ),
            const SizedBox(height: 8),
            Expanded(child: ClientList(query: _query)),
          ],
        ),
      ),
    );
  }
}
