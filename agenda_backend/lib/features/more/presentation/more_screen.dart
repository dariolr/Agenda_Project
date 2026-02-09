import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/form_factor_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../auth/providers/current_business_user_provider.dart';

/// Schermata "Altro" con cards per le sezioni secondarie
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    final canManageOperators = ref.watch(canManageOperatorsProvider);
    final canManageSettings = ref.watch(canManageBusinessSettingsProvider);
    final canViewServices = ref.watch(currentUserCanViewServicesProvider);
    final canViewStaff = ref.watch(currentUserCanViewStaffProvider);
    final canViewReports = ref.watch(currentUserCanViewReportsProvider);

    final items = [
      // Servizi - visibile solo a chi può gestire impostazioni
      if (canViewServices)
        _MoreItem(
          icon: Icons.category_outlined,
          title: l10n.navServices,
          description: l10n.moreServicesDescription,
          color: const Color(0xFF4CAF50), // Green
          onTap: () => context.go('/servizi'),
        ),
      // Team - visibile solo a chi può gestire impostazioni
      if (canViewStaff)
        _MoreItem(
          icon: Icons.badge_outlined,
          title: l10n.navStaff,
          description: l10n.moreTeamDescription,
          color: const Color(0xFF2196F3), // Blue
          onTap: () => context.go('/staff'),
        ),
      if (canViewStaff)
        _MoreItem(
          icon: Icons.schedule_outlined,
          title: l10n.staffHubAvailabilityTitle,
          description: l10n.moreTeamDescription,
          color: const Color(0xFF3F51B5), // Indigo
          onTap: () => context.pushNamed('staff-availability'),
        ),
      // Permessi - visibile solo a chi può gestire operatori
      if (canManageOperators)
        _MoreItem(
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.permissionsTitle,
          description: l10n.permissionsDescription,
          color: const Color(0xFF00BCD4), // Cyan
          onTap: () => context.go('/permessi'),
        ),
      if (canViewReports)
        _MoreItem(
          icon: Icons.bar_chart,
          title: l10n.reportsTitle,
          description: l10n.moreReportsDescription,
          color: const Color(0xFFFF9800), // Orange
          onTap: () => context.go('/report'),
        ),
      _MoreItem(
        icon: Icons.list_alt,
        title: l10n.bookingsListTitle,
        description: l10n.moreBookingsDescription,
        color: const Color(0xFF9C27B0), // Purple
        onTap: () => context.go('/prenotazioni'),
      ),
      // Chiusure - visibile solo a chi può gestire impostazioni
      if (canManageSettings)
        _MoreItem(
          icon: Icons.event_busy,
          title: l10n.closuresTitle,
          description: l10n.closuresEmptyHint,
          color: const Color(0xFFE91E63), // Pink
          onTap: () => context.go('/chiusure'),
        ),
      _MoreItem(
        icon: Icons.account_circle_outlined,
        title: l10n.profileTitle,
        description: l10n.moreProfileDescription,
        color: const Color(0xFF607D8B), // Blue Grey
        onTap: () => context.go('/profilo'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  isDesktop ? 24 : 16,
                  isDesktop ? 32 : 20,
                  isDesktop ? 24 : 20,
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
            // Lista di cards (layout adattivo)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
              sliver: isDesktop
                  ? _buildDesktopGrid(items, context)
                  : _buildMobileList(items),
            ),
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

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
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

/// Card per desktop (layout verticale con aspect ratio fisso)
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icona con sfondo colorato
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
                  // Titolo
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Descrizione (troncata se troppo lunga)
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Freccia di navigazione
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: _isHovered
                          ? item.color
                          : colorScheme.outline.withOpacity(0.5),
                    ),
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
