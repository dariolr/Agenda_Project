import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/user_menu_button.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/business.dart';
import '../../agenda/providers/business_providers.dart';
import '../providers/superadmin_selected_business_provider.dart';

/// Schermata selezione business per utenti non superadmin.
/// Mostra solo la lista dei business accessibili, senza azioni CRUD.
class UserBusinessSwitchScreen extends ConsumerWidget {
  const UserBusinessSwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(businessesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona Business'),
        centerTitle: true,
        actions: const [UserMenuButton(), SizedBox(width: 8)],
      ),
      body: businessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Text(
                'Nessun business disponibile',
                style: theme.textTheme.titleMedium,
              ),
            );
          }

          if (businesses.length == 1) {
            final onlyBusiness = businesses.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final currentId = ref.read(currentBusinessIdProvider);
              if (currentId != onlyBusiness.id) {
                ref
                    .read(currentBusinessIdProvider.notifier)
                    .selectByUser(onlyBusiness.id);
                invalidateBusinessScopedProviders(ref);
              }
              if (context.mounted) {
                context.go('/agenda');
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          return _UserBusinessList(
            businesses: businesses,
            onSelect: (business) {
              ref
                  .read(currentBusinessIdProvider.notifier)
                  .selectByUser(business.id);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                invalidateBusinessScopedProviders(ref);
                context.go('/agenda');
              });
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Errore nel caricamento: $error',
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _UserBusinessList extends StatelessWidget {
  const _UserBusinessList({required this.businesses, required this.onSelect});

  final List<Business> businesses;
  final void Function(Business business) onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: businesses.length,
          itemBuilder: (context, index) {
            final business = businesses[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelect(business),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(
                          business.name.isNotEmpty
                              ? business.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              business.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (business.userRole != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _roleLabel(context, business.userRole!),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _roleLabel(BuildContext context, String role) {
    final l10n = context.l10n;
    return switch (role) {
      'admin' => l10n.operatorsRoleAdmin,
      'manager' => l10n.operatorsRoleManager,
      'staff' => l10n.operatorsRoleStaff,
      'viewer' =>
        Localizations.localeOf(context).languageCode == 'it'
            ? 'Visualizzatore'
            : 'Viewer',
      _ => role,
    };
  }
}
