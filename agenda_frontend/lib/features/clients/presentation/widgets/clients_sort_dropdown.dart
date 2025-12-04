import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/widgets/adaptive_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../domain/client_sort_option.dart';

/// Dropdown per selezionare il criterio di ordinamento della lista clienti.
class ClientsSortDropdown extends ConsumerStatefulWidget {
  const ClientsSortDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ClientSortOption value;
  final ValueChanged<ClientSortOption> onChanged;

  @override
  ConsumerState<ClientsSortDropdown> createState() =>
      _ClientsSortDropdownState();
}

class _ClientsSortDropdownState extends ConsumerState<ClientsSortDropdown> {
  bool _isHovered = false;

  String _getLabel(ClientSortOption option) {
    final l10n = context.l10n;
    switch (option) {
      case ClientSortOption.nameAsc:
        return l10n.sortByNameAsc;
      case ClientSortOption.nameDesc:
        return l10n.sortByNameDesc;
      case ClientSortOption.lastNameAsc:
        return l10n.sortByLastNameAsc;
      case ClientSortOption.lastNameDesc:
        return l10n.sortByLastNameDesc;
      case ClientSortOption.lastVisitDesc:
        return l10n.sortByLastVisitDesc;
      case ClientSortOption.lastVisitAsc:
        return l10n.sortByLastVisitAsc;
      case ClientSortOption.createdAtDesc:
        return l10n.sortByCreatedAtDesc;
      case ClientSortOption.createdAtAsc:
        return l10n.sortByCreatedAtAsc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final interactions = theme.extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final backgroundColor = _isHovered
        ? Color.alphaBlend(hoverFill, colorScheme.surface)
        : colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: AdaptiveDropdown<ClientSortOption>(
        items: [
          AdaptiveDropdownItem(
            value: ClientSortOption.nameAsc,
            child: Text(l10n.sortByNameAsc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.nameDesc,
            child: Text(l10n.sortByNameDesc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.lastNameAsc,
            child: Text(l10n.sortByLastNameAsc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.lastNameDesc,
            child: Text(l10n.sortByLastNameDesc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.lastVisitDesc,
            child: Text(l10n.sortByLastVisitDesc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.lastVisitAsc,
            child: Text(l10n.sortByLastVisitAsc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.createdAtDesc,
            child: Text(l10n.sortByCreatedAtDesc),
          ),
          AdaptiveDropdownItem(
            value: ClientSortOption.createdAtAsc,
            child: Text(l10n.sortByCreatedAtAsc),
          ),
        ],
        selectedValue: widget.value,
        onSelected: widget.onChanged,
        modalTitle: l10n.sortByTitle,
        useRootNavigator: true,
        onOpened: () => setState(() => _isHovered = true),
        onClosed: () => setState(() => _isHovered = false),
        popupWidth: 220,
        child: MouseRegion(
          onEnter: (_) {
            if (!_isHovered) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (_isHovered) setState(() => _isHovered = false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getLabel(widget.value),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
