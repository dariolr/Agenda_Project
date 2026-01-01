import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/user_menu_button.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';
import '../../agenda/providers/agenda_scroll_provider.dart';
import '../../agenda/providers/appointment_providers.dart';
import '../../agenda/providers/bookings_provider.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/date_range_provider.dart';
import '../../agenda/providers/drag_session_provider.dart';
import '../../agenda/providers/dragged_appointment_provider.dart';
import '../../agenda/providers/dragged_base_range_provider.dart';
import '../../agenda/providers/layout_config_provider.dart';
import '../../agenda/providers/location_providers.dart';
import '../../agenda/providers/pending_drop_provider.dart';
import '../../agenda/providers/resizing_provider.dart';
import '../../agenda/providers/resource_providers.dart';
import '../../agenda/providers/selected_appointment_provider.dart';
import '../../agenda/providers/staff_filter_providers.dart';
import '../../agenda/providers/temp_drag_time_provider.dart';
import '../../agenda/providers/time_blocks_provider.dart';
import '../../clients/providers/clients_providers.dart';
import '../../services/providers/service_categories_provider.dart';
import '../../services/providers/services_provider.dart';
import '../../staff/providers/availability_exceptions_provider.dart';
import '../../staff/providers/staff_providers.dart';
import '../providers/business_providers.dart';
import 'dialogs/create_business_dialog.dart';
import 'dialogs/edit_business_dialog.dart';

/// Notifier per tracciare se il superadmin ha selezionato un business.
/// Quando è null, mostra la lista business.
class SuperadminSelectedBusinessNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int businessId) => state = businessId;

  /// Pulisce la selezione e invalida tutti i provider relativi al business.
  void clear() {
    state = null;
    // Invalida tutti i provider business-specific per forzare ricaricamento
    _invalidateBusinessProviders();
  }

  /// Invalida tutti i provider che contengono dati specifici del business.
  void _invalidateBusinessProviders() {
    // Staff
    ref.invalidate(allStaffProvider);

    // Locations
    ref.invalidate(locationsProvider);
    ref.invalidate(currentLocationProvider);

    // Services
    ref.invalidate(servicesProvider);
    ref.invalidate(serviceCategoriesProvider);
    ref.invalidate(serviceStaffEligibilityProvider);

    // Clients
    ref.invalidate(clientsProvider);

    // Appointments
    ref.invalidate(appointmentsProvider);

    // Bookings (prenotazioni con note/customerName)
    ref.invalidate(bookingsProvider);

    // Resources
    ref.invalidate(resourcesProvider);

    // Time Blocks
    ref.invalidate(timeBlocksProvider);

    // Availability Exceptions
    ref.invalidate(availabilityExceptionsProvider);

    // UI State legato al business (contiene ID di entità business-specific)
    ref.invalidate(selectedStaffIdsProvider);
    ref.invalidate(staffFilterModeProvider);
    ref.invalidate(selectedAppointmentProvider);
    ref.invalidate(dragSessionProvider);
    ref.invalidate(draggedAppointmentIdProvider);
    ref.invalidate(draggedBaseRangeProvider);
    ref.invalidate(tempDragTimeProvider);
    ref.invalidate(resizingProvider);
    ref.invalidate(pendingDropProvider);

    // Business ID corrente (currentBusinessProvider è derivato, si aggiorna da solo)
    ref.invalidate(currentBusinessIdProvider);

    // Layout e UI state (per sicurezza, anche se sembrano UI-only)
    ref.invalidate(layoutConfigProvider);
    ref.invalidate(agendaDateProvider);
    ref.invalidate(agendaScrollProvider);
  }
}

final superadminSelectedBusinessProvider =
    NotifierProvider<SuperadminSelectedBusinessNotifier, int?>(
      SuperadminSelectedBusinessNotifier.new,
    );

/// Schermata lista business per superadmin.
/// Mostra tutti i business con possibilità di selezionarne uno o crearne uno nuovo.
class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final businessesAsync = ref.watch(businessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona Business'),
        centerTitle: true,
        actions: [
          // Menu utente (profilo, cambia password, logout)
          const UserMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: businessesAsync.when(
        data: (businesses) => _BusinessList(
          businesses: businesses,
          onSelect: (business) => _selectBusiness(context, ref, business),
          onEdit: (business) => _showEditBusinessDialog(context, ref, business),
          onResendInvite: (business) =>
              _showResendInviteDialog(context, ref, business),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Errore nel caricamento',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(businessesProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBusinessDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  void _selectBusiness(BuildContext context, WidgetRef ref, Business business) {
    // Imposta il business corrente
    ref.read(currentBusinessIdProvider.notifier).set(business.id);
    // Segna che il superadmin ha selezionato un business
    ref.read(superadminSelectedBusinessProvider.notifier).select(business.id);
    // Naviga all'agenda
    context.go('/agenda');
  }

  Future<void> _showCreateBusinessDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final created = await showCreateBusinessDialog(context);
    if (created == true) {
      // Forza il refresh della lista
      ref.read(businessesRefreshProvider.notifier).refresh();
    }
  }

  Future<void> _showEditBusinessDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final updated = await showEditBusinessDialog(context, business);
    if (updated == true) {
      // Forza il refresh della lista
      ref.read(businessesRefreshProvider.notifier).refresh();
    }
  }

  Future<void> _showResendInviteDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reinvia invito'),
        content: Text(
          business.adminEmail != null
              ? 'Vuoi reinviare l\'email di invito a ${business.adminEmail}?'
              : 'Questo business non ha un admin email configurato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          if (business.adminEmail != null)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Invia'),
            ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(businessRepositoryProvider);
        await repository.resendAdminInvite(business.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invito inviato a ${business.adminEmail}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: ${e.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class _BusinessList extends StatelessWidget {
  const _BusinessList({
    required this.businesses,
    required this.onSelect,
    required this.onEdit,
    required this.onResendInvite,
  });

  final List<Business> businesses;
  final void Function(Business) onSelect;
  final void Function(Business) onEdit;
  final void Function(Business) onResendInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun business',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo business per iniziare',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid
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
            return _BusinessCard(
              business: business,
              onTap: () => onSelect(business),
              onEdit: () => onEdit(business),
              onResendInvite: () => onResendInvite(business),
            );
          },
        );
      },
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.business,
    required this.onTap,
    required this.onEdit,
    required this.onResendInvite,
  });

  final Business business;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onResendInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar con iniziale
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  business.name.isNotEmpty
                      ? business.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info business
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ID: ${business.id}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (business.slug != null)
                      Text(
                        business.slug!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (business.adminEmail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Admin: ${business.adminEmail}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Menu azioni
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'resend':
                      onResendInvite();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifica'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'resend',
                    child: ListTile(
                      leading: Icon(Icons.email_outlined),
                      title: Text('Reinvia invito'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
              const SizedBox(width: 4),
              // Freccia per entrare
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
