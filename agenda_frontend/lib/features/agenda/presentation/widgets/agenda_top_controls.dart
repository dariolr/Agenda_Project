import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/models/location.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';

class AgendaTopControls extends ConsumerWidget {
  const AgendaTopControls({super.key});

  static const double _controlHeight = 40;
  static const double _horizontalPadding = 20;
  static const double _minDateLabelWidth = 120;
  static const BorderRadius _pillRadius = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final agendaDate = ref.watch(agendaDateProvider);
    final locations = ref.watch(locationsProvider);
    if (locations.isEmpty) {
      return Text(l10n.agendaNoLocations);
    }
    final currentLocation = ref.watch(currentLocationProvider);
    final dateController = ref.read(agendaDateProvider.notifier);
    final locationController = ref.read(currentLocationIdProvider.notifier);

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = DateFormat('EEE d MMM', locale).format(agendaDate);

    return Row(
      children: [
        _RoundedButton(
          label: l10n.agendaToday,
          onTap: dateController.setToday,
        ),
        const SizedBox(width: 12),
        _DateSwitcher(
          label: formattedDate,
          onPrevious: dateController.previousDay,
          onNext: dateController.nextDay,
        ),
        const SizedBox(width: 12),
        _LocationSelector(
          locations: locations,
          current: currentLocation,
          onSelected: locationController.set,
        ),
      ],
    );
  }
}

class _RoundedButton extends StatelessWidget {
  const _RoundedButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final pressedFill =
        interactions?.pressedFill ?? colorScheme.primary.withOpacity(0.1);
    return SizedBox(
      height: AgendaTopControls._controlHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: AgendaTopControls._pillRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AgendaTopControls._horizontalPadding,
          ),
          side: BorderSide(color: Colors.grey.withOpacity(0.35)),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) return pressedFill;
            if (states.contains(MaterialState.hovered)) return hoverFill;
            return colorScheme.surface;
          }),
          overlayColor:
              MaterialStateProperty.all(Colors.transparent),
          elevation: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.hovered) ? 6 : 0,
          ),
          shadowColor:
              MaterialStateProperty.all(Colors.black.withOpacity(0.08)),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class _DateSwitcher extends StatefulWidget {
  const _DateSwitcher({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  State<_DateSwitcher> createState() => _DateSwitcherState();
}

class _DateSwitcherState extends State<_DateSwitcher> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final backgroundColor = _isHovered ? hoverFill : colorScheme.surface;
    final borderColor = Colors.grey.withOpacity(0.35);
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        height: AgendaTopControls._controlHeight,
        decoration: BoxDecoration(
          borderRadius: AgendaTopControls._pillRadius,
          border: Border.all(color: borderColor),
          color: backgroundColor,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateArrowButton(
              icon: Icons.chevron_left,
              onTap: widget.onPrevious,
              semanticsLabel: l10n.agendaPrevDay,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AgendaTopControls._minDateLabelWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgendaTopControls._horizontalPadding,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            _DateArrowButton(
              icon: Icons.chevron_right,
              onTap: widget.onNext,
              semanticsLabel: l10n.agendaNextDay,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateArrowButton extends StatelessWidget {
  const _DateArrowButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final splashColor =
        interactions?.pressedFill ?? Theme.of(context).colorScheme.primary.withOpacity(0.1);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: AgendaTopControls._pillRadius,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: splashColor,
        onTap: onTap,
        child: SizedBox(
          width: AgendaTopControls._controlHeight,
          height: AgendaTopControls._controlHeight,
          child: Center(
            child: Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}

class _LocationSelector extends StatefulWidget {
  const _LocationSelector({
    required this.locations,
    required this.current,
    required this.onSelected,
  });

  final List<Location> locations;
  final Location current;
  final void Function(int id) onSelected;

  @override
  State<_LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<_LocationSelector> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final backgroundColor = _isHovered ? hoverFill : colorScheme.surface;
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TooltipVisibility(
        visible: false,
        child: PopupMenuButton<int>(
          tooltip: '',
          onOpened: () => setState(() => _isHovered = true),
          onCanceled: () => setState(() => _isHovered = false),
          onSelected: (value) {
            widget.onSelected(value);
            setState(() => _isHovered = false);
          },
          itemBuilder: (context) => [
            for (final location in widget.locations)
              PopupMenuItem<int>(
                value: location.id,
                child: Text(location.name),
              ),
          ],
          child: Semantics(
            button: true,
            label: l10n.agendaSelectLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              height: AgendaTopControls._controlHeight,
              decoration: BoxDecoration(
                borderRadius: AgendaTopControls._pillRadius,
                border: Border.all(color: Colors.grey.withOpacity(0.35)),
                color: backgroundColor,
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AgendaTopControls._horizontalPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.current.name),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
