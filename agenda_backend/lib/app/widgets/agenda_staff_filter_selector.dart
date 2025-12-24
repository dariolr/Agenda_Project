import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/theme/extensions.dart';
import 'package:agenda_backend/app/widgets/agenda_control_components.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/widgets/desktop_popup_container.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selector per filtrare lo staff visualizzato nell'agenda.
/// [isCompact] = true: solo icona (mobile/tablet)
/// [isCompact] = false: pill con icona + label + freccia (desktop)
class AgendaStaffFilterSelector extends ConsumerStatefulWidget {
  const AgendaStaffFilterSelector({super.key, this.isCompact = true});

  final bool isCompact;

  @override
  ConsumerState<AgendaStaffFilterSelector> createState() =>
      _AgendaStaffFilterSelectorState();
}

class _AgendaStaffFilterSelectorState
    extends ConsumerState<AgendaStaffFilterSelector> {
  bool _isHovered = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen) {
      _isOpen = false;
      setState(() => _isHovered = false);
    }
  }

  void _handleTap() {
    final formFactor = ref.read(formFactorProvider);

    if (formFactor == AppFormFactor.desktop) {
      _showDesktopPopup();
    } else {
      _showMobileSheet(context);
    }
  }

  void _showDesktopPopup() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    setState(() => _isHovered = true);
    _isOpen = true;

    final renderBox = context.findRenderObject() as RenderBox;
    final triggerSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => DesktopPopupContainer(
        link: _layerLink,
        triggerWidth: triggerSize.width,
        triggerHeight: triggerSize.height,
        popupWidth: 280,
        maxHeight: 400,
        onDismiss: _removeOverlay,
        child: _StaffFilterPopupContent(onDismiss: _removeOverlay),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _showMobileSheet(BuildContext context) async {
    setState(() => _isHovered = true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const _StaffFilterSheet(),
    );
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formFactor = ref.watch(formFactorProvider);
    if (widget.isCompact) {
      return IconButton(
        tooltip: l10n.staffFilterTooltip,
        icon: const Icon(Icons.people_outline),
        iconSize: formFactor == AppFormFactor.mobile ? 22 : 33,
        onPressed: () => _showMobileSheet(context),
      );
    }

    // Desktop mode: pill style like AgendaLocationSelector
    final colorScheme = Theme.of(context).colorScheme;
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final backgroundColor = _isHovered
        ? Color.alphaBlend(hoverFill, colorScheme.surface)
        : colorScheme.surface;

    final mode = ref.watch(staffFilterModeProvider);
    final label = _getModeLabel(l10n, mode);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovered && !_isOpen) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered && !_isOpen) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTap: _handleTap,
          child: Semantics(
            button: true,
            label: l10n.staffFilterTooltip,
            child: ClipRRect(
              borderRadius: kAgendaPillRadius,
              child: Container(
                height: kAgendaControlHeight,
                decoration: BoxDecoration(
                  borderRadius: kAgendaPillRadius,
                  border: Border.all(color: Colors.grey.withOpacity(0.35)),
                  color: backgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kAgendaControlHorizontalPadding,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getModeLabel(dynamic l10n, StaffFilterMode mode) {
    switch (mode) {
      case StaffFilterMode.allTeam:
        return l10n.staffFilterAllTeam;
      case StaffFilterMode.onDutyTeam:
        return l10n.staffFilterOnDuty;
      case StaffFilterMode.custom:
        final selectedIds = ref.read(selectedStaffIdsProvider);
        final count = selectedIds.length;
        if (count == 0) return l10n.staffFilterAllTeam;
        return '$count';
    }
  }
}

/// Content widget for the staff filter desktop popup.
class _StaffFilterPopupContent extends ConsumerWidget {
  const _StaffFilterPopupContent({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mode = ref.watch(staffFilterModeProvider);
    final allStaff = ref.watch(staffForCurrentLocationProvider);
    final selectedIds = ref.watch(selectedStaffIdsProvider);
    final onDutyIds = ref.watch(onDutyStaffIdsProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              l10n.staffFilterTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.35)),

          // Opzione: Tutto il team
          _DesktopFilterOptionTile(
            title: l10n.staffFilterAllTeam,
            isSelected: mode == StaffFilterMode.allTeam,
            onTap: () {
              ref
                  .read(staffFilterModeProvider.notifier)
                  .set(StaffFilterMode.allTeam);
              onDismiss();
            },
          ),

          // Opzione: Team di turno
          _DesktopFilterOptionTile(
            title: l10n.staffFilterOnDuty,
            isSelected: mode == StaffFilterMode.onDutyTeam,
            onTap: () {
              ref
                  .read(staffFilterModeProvider.notifier)
                  .set(StaffFilterMode.onDutyTeam);
              onDismiss();
            },
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.withOpacity(0.35)),

          // Header staff
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              l10n.staffFilterSelectMembers,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Lista staff con checkbox
          for (final staff in allStaff)
            _DesktopStaffMemberTile(
              staff: staff,
              isSelected: _isStaffSelected(
                mode,
                selectedIds,
                onDutyIds,
                staff.id,
              ),
              onChanged: (selected) {
                if (mode != StaffFilterMode.custom) {
                  final ids = allStaff.map((s) => s.id).toList();
                  ref.read(selectedStaffIdsProvider.notifier).setFromList(ids);
                  ref
                      .read(staffFilterModeProvider.notifier)
                      .set(StaffFilterMode.custom);
                }
                ref.read(selectedStaffIdsProvider.notifier).toggle(staff.id);
              },
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _isStaffSelected(
    StaffFilterMode mode,
    Set<int> selectedIds,
    Set<int> onDutyIds,
    int staffId,
  ) {
    switch (mode) {
      case StaffFilterMode.allTeam:
        return true;
      case StaffFilterMode.onDutyTeam:
        return onDutyIds.contains(staffId);
      case StaffFilterMode.custom:
        return selectedIds.isEmpty || selectedIds.contains(staffId);
    }
  }
}

class _DesktopFilterOptionTile extends StatefulWidget {
  const _DesktopFilterOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DesktopFilterOptionTile> createState() =>
      _DesktopFilterOptionTileState();
}

class _DesktopFilterOptionTileState extends State<_DesktopFilterOptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: widget.isSelected
              ? colorScheme.primary.withOpacity(0.08)
              : _isHovered
              ? colorScheme.primary.withOpacity(0.04)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: widget.isSelected ? colorScheme.primary : null,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopStaffMemberTile extends StatefulWidget {
  const _DesktopStaffMemberTile({
    required this.staff,
    required this.isSelected,
    required this.onChanged,
  });

  final Staff staff;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  State<_DesktopStaffMemberTile> createState() =>
      _DesktopStaffMemberTileState();
}

class _DesktopStaffMemberTileState extends State<_DesktopStaffMemberTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onChanged(!widget.isSelected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: _isHovered
              ? colorScheme.primary.withOpacity(0.04)
              : Colors.transparent,
          child: Row(
            children: [
              StaffCircleAvatar(
                height: 28,
                color: widget.staff.color,
                isHighlighted: widget.isSelected,
                initials: widget.staff.initials,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.staff.displayName)),
              Checkbox(
                value: widget.isSelected,
                onChanged: (value) => widget.onChanged(value ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile/tablet bottom sheet for staff filter.
class _StaffFilterSheet extends ConsumerWidget {
  const _StaffFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mode = ref.watch(staffFilterModeProvider);
    final allStaff = ref.watch(staffForCurrentLocationProvider);
    final selectedIds = ref.watch(selectedStaffIdsProvider);
    final onDutyIds = ref.watch(onDutyStaffIdsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.staffFilterTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.35)),

            // Opzione: Tutto il team
            _MobileFilterOptionTile(
              title: l10n.staffFilterAllTeam,
              isSelected: mode == StaffFilterMode.allTeam,
              onTap: () {
                ref
                    .read(staffFilterModeProvider.notifier)
                    .set(StaffFilterMode.allTeam);
                Navigator.of(context).pop();
              },
            ),

            // Opzione: Team di turno
            _MobileFilterOptionTile(
              title: l10n.staffFilterOnDuty,
              isSelected: mode == StaffFilterMode.onDutyTeam,
              onTap: () {
                ref
                    .read(staffFilterModeProvider.notifier)
                    .set(StaffFilterMode.onDutyTeam);
                Navigator.of(context).pop();
              },
            ),

            // Divider
            Divider(height: 1, color: Colors.grey.withOpacity(0.35)),

            // Header staff
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.staffFilterSelectMembers,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Lista staff con checkbox
            for (final staff in allStaff)
              _MobileStaffMemberTile(
                staff: staff,
                isSelected: _isStaffSelected(
                  mode,
                  selectedIds,
                  onDutyIds,
                  staff.id,
                ),
                onChanged: (selected) {
                  if (mode != StaffFilterMode.custom) {
                    final ids = allStaff.map((s) => s.id).toList();
                    ref
                        .read(selectedStaffIdsProvider.notifier)
                        .setFromList(ids);
                    ref
                        .read(staffFilterModeProvider.notifier)
                        .set(StaffFilterMode.custom);
                  }
                  ref.read(selectedStaffIdsProvider.notifier).toggle(staff.id);
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _isStaffSelected(
    StaffFilterMode mode,
    Set<int> selectedIds,
    Set<int> onDutyIds,
    int staffId,
  ) {
    switch (mode) {
      case StaffFilterMode.allTeam:
        return true;
      case StaffFilterMode.onDutyTeam:
        return onDutyIds.contains(staffId);
      case StaffFilterMode.custom:
        return selectedIds.isEmpty || selectedIds.contains(staffId);
    }
  }
}

class _MobileFilterOptionTile extends StatelessWidget {
  const _MobileFilterOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(title),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      onTap: onTap,
    );
  }
}

class _MobileStaffMemberTile extends StatelessWidget {
  const _MobileStaffMemberTile({
    required this.staff,
    required this.isSelected,
    required this.onChanged,
  });

  final Staff staff;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: StaffCircleAvatar(
        height: 32,
        color: staff.color,
        isHighlighted: isSelected,
        initials: staff.initials,
      ),
      title: Text(staff.displayName),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
      ),
      onTap: () => onChanged(!isSelected),
    );
  }
}
