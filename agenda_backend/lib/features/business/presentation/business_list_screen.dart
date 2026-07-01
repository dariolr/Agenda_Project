import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/router_debug_log_provider.dart';
import '../../../app/widgets/user_menu_button.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/initials_utils.dart';
import '../../../core/utils/price_utils.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../billing/presentation/admin_business_billing_config_dialog.dart';
import '../domain/business_sorting.dart';
import '../providers/business_providers.dart';
import '../providers/superadmin_selected_business_provider.dart';
import 'dialogs/business_whatsapp_settings_dialog.dart';
import 'dialogs/create_business_dialog.dart';
import 'dialogs/edit_business_dialog.dart';

/// Schermata lista business per superadmin.
/// Mostra tutti i business con possibilità di selezionarne uno o crearne uno nuovo.
class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  static const String _appBuildVersion = String.fromEnvironment(
    'APP_BUILD_VERSION',
    defaultValue: 'dev',
  );
  static const String _buildBannerText =
      'Build $_appBuildVersion · GoRouter.go (in-app)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final businessesAsync = ref.watch(businessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona Business'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              _buildBannerText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Router Debug Log',
            onPressed: () => _showDebugLogPanel(context, ref),
            icon: const Text(
              'LOG',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: context.l10n.bookingNotificationsTitle,
            onPressed: () => context.go('/businesses/notifiche-prenotazioni'),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          // Menu utente (profilo, cambia password, logout)
          const UserMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: businessesAsync.when(
        data: (businesses) {
          final orderedBusinesses = sortBusinessesForSelection(businesses);
          return Column(
            children: [
              _BillingTotalsBar(businesses: orderedBusinesses),
              Expanded(
                child: _BusinessList(
                  businesses: orderedBusinesses,
                  onSelect: (business) =>
                      _selectBusiness(context, ref, business),
                  onEdit: (business) =>
                      _showEditBusinessDialog(context, ref, business),
                  onResendInvite: (business) =>
                      _showResendInviteDialog(context, ref, business),
                  onSuspend: (business) =>
                      _showSuspendDialog(context, ref, business),
                  onBilling: (business) =>
                      _showBillingDialog(context, ref, business),
                  onWhatsapp: (business) =>
                      _showWhatsappDialog(context, ref, business),
                  onDelete: (business) =>
                      _showDeleteDialog(context, ref, business),
                ),
              ),
            ],
          );
        },
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

  Future<void> _selectBusiness(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    // 1) Aggiorna lo stato e attende la persistenza completa delle preferenze.
    await ref
        .read(superadminSelectedBusinessProvider.notifier)
        .switchBusiness(business.id);

    // 2) Allinea il business corrente usato dai provider della shell.
    ref.read(currentBusinessIdProvider.notifier).selectByUser(business.id);

    // 3) Navigazione verso /agenda via GoRouter.
    if (context.mounted) {
      GoRouter.of(context).go('/agenda');
    }

    // 4) Invalida i provider scoped al business precedente DOPO la navigazione,
    // per evitare che le notifiche di invalidation triggherino il redirect guard
    // prima che GoRouter abbia registrato la nuova location /agenda.
    invalidateBusinessScopedProviders(ref);
    ref.invalidate(currentBusinessUserContextProvider);

    // 5) Aggiorna la location selection appena le sedi del nuovo business sono disponibili.
    unawaited(_syncCurrentLocationForSelectedBusiness(ref));
  }

  Future<void> _showDebugLogPanel(BuildContext context, WidgetRef ref) {
    return AppBottomSheet.show<void>(
      context: context,
      adaptiveHeight: true,
      builder: (ctx) => Consumer(
        builder: (_, innerRef, _) {
          final logs = innerRef.watch(routerDebugLogProvider);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Router Debug Log',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: logs.join('\n')));
                      },
                      child: const Text('Copia'),
                    ),
                    TextButton(
                      onPressed: () => innerRef
                          .read(routerDebugLogProvider.notifier)
                          .clear(),
                      child: const Text('Clear'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Flexible(
                  child: logs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No logs yet'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: logs.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              logs[i],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _syncCurrentLocationForSelectedBusiness(WidgetRef ref) async {
    try {
      final locations = await ref.read(locationsAsyncProvider.future);
      if (locations.isEmpty) return;

      final currentLocationId = ref.read(currentLocationIdProvider);
      final hasCurrent = locations.any((l) => l.id == currentLocationId);
      if (!hasCurrent) {
        ref.read(currentLocationIdProvider.notifier).set(locations.first.id);
      }
    } catch (_) {
      // Non bloccare il cambio business per un errore temporaneo sulle sedi.
    }
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

  Future<void> _showBillingDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final updated = await showAdminBusinessBillingConfigDialog(
      context,
      businessId: business.id,
      businessName: business.name,
    );
    if (updated == true) {
      ref.read(businessesRefreshProvider.notifier).refresh();
    }
  }

  Future<void> _showWhatsappDialog(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) async {
    final updated = await showBusinessWhatsappSettingsDialog(
      context,
      businessId: business.id,
      businessName: business.name,
    );
    if (updated == true) {
      ref.read(businessesRefreshProvider.notifier).refresh();
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

/// Barra riepilogo importi abbonamenti: totale, totale in regola (verde),
/// totale non pagato (rosso). Mostrata sopra la lista business.
class _BillingTotalsBar extends StatelessWidget {
  const _BillingTotalsBar({required this.businesses});

  final List<Business> businesses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var totalCents = 0;
    var greenCents = 0;
    var redCents = 0;
    var currency = 'EUR';

    for (final b in businesses) {
      if (!b.billingEnabled || b.billingAmountCents == null) continue;
      final cents = b.billingAmountCents!;
      totalCents += cents;
      if (b.subscriptionStatus == 'active') {
        greenCents += cents;
      } else {
        redCents += cents;
      }
      currency = b.currency;
    }

    if (totalCents == 0) return const SizedBox.shrink();

    String fmt(int cents) => PriceFormatter.format(
      context: context,
      amount: cents / 100,
      currencyCode: currency,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _totalChip(
            theme: theme,
            label: 'Totale',
            value: fmt(totalCents),
            color: colorScheme.onSurfaceVariant,
            background: colorScheme.surfaceContainerHighest,
          ),
          _totalChip(
            theme: theme,
            label: 'In regola',
            value: fmt(greenCents),
            color: Colors.green.shade700,
            background: Colors.green.withValues(alpha: 0.15),
          ),
          _totalChip(
            theme: theme,
            label: 'Non pagato',
            value: fmt(redCents),
            color: Colors.red.shade700,
            background: Colors.red.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _totalChip({
    required ThemeData theme,
    required String label,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessList extends StatelessWidget {
  const _BusinessList({
    required this.businesses,
    required this.onSelect,
    required this.onEdit,
    required this.onResendInvite,
    required this.onSuspend,
    required this.onBilling,
    required this.onWhatsapp,
    required this.onDelete,
  });

  final List<Business> businesses;
  final void Function(Business) onSelect;
  final void Function(Business) onEdit;
  final void Function(Business) onResendInvite;
  final void Function(Business) onSuspend;
  final void Function(Business) onBilling;
  final void Function(Business) onWhatsapp;
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
              onBilling: () => onBilling(business),
              onWhatsapp: () => onWhatsapp(business),
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
    required this.onBilling,
    required this.onWhatsapp,
    required this.onDelete,
  });

  final Business business;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onResendInvite;
  final VoidCallback onSuspend;
  final VoidCallback onBilling;
  final VoidCallback onWhatsapp;
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
                        // Tag ammontare abbonamento (verde=attivo, rosso=non in regola)
                        if (business.billingEnabled &&
                            business.billingAmountCents != null) ...[
                          Builder(
                            builder: (context) {
                              final isPaid =
                                  business.subscriptionStatus == 'active';
                              final tagColor = isPaid
                                  ? Colors.green
                                  : Colors.red;
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 4 : 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  PriceFormatter.format(
                                    context: context,
                                    amount: business.billingAmountCents! / 100,
                                    currencyCode: business.currency,
                                  ),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: tagColor.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isCompact ? 9 : 11,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                        ],
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
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'resend':
                      onResendInvite();
                    case 'suspend':
                      onSuspend();
                    case 'billing':
                      onBilling();
                    case 'whatsapp':
                      onWhatsapp();
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
                    value: 'billing',
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: Text(context.l10n.billingTitle),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'whatsapp',
                    child: ListTile(
                      leading: SvgPicture.asset(
                        'assets/icons/whatsapp.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF25D366),
                          BlendMode.srcIn,
                        ),
                      ),
                      title: Text(
                        context.l10n.businessWhatsappSettingsMenuItem,
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
