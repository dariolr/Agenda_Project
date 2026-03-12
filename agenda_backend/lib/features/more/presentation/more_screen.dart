import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/form_factor_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';

/// Schermata "Altro" con cards per le sezioni secondarie
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static String _withFromAltro(String path) => '$path?from_altro=1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    final canManageOperators = ref.watch(canManageOperatorsProvider);
    final canManageSettings = ref.watch(canManageBusinessSettingsProvider);
    final canManageBookings = ref.watch(currentUserCanManageBookingsProvider);
    final canViewServices = ref.watch(currentUserCanViewServicesProvider);
    final canViewStaff = ref.watch(currentUserCanViewStaffProvider);
    final canViewReports = ref.watch(currentUserCanViewReportsProvider);
    final canAccessClassEvents = canViewServices && kDebugMode;
    final isSuperadmin = ref.watch(
      authProvider.select((s) => s.user?.isSuperadmin ?? false),
    );
    final businessOwner = isSuperadmin ? ref.watch(businessOwnerProvider) : null;
    final showProfile = !isSuperadmin || businessOwner != null;

    final configurationItems = [
      if (canManageSettings)
        _MoreItem(
          icon: Icons.location_on_outlined,
          title: l10n.teamLocationsLabel,
          description: l10n.moreLocationsDescription,
          color: const Color(0xFF009688),
          onTap: () => context.go(_withFromAltro('/altro/sedi')),
        ),
      // Team - visibile solo a chi può gestire impostazioni
      if (canViewStaff)
        _MoreItem(
          icon: Icons.badge_outlined,
          title: l10n.navStaff,
          description: l10n.moreTeamDescription,
          color: const Color(0xFF2196F3), // Blue
          onTap: () => context.go(_withFromAltro('/staff')),
        ),
      // Servizi - visibile solo a chi può gestire impostazioni
      if (canViewServices)
        _MoreItem(
          icon: Icons.category_outlined,
          title: l10n.navServices,
          description: l10n.moreServicesDescription,
          color: const Color(0xFF4CAF50), // Green
          onTap: () => context.go(_withFromAltro('/servizi')),
        ),
      if (canAccessClassEvents)
        _MoreItem(
          icon: Icons.groups_outlined,
          title: l10n.classEventsTitle,
          description: l10n.moreClassEventsDescription,
          color: const Color(0xFF795548),
          onTap: () => context.go(_withFromAltro('/altro/classi')),
        ),
      if (canManageSettings)
        _MoreItem(
          icon: Icons.inventory_2_outlined,
          title: l10n.resourcesTitle,
          description: l10n.resourcesEmptyHint,
          color: const Color(0xFF8BC34A),
          onTap: () => context.go(_withFromAltro('/altro/risorse')),
        ),
      // Permessi - visibile solo a chi può gestire operatori
      if (canManageOperators)
        _MoreItem(
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.permissionsTitle,
          description: l10n.permissionsDescription,
          color: const Color(0xFF00BCD4), // Cyan
          onTap: () => context.go(_withFromAltro('/permessi')),
        ),
      if (canManageSettings)
        _MoreItem(
          icon: Icons.event_busy,
          title: l10n.closuresTitle,
          description: l10n.closuresEmptyHint,
          color: const Color(0xFFE91E63), // Pink
          onTap: () => context.go(_withFromAltro('/chiusure')),
        ),
    ];

    final analyticsItems = [
      if (canViewReports)
        _MoreItem(
          icon: Icons.bar_chart,
          title: l10n.reportsTitle,
          description: l10n.moreReportsDescription,
          color: const Color(0xFFFF9800), // Orange
          onTap: () => context.go(_withFromAltro('/report')),
        ),
      if (canManageBookings)
        _MoreItem(
          icon: Icons.list_alt,
          title: l10n.bookingsListTitle,
          description: l10n.moreBookingsDescription,
          color: const Color(0xFF9C27B0), // Purple
          onTap: () => context.go(_withFromAltro('/prenotazioni')),
        ),
      if (canManageBookings)
        _MoreItem(
          icon: Icons.notifications_outlined,
          title: l10n.bookingNotificationsTitle,
          description: l10n.moreBookingNotificationsDescription,
          color: const Color(0xFF3F51B5), // Indigo
          onTap: () => context.go(_withFromAltro('/notifiche-prenotazioni')),
        ),
    ];

    final profileItems = [
      if (showProfile)
        _MoreItem(
          icon: Icons.account_circle_outlined,
          title: l10n.profileTitle,
          description: l10n.moreProfileDescription,
          color: const Color(0xFF607D8B), // Blue Grey
          onTap: () => context.go(_withFromAltro('/profilo')),
        ),
    ];
    final sections = [
      if (configurationItems.isNotEmpty)
        _MoreSection(
          title: l10n.moreSectionBusinessConfig,
          items: configurationItems,
        ),
      if (analyticsItems.isNotEmpty)
        _MoreSection(title: l10n.moreSectionDataAnalysis, items: analyticsItems),
      if (profileItems.isNotEmpty)
        _MoreSection(title: l10n.moreSectionProfileManage, items: profileItems),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  isDesktop ? 16 : 12,
                  isDesktop ? 32 : 20,
                  isDesktop ? 16 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navMore,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.moreSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (int i = 0; i < sections.length; i++) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 20,
                    sections[i].title == null ? 12 : 8,
                    isDesktop ? 32 : 20,
                    sections[i].title == null ? 4 : 10,
                  ),
                  child: sections[i].title == null
                      ? const SizedBox.shrink()
                      : Text(
                          sections[i].title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 16,
                  0,
                  isDesktop ? 32 : 16,
                  0,
                ),
                sliver: isDesktop
                    ? _buildDesktopGrid(sections[i].items, context)
                    : _buildMobileList(sections[i].items),
              ),
              if (i < sections.length - 1)
                SliverToBoxAdapter(
                  child: SizedBox(height: isDesktop ? 32 : 24),
                ),
            ],
            // Padding in fondo
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// Griglia per desktop (4 colonne)
  Widget _buildDesktopGrid(List<_MoreItem> items, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);
    const mainAxisExtent = 180.0;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: mainAxisExtent,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _MoreCardDesktop(item: items[index]),
        childCount: items.length,
      ),
    );
  }

  /// Lista per mobile (cards orizzontali che si adattano al contenuto)
  Widget _buildMobileList(List<_MoreItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
          child: _MoreCardMobile(item: items[index]),
        ),
        childCount: items.length,
      ),
    );
  }
}

class _MoreSection {
  final String? title;
  final List<_MoreItem> items;

  const _MoreSection({this.title, required this.items});
}

class _MoreItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });
}

/// Card per desktop (layout verticale compatto)
class _MoreCardDesktop extends StatefulWidget {
  final _MoreItem item;

  const _MoreCardDesktop({required this.item});

  @override
  State<_MoreCardDesktop> createState() => _MoreCardDesktopState();
}

class _MoreCardDesktopState extends State<_MoreCardDesktop> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          shadowColor: item.color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered
                  ? item.color.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.1),
              width: _isHovered ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icona
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, size: 26, color: item.color),
                      ),
                      const Spacer(),
                      // Freccia di navigazione
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: _isHovered
                            ? item.color
                            : colorScheme.outline.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                      // Titolo
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Descrizione
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card per mobile (layout orizzontale che si adatta al contenuto)
class _MoreCardMobile extends StatelessWidget {
  final _MoreItem item;

  const _MoreCardMobile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shadowColor: item.color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona con sfondo colorato
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 24, color: item.color),
              ),
              const SizedBox(width: 16),
              // Testo (si espande e si adatta)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Descrizione completa (senza limite di righe)
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Freccia
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: colorScheme.outline.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
