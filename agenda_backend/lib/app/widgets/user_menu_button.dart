import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10_extension.dart';
import '../../core/models/user.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/business/presentation/business_list_screen.dart';

/// Avatar utente riutilizzabile.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 16});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Widget per mostrare il menu utente nell'AppBar.
/// Mostra avatar con iniziali e menu con logout.
class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(user: user, radius: 16),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (context) =>
          buildMenuItems(context, theme, colorScheme, user),
      onSelected: (value) {
        if (value == 'logout') {
          handleLogout(context, ref);
        } else if (value == 'profile') {
          context.push('/profilo');
        } else if (value == 'change_password') {
          context.push('/change-password');
        } else if (value == 'switch_business') {
          // Reset selected business e torna alla lista
          ref.read(superadminSelectedBusinessProvider.notifier).clear();
          context.go('/businesses');
        }
      },
    );
  }

  static List<PopupMenuEntry<String>> buildMenuItems(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    User user,
  ) {
    return [
      PopupMenuItem<String>(
        enabled: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.fullName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (user.isSuperadmin) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Superadmin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      const PopupMenuDivider(),
      // Cambia password
      PopupMenuItem<String>(
        value: 'change_password',
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Cambia password'),
          ],
        ),
      ),
      // Cambia Business per superadmin
      if (user.isSuperadmin)
        PopupMenuItem<String>(
          value: 'switch_business',
          child: Row(
            children: [
              Icon(Icons.business, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text('Cambia Business'),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: colorScheme.error),
            const SizedBox(width: 12),
            Text(
              context.l10n.authLogout,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
        ),
      ),
    ];
  }

  static void handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.authLogout),
        content: const Text('Vuoi uscire dal gestionale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text(context.l10n.authLogout),
          ),
        ],
      ),
    );
  }
}
