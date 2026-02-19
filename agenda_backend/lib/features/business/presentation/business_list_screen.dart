import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/user_menu_button.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/initials_utils.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../providers/business_providers.dart';
import '../providers/superadmin_selected_business_provider.dart';
import 'dialogs/create_business_dialog.dart';
import 'dialogs/edit_business_dialog.dart';

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
          onSuspend: (business) => _showSuspendDialog(context, ref, business),
          onDelete: (business) => _showDeleteDialog(context, ref, business),
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
    ref.read(currentBusinessIdProvider.notifier).selectByUser(business.id);
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
          await FeedbackDialog.showSuccess(
            context,
            title: 'Invito inviato',
            message: 'Invito inviato a ${business.adminEmail}',
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          await FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: e.message,
          );
        }
      } catch (e) {
        if (context.mounted) {
          await FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: e.toString(),
          );
        }
      }
    }
  }

  /// Mostra dialog per sospendere/riattivare un business
  Future<void> _showSuspendDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final l10n = context.l10n;
    final isSuspended = business.isSuspended;

    // Se è già sospeso, mostra dialog per riattivare
    if (isSuspended) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Riattiva Business'),
          content: Text(
            'Vuoi riattivare "${business.name}"?\n\n'
            'Gli operatori e i clienti potranno accedere normalmente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Riattiva'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await _executeSuspend(context, ref, business, false, null);
      }
      return;
    }

    // Dialog per sospendere con messaggio
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sospendi Business'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sospendendo "${business.name}" gli operatori vedranno un avviso '
                'e i clienti non potranno effettuare prenotazioni online.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Messaggio di sospensione (opzionale)',
                  hintText: 'Es: Chiuso per ferie fino al 15 gennaio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sospendi'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final message = messageController.text.trim().isEmpty
          ? null
          : messageController.text.trim();
      await _executeSuspend(context, ref, business, true, message);
    }
  }

  Future<void> _executeSuspend(
    BuildContext context,
    WidgetRef ref,
    Business business,
    bool isSuspended,
    String? message,
  ) async {
    try {
      final repository = ref.read(businessRepositoryProvider);
      await repository.suspendBusiness(
        businessId: business.id,
        isSuspended: isSuspended,
        suspensionMessage: message,
      );

      if (context.mounted) {
        final snackMessage = isSuspended
            ? '${business.name} sospeso'
            : '${business.name} riattivato';
        await FeedbackDialog.showSuccess(
          context,
          title: 'Operazione completata',
          message: snackMessage,
        );
        // Refresh lista
        ref.read(businessesRefreshProvider.notifier).refresh();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.message,
        );
      }
    } catch (e) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.toString(),
        );
      }
    }
  }

  /// Mostra dialog per eliminare un business
  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Business'),
        content: Text(
          'Sei sicuro di voler eliminare "${business.name}"?\n\n'
          '⚠️ Questa azione nasconderà il business dalla lista. '
          'I dati non verranno cancellati definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(businessRepositoryProvider);
        await repository.deleteBusiness(business.id);

        if (context.mounted) {
          final selectedBusinessId = ref.read(
            superadminSelectedBusinessProvider,
          );
          if (selectedBusinessId == business.id) {
            ref
                .read(superadminSelectedBusinessProvider.notifier)
                .clearCompletely();
          }
          await FeedbackDialog.showSuccess(
            context,
            title: 'Operazione completata',
            message: '${business.name} eliminato',
          );
          // Refresh lista
          ref.read(businessesRefreshProvider.notifier).refresh();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          await FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: e.message,
          );
        }
      } catch (e) {
        if (context.mounted) {
          await FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: e.toString(),
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
    required this.onSuspend,
    required this.onDelete,
  });

  final List<Business> businesses;
  final void Function(Business) onSelect;
  final void Function(Business) onEdit;
  final void Function(Business) onResendInvite;
  final void Function(Business) onSuspend;
  final void Function(Business) onDelete;

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
              onSuspend: () => onSuspend(business),
              onDelete: () => onDelete(business),
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
    required this.onSuspend,
    required this.onDelete,
  });

  final Business business;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onResendInvite;
  final VoidCallback onSuspend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 400;
    final businessInitial = InitialsUtils.fromName(business.name, maxChars: 1);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 10 : 16),
          child: Row(
            children: [
              // Avatar con iniziale
              CircleAvatar(
                radius: isCompact ? 18 : 24,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  businessInitial.isNotEmpty ? businessInitial : '?',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              // Info business
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style:
                                (isCompact
                                        ? theme.textTheme.bodyMedium
                                        : theme.textTheme.titleMedium)
                                    ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge sospeso
                        if (business.isSuspended) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 4 : 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pause_circle,
                                  size: isCompact ? 10 : 12,
                                  color: Colors.orange.shade700,
                                ),
                                SizedBox(width: isCompact ? 2 : 4),
                                Text(
                                  'Sospeso',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isCompact ? 9 : 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Badge ID
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 4 : 6,
                            vertical: 1,
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
                              fontSize: isCompact ? 9 : 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Slug (sempre) e admin email (solo desktop)
                    if (business.slug != null ||
                        (!isCompact && business.adminEmail != null))
                      SizedBox(height: isCompact ? 2 : 4),
                    if (business.slug != null ||
                        (!isCompact && business.adminEmail != null))
                      Text(
                        [
                          if (business.slug != null) business.slug!,
                          if (!isCompact && business.adminEmail != null)
                            business.adminEmail!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: isCompact ? 11 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                    case 'suspend':
                      onSuspend();
                    case 'delete':
                      onDelete();
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
                  PopupMenuItem(
                    value: 'suspend',
                    child: ListTile(
                      leading: Icon(
                        business.isSuspended
                            ? Icons.play_circle_outline
                            : Icons.pause_circle_outline,
                        color: business.isSuspended
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        business.isSuspended ? 'Riattiva' : 'Sospendi',
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Elimina',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
              // Freccia per entrare (solo su schermi non compatti)
              if (!isCompact) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
