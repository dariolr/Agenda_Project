import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../providers/clients_providers.dart';
import '../dialogs/client_edit_dialog.dart';
import 'client_card.dart';

class ClientList extends ConsumerStatefulWidget {
  const ClientList({super.key});

  @override
  ConsumerState<ClientList> createState() => _ClientListState();
}

class _ClientListState extends ConsumerState<ClientList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Carica più clienti quando siamo a 200px dal fondo
      final state = ref.read(clientsProvider).value;
      if (state != null && state.hasMore && !state.isLoadingMore) {
        ref.read(clientsProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(filteredClientsProvider);
    final clientsState = ref.watch(clientsProvider).value;
    final hasMore = clientsState?.hasMore ?? false;
    final isLoadingMore = clientsState?.isLoadingMore ?? false;

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
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: clients.length + (hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= clients.length) {
                // Loading indicator at the end
                return Center(
                  child: isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                );
              }
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
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, i) {
        if (i >= clients.length) {
          // Loading indicator at the end
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }
        final c = clients[i];
        return ClientCard(
          client: c,
          onTap: () => showClientEditDialog(context, ref, client: c),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: clients.length + (hasMore ? 1 : 0),
    );
  }
}
