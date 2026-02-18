import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers/form_factor_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/business_invitation.dart';
import '../../../core/models/business_user.dart';
import '../../../core/models/location.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';
import '../providers/business_users_provider.dart';
import 'dialogs/role_selection_dialog.dart';

/// Schermata per la gestione degli operatori di un business.
class OperatorsScreen extends ConsumerWidget {
  const OperatorsScreen({super.key, this.businessId});

  /// Se null, usa currentBusinessIdProvider (navigazione shell, senza Scaffold)
  final int? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int effectiveBusinessId =
        businessId ?? ref.watch(currentBusinessIdProvider);

    // Se businessId è passato esplicitamente → navigazione push, serve Scaffold con back button
    if (businessId != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(context.l10n.permissionsTitle),
        ),
        body: _OperatorsBody(businessId: effectiveBusinessId),
      );
    }

    // Navigazione shell → niente Scaffold (la toolbar è gestita da ScaffoldWithNavigation)
    return _OperatorsBody(businessId: effectiveBusinessId);
  }
}

class _OperatorsBody extends ConsumerStatefulWidget {
  const _OperatorsBody({required this.businessId});

  final int businessId;

  @override
  ConsumerState<_OperatorsBody> createState() => _OperatorsBodyState();
}

class _OperatorsBodyState extends ConsumerState<_OperatorsBody> {
  bool _showHistoricalInvitations = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessUsersProvider(widget.businessId));
    final l10n = context.l10n;

    return _buildBody(context, ref, state, l10n);
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BusinessUsersState state,
    dynamic l10n,
  ) {
    final pendingInvitations = state.invitations.where((i) => i.isPending).toList();
    final historicalInvitations = state.invitations
        // Non mostrare inviti già accettati: l'utente è ormai un operatore attivo.
        .where((i) => !i.isPending && i.effectiveStatus != 'accepted')
        .toList();

    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(businessUsersProvider(widget.businessId).notifier)
                  .refresh(),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(businessUsersProvider(widget.businessId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          if (state.isLoading && state.users.isNotEmpty)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          // Header con sottotitolo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.operatorsSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Sezione inviti pendenti
          if (pendingInvitations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.operatorsPendingInvitesCount(
                        pendingInvitations.length,
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _InvitationTile(
                  invitation: pendingInvitations[index],
                  businessId: widget.businessId,
                  enableActions: !state.isLoading,
                ),
                childCount: pendingInvitations.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 32, indent: 16, endIndent: 16),
            ),
          ],

          if (historicalInvitations.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    selected: _showHistoricalInvitations,
                    onSelected: (selected) {
                      setState(() => _showHistoricalInvitations = selected);
                    },
                    label: Text(
                      _historicalToggleLabel(
                        context,
                        historicalInvitations.length,
                        _showHistoricalInvitations,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (historicalInvitations.isNotEmpty && _showHistoricalInvitations) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.operatorsInvitesHistoryCount(
                    historicalInvitations.length,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _InvitationTile(
                  invitation: historicalInvitations[index],
                  businessId: widget.businessId,
                  enableActions: !state.isLoading,
                ),
                childCount: historicalInvitations.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 32, indent: 16, endIndent: 16),
            ),
          ],

          // Lista operatori attivi
          if (state.users.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.operatorsEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = state.users[index];
                // Key composita per forzare rebuild quando cambiano i dati
                return _UserTile(
                  key: ValueKey(
                    '${user.userId}_${user.role}_${user.scopeType}_${user.locationIds.join(',')}',
                  ),
                  user: user,
                  businessId: widget.businessId,
                  enableActions: !state.isLoading,
                );
              }, childCount: state.users.length),
            ),

          // Padding finale
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _historicalToggleLabel(
    BuildContext context,
    int count,
    bool selected,
  ) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    if (selected) {
      return isEn ? 'Hide invite history' : 'Nascondi storico inviti';
    }
    return isEn ? 'Show invite history ($count)' : 'Mostra storico inviti ($count)';
  }
}

/// Tile per visualizzare un invito pendente.
class _InvitationTile extends ConsumerWidget {
  const _InvitationTile({
    required this.invitation,
    required this.businessId,
    this.enableActions = true,
  });

