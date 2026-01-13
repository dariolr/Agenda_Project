import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/route_slug_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/booking/providers/business_provider.dart';
import '../l10n/l10_extension.dart';

/// AppBar professionale per il sistema di prenotazione.
///
/// Caratteristiche:
/// - Mostra nome business centrato
/// - Design minimal e professionale
/// - Menu utente integrato per utenti autenticati
/// - Supporta back button quando necessario
class BookingAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BookingAppBar({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
    this.showUserMenu = true,
    this.bottom,
  });

  /// Se mostrare il pulsante back
  final bool showBackButton;

  /// Callback per il back button (se null, usa Navigator.pop)
  final VoidCallback? onBackPressed;

  /// Se mostrare il menu utente per utenti autenticati
  final bool showUserMenu;

  /// Widget opzionale da mostrare sotto l'AppBar (es. TabBar)
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(currentBusinessProvider);
    final isAuthenticated = ref.watch(
      authProvider.select((state) => state.isAuthenticated),
    );
    final slug = ref.watch(routeSlugProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Nome business o placeholder
    final businessName = businessAsync.value?.name ?? '';

    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      // Leading: back button o niente
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: colorScheme.onSurface,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      // Title: nome business con stile
      title: businessName.isNotEmpty
          ? Text(
              businessName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: colorScheme.onSurface,
              ),
            )
          : null,
      // Actions: menu utente
      actions: [
        if (showUserMenu && isAuthenticated && slug != null)
          _UserMenuButton(slug: slug),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }
}

/// Menu utente con avatar iniziali
class _UserMenuButton extends ConsumerWidget {
  const _UserMenuButton({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authProvider.select((s) => s.user));

    // Iniziali per avatar
    final initials = _getInitials(user?.firstName, user?.lastName);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      tooltip: l10n.profileTitle,
      onSelected: (value) async {
        switch (value) {
          case 'bookings':
            context.push('/$slug/my-bookings');
          case 'profile':
            context.push('/$slug/profile');
          case 'change-password':
            context.push('/$slug/change-password');
          case 'logout':
            final businessId = ref.read(currentBusinessIdProvider);
            if (businessId != null) {
              await ref
                  .read(authProvider.notifier)
                  .logout(businessId: businessId);
            }
        }
      },
      itemBuilder: (context) => [
        // Header con nome utente
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user?.email != null)
                Text(
                  user!.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'bookings',
          child: _MenuItemContent(
            icon: Icons.calendar_today_outlined,
            label: l10n.myBookings,
          ),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          child: _MenuItemContent(
            icon: Icons.person_outline,
            label: l10n.profileTitle,
          ),
        ),
        PopupMenuItem<String>(
          value: 'change-password',
          child: _MenuItemContent(
            icon: Icons.lock_outline,
            label: l10n.authChangePassword,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: _MenuItemContent(
            icon: Icons.logout,
            label: l10n.actionLogout,
            isDestructive: true,
          ),
        ),
      ],
      padding: EdgeInsets.zero,
      splashRadius: 24,
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    final f = firstName?.isNotEmpty == true ? firstName![0].toUpperCase() : '';
    final l = lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }
}

/// Contenuto riga menu
class _MenuItemContent extends StatelessWidget {
  const _MenuItemContent({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? Colors.red : colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

/// AppBar semplice per le schermate secondarie (login, registrazione, ecc.)
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: colorScheme.onSurface,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
      ),
      actions: actions,
    );
  }
}
