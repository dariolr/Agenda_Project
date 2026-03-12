import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/form_factor_provider.dart';
import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/location.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../agenda/providers/location_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../staff/presentation/dialogs/location_dialog.dart';
import '../../staff/presentation/screens/resources_screen.dart';
import '../../staff/presentation/widgets/location_item.dart';
import '../../staff/providers/staff_providers.dart';
import '../../staff/providers/staff_sorted_providers.dart';

class MoreLocationsScreen extends ConsumerWidget {
  const MoreLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(sortedLocationsProvider);
    final staffAsync = ref.watch(allStaffProvider);
    final formFactor = ref.watch(formFactorProvider);
    final isWide = formFactor != AppFormFactor.mobile;
    final topPadding = formFactor == AppFormFactor.desktop ? 0.0 : 16.0;
    final canManageSettings = ref.watch(canManageBusinessSettingsProvider);
    final canViewStaff = ref.watch(currentUserCanViewStaffProvider);

    if (staffAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (locations.isEmpty) {
      return Center(
        child: Text(
          context.l10n.agendaNoLocations,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final staffInLocation = ref.watch(staffByLocationProvider(location.id));
        return LocationItem(
          location: location,
          staff: const [],
          isWide: isWide,
          showDefaultActions: false,
          showBody: false,
          readOnly: !canManageSettings,
          onTap: canManageSettings
              ? () => showLocationDialog(context, ref, initial: location)
              : null,
          headerTrailing: _LocationActions(
            location: location,
            hasStaff: staffInLocation.isNotEmpty,
            canManageSettings: canManageSettings,
            canViewStaff: canViewStaff,
          ),
          onAddStaff: () {},
          onEditLocation: () {},
          onDeleteLocation: () {},
          onEditStaff: (_) {},
          onDuplicateStaff: (_) {},
          onDeleteStaff: (_) {},
        );
      },
    );
  }
}

class MoreResourcesScreen extends ConsumerWidget {
  const MoreResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(sortedLocationsProvider);
    if (locations.isEmpty) {
      return Center(
        child: Text(
          context.l10n.agendaNoLocations,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final currentLocation = ref.watch(currentLocationProvider);
    Location targetLocation = locations.first;
    for (final location in locations) {
      if (location.id == currentLocation.id) {
        targetLocation = location;
        break;
      }
    }

    return ResourcesScreen(
      location: targetLocation,
      showAppBar: false,
      enableLocationSelectionInForm: true,
    );
  }
}

class _LocationActions extends ConsumerWidget {
  const _LocationActions({
    required this.location,
    required this.hasStaff,
    required this.canManageSettings,
    required this.canViewStaff,
  });

  final Location location;
  final bool hasStaff;
  final bool canManageSettings;
  final bool canViewStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canViewStaff)
          IconButton(
            tooltip: context.l10n.navStaff,
            icon: const Icon(Icons.badge_outlined),
            onPressed: () {
              ref.read(staffSectionLocationIdProvider.notifier).set(location.id);
              context.go('/staff?from_altro=1');
            },
          ),
        IconButton(
          tooltip: context.l10n.resourcesTitle,
          icon: const Icon(Icons.inventory_2_outlined),
          onPressed: () {
            ref.read(currentLocationIdProvider.notifier).set(location.id);
            context.go('/altro/risorse?from_altro=1');
          },
        ),
        if (canManageSettings)
          IconButton(
            tooltip: context.l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showLocationDialog(context, ref, initial: location),
          ),
        if (canManageSettings && !hasStaff)
          IconButton(
            tooltip: context.l10n.actionDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _handleDelete(context, ref),
          ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    if (hasStaff) {
      await showAppInfoDialog(
        context,
        title: Text(context.l10n.teamDeleteLocationBlockedTitle),
        content: Text(context.l10n.teamDeleteLocationBlockedMessage),
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: Text(context.l10n.teamDeleteLocationTitle),
      content: Text(context.l10n.teamDeleteLocationMessage),
      confirmLabel: context.l10n.actionConfirm,
      cancelLabel: context.l10n.actionCancel,
    );
    if (confirmed != true || !context.mounted) return;

    final currentId = ref.read(currentLocationIdProvider);
    await ref
        .read(locationsProvider.notifier)
        .deleteLocation(location.id, currentLocationId: currentId);
  }
}