  final BusinessInvitation invitation;
  final int businessId;
  final bool enableActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMd();
    final statusColor = _statusColor(colorScheme, invitation.effectiveStatus);
    final statusLabel = _statusLabel(l10n, invitation.effectiveStatus);
    final canResend = enableActions && invitation.isPending;
    final canRevoke = enableActions && invitation.isPending;
    final canDelete = enableActions && !invitation.isPending;
    final resendLabel = Localizations.localeOf(context).languageCode == 'en'
        ? 'Resend invite'
        : 'Reinvia invito';
    final trailing = enableActions
        ? PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'resend') {
                _resendInvitation(context, ref);
              } else if (value == 'revoke') {
                _confirmRevoke(context, ref);
              } else if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (context) {
              final entries = <PopupMenuEntry<String>>[];
              if (canResend) {
                entries.add(
                  PopupMenuItem(
                    value: 'resend',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh, size: 20),
                        const SizedBox(width: 12),
                        Text(resendLabel),
                      ],
                    ),
                  ),
                );
              }
              if (canRevoke) {
                entries.add(
                  PopupMenuItem(
                    value: 'revoke',
                    child: Row(
                      children: [
                        Icon(
                          Icons.block_outlined,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.operatorsRevokeInvite,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (canDelete) {
                entries.add(
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.operatorsDeleteInvite,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return entries;
            },
          )
        : null;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      elevation: 1.5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.mail_outline, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(invitation.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitation.roleLabel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invitation.effectiveStatus == 'accepted' &&
                      invitation.acceptedAt != null
                  ? l10n.operatorsAcceptedOn(
                      dateFormat.format(invitation.acceptedAt!),
                    )
                  : l10n.operatorsExpires(
                      dateFormat.format(invitation.expiresAt),
                    ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: invitation.effectiveStatus == 'expired'
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: trailing,
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, String status) {
    return switch (status) {
      'pending' => scheme.primary,
      'accepted' => Colors.green.shade700,
      'declined' => Colors.orange.shade700,
      'revoked' => scheme.onSurfaceVariant,
      'expired' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
  }

  String _statusLabel(dynamic l10n, String status) {
    return switch (status) {
      'pending' => l10n.operatorsInviteStatusPending,
      'accepted' => l10n.operatorsInviteStatusAccepted,
      'declined' => l10n.operatorsInviteStatusDeclined,
      'revoked' => l10n.operatorsInviteStatusRevoked,
      'expired' => l10n.operatorsInviteStatusExpired,
      _ => status,
    };
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showAppConfirmDialog(
      context,
      title: Text(l10n.operatorsDeleteInvite),
      content: Text(l10n.operatorsDeleteInviteConfirm(invitation.email)),
      confirmLabel: l10n.actionDelete,
      danger: true,
      onConfirm: () {
        ref
            .read(businessUsersProvider(businessId).notifier)
            .deleteInvitation(invitation.id);
      },
    );
  }

  void _confirmRevoke(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showAppConfirmDialog(
      context,
      title: Text(l10n.operatorsRevokeInvite),
      content: Text(l10n.operatorsRevokeInviteConfirm(invitation.email)),
      confirmLabel: l10n.operatorsRevokeInvite,
      danger: true,
      onConfirm: () {
        ref
            .read(businessUsersProvider(businessId).notifier)
            .deleteInvitation(invitation.id);
      },
    );
  }

  Future<void> _resendInvitation(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await ref
        .read(businessUsersProvider(businessId).notifier)
        .resendInvitation(invitation);
    if (!context.mounted) return;

    final message = ok
        ? l10n.operatorsInviteSuccess(invitation.email)
        : (ref.read(businessUsersProvider(businessId)).error ??
              l10n.operatorsInviteError);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Tile per visualizzare un operatore attivo.
class _UserTile extends ConsumerWidget {
  const _UserTile({
    super.key,
    required this.user,
    required this.businessId,
    this.enableActions = true,
  });

  final BusinessUser user;
  final int businessId;
  final bool enableActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final locations = ref.watch(locationsProvider);
    final canEditRole = enableActions && !user.isCurrentUser && user.role != 'owner';
    final showLocationsInfo = locations.length > 1;
    final enabledLocationsInfo = _buildEnabledLocationsInfo(l10n, locations);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      elevation: 1.5,
      child: ListTile(
        onTap: canEditRole
            ? () => _showEditRoleDialog(context, ref, locations)
            : null,
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Text(
            _getInitials(user),
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(child: Text(user.fullName)),
            if (user.isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.operatorsYou,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getRoleLabel(user.role, l10n),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (showLocationsInfo) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.teamStaffLocationsLabel}: $enabledLocationsInfo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: !canEditRole
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditRoleDialog(context, ref, locations);
                  } else if (value == 'remove') {
                    _confirmRemove(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.operatorsEditRole),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.operatorsRemove,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getInitials(BusinessUser user) {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    if (first.isEmpty && last.isEmpty) {
      return user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
    }
    return '$first$last'.toUpperCase();
  }

  String _getRoleLabel(String role, dynamic l10n) {
    return switch (role) {
      'owner' => l10n.operatorsRoleOwner,
      'admin' => l10n.operatorsRoleAdmin,
      'manager' => l10n.operatorsRoleManager,
      'staff' => l10n.operatorsRoleStaff,
      'viewer' => 'Viewer',
      _ => role,
    };
  }

  String _buildEnabledLocationsInfo(dynamic l10n, List<Location> locations) {
    if (user.scopeType != 'locations' || user.locationIds.isEmpty) {
      return l10n.allLocations;
    }

    final selectedNames = locations
        .where((location) => user.locationIds.contains(location.id))
        .map((location) => location.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (selectedNames.isEmpty) {
      return l10n.allLocations;
    }

    return selectedNames.join(', ');
  }

  void _showEditRoleDialog(
    BuildContext context,
    WidgetRef ref,
    List<Location> locations,
  ) {
    final formFactor = ref.read(formFactorProvider);
    final currentLocationIds = user.locationIds.toSet();

    if (formFactor == AppFormFactor.mobile ||
        formFactor == AppFormFactor.tablet) {
      AppBottomSheet.show(
        context: context,
        heightFactor: null,
        builder: (ctx) => RoleSelectionSheet(
          currentRole: user.role,
          currentScopeType: user.scopeType,
          currentLocationIds: user.locationIds,
          locations: locations,
          userName: user.fullName,
          userEmail: user.email,
          onSave:
              ({
                required String role,
                required String scopeType,
                required List<int> locationIds,
              }) async {
                Navigator.of(ctx).pop();
                final selectedLocationIds = scopeType == 'locations'
                    ? locationIds.toSet()
                    : <int>{};
                final hasChanges =
                    role != user.role ||
                    scopeType != user.scopeType ||
                    !setEquals(selectedLocationIds, currentLocationIds);
                if (hasChanges) {
                  final ok = await ref
                      .read(businessUsersProvider(businessId).notifier)
                      .updateUser(
                        userId: user.userId,
                        role: role,
                        scopeType: scopeType,
                        locationIds: scopeType == 'locations'
                            ? selectedLocationIds.toList()
                            : <int>[],
                      );
                  if (!context.mounted || ok) return;
                  final isIt =
                      Localizations.localeOf(context).languageCode == 'it';
                  final message =
                      ref.read(businessUsersProvider(businessId)).error ??
                      (isIt
                          ? 'Impossibile aggiornare i permessi dell\'operatore.'
                          : 'Unable to update operator permissions.');
                  FeedbackDialog.showError(
                    context,
                    title: context.l10n.errorTitle,
                    message: message,
                  );
                }
              },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => RoleSelectionDialog(
          currentRole: user.role,
          currentScopeType: user.scopeType,
          currentLocationIds: user.locationIds,
          locations: locations,
          userName: user.fullName,
          userEmail: user.email,
          onSave:
              ({
                required String role,
                required String scopeType,
                required List<int> locationIds,
              }) async {
                Navigator.of(ctx).pop();
                final selectedLocationIds = scopeType == 'locations'
                    ? locationIds.toSet()
                    : <int>{};
                final hasChanges =
                    role != user.role ||
                    scopeType != user.scopeType ||
                    !setEquals(selectedLocationIds, currentLocationIds);
                if (hasChanges) {
                  final ok = await ref
                      .read(businessUsersProvider(businessId).notifier)
                      .updateUser(
                        userId: user.userId,
                        role: role,
                        scopeType: scopeType,
                        locationIds: scopeType == 'locations'
                            ? selectedLocationIds.toList()
                            : <int>[],
                      );
                  if (!context.mounted || ok) return;
                  final isIt =
                      Localizations.localeOf(context).languageCode == 'it';
                  final message =
                      ref.read(businessUsersProvider(businessId)).error ??
                      (isIt
                          ? 'Impossibile aggiornare i permessi dell\'operatore.'
                          : 'Unable to update operator permissions.');
                  FeedbackDialog.showError(
                    context,
                    title: context.l10n.errorTitle,
                    message: message,
                  );
                }
              },
        ),
      );
    }
  }

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showAppConfirmDialog(
      context,
      title: Text(l10n.operatorsRemove),
      content: Text(l10n.operatorsRemoveConfirm(user.fullName)),
      confirmLabel: l10n.actionConfirm,
      danger: true,
      onConfirm: () {
        ref
            .read(businessUsersProvider(businessId).notifier)
            .removeUser(user.userId);
      },
    );
  }
}
