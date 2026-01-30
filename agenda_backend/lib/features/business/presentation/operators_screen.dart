import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../agenda/providers/location_providers.dart';
import '../providers/business_users_provider.dart';
import 'dialogs/invite_operator_dialog.dart';
import 'dialogs/role_selection_dialog.dart';

/// Schermata per la gestione degli operatori di un business.
class OperatorsScreen extends ConsumerWidget {
  const OperatorsScreen({super.key, required this.businessId});

  final int businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessUsersProvider(businessId));
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.operatorsTitle),
      ),
      body: _buildBody(context, ref, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BusinessUsersState state,
    dynamic l10n,
  ) {
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
                  .read(businessUsersProvider(businessId).notifier)
                  .refresh(),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(businessUsersProvider(businessId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Header con sottotitolo e pulsante aggiungi
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.operatorsSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showInviteDialog(context, ref),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: Text(l10n.operatorsInviteTitle),
                  ),
                ],
              ),
            ),
          ),

          // Sezione inviti pendenti
          if (state.invitations.isNotEmpty) ...[
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
                        state.invitations.length,
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
                  invitation: state.invitations[index],
                  businessId: businessId,
                ),
                childCount: state.invitations.length,
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
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _UserTile(user: state.users[index], businessId: businessId),
                childCount: state.users.length,
              ),
            ),

          // Padding finale
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final formFactor = ref.read(formFactorProvider);

    if (formFactor == AppFormFactor.mobile ||
        formFactor == AppFormFactor.tablet) {
      AppBottomSheet.show(
        context: context,
        builder: (ctx) => InviteOperatorSheet(businessId: businessId),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => InviteOperatorDialog(businessId: businessId),
      );
    }
  }
}

/// Tile per visualizzare un invito pendente.
class _InvitationTile extends ConsumerWidget {
  const _InvitationTile({required this.invitation, required this.businessId});

  final BusinessInvitation invitation;
  final int businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMd();

    return ListTile(
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
          Text(
            l10n.operatorsExpires(dateFormat.format(invitation.expiresAt)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: invitation.isExpired
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'revoke') {
            _confirmRevoke(context, ref);
          } else if (value == 'copy' && invitation.token != null) {
            _copyInviteLink(context, invitation.token!);
          }
        },
        itemBuilder: (context) => [
          if (invitation.token != null)
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  const Icon(Icons.copy, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.operatorsInviteCopied),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'revoke',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 20, color: colorScheme.error),
                const SizedBox(width: 12),
                Text(
                  l10n.operatorsRevokeInvite,
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showAppConfirmDialog(
      context,
      title: Text(l10n.operatorsRevokeInvite),
      content: Text(l10n.operatorsRevokeInviteConfirm(invitation.email)),
      confirmLabel: l10n.actionConfirm,
      danger: true,
      onConfirm: () {
        ref
            .read(businessUsersProvider(businessId).notifier)
            .revokeInvitation(invitation.id);
      },
    );
  }

  void _copyInviteLink(BuildContext context, String token) {
    final url = 'https://agenda.example.com/invite/$token';
    Clipboard.setData(ClipboardData(text: url));
    FeedbackDialog.showSuccess(
      context,
      title: context.l10n.operatorsInviteCopied,
      message: context.l10n.operatorsInviteCopied,
    );
  }
}

/// Tile per visualizzare un operatore attivo.
class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.businessId});

  final BusinessUser user;
  final int businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final locations = ref.watch(locationsProvider);

    return ListTile(
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
      subtitle: Text(
        _getRoleLabel(user.role, l10n),
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: user.isCurrentUser || user.role == 'owner'
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
      _ => role,
    };
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
          onSave: ({
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
              await ref
                  .read(businessUsersProvider(businessId).notifier)
                  .updateUser(
                    userId: user.userId,
                    role: role,
                    scopeType: scopeType,
                    locationIds:
                        scopeType == 'locations'
                            ? selectedLocationIds.toList()
                            : <int>[],
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
          onSave: ({
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
              await ref
                  .read(businessUsersProvider(businessId).notifier)
                  .updateUser(
                    userId: user.userId,
                    role: role,
                    scopeType: scopeType,
                    locationIds:
                        scopeType == 'locations'
                            ? selectedLocationIds.toList()
                            : <int>[],
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
