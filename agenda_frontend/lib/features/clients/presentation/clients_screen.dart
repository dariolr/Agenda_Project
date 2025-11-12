import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart'; // 🌍
import '../presentation/dialogs/client_edit_dialog.dart';
import 'widgets/client_list.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewClientDialog,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.actionNew),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.clientsTitle, // reuse existing
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(context.l10n.filterAll),
                    selected: _filterIndex == 0,
                    onSelected: (_) => setState(() => _filterIndex = 0),
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.filterVIP),
                    selected: _filterIndex == 1,
                    onSelected: (_) => setState(() => _filterIndex = 1),
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.filterInactive),
                    selected: _filterIndex == 2,
                    onSelected: (_) => setState(() => _filterIndex = 2),
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.filterNew),
                    selected: _filterIndex == 3,
                    onSelected: (_) => setState(() => _filterIndex = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: ClientList(query: _query)),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewClientDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const ClientEditDialog(),
    );
  }
}
