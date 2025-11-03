import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/models/location.dart';
import 'package:flutter/material.dart';

const double kAgendaControlHeight = 40;
const double kAgendaControlHorizontalPadding = 20;
const double kAgendaMinDateLabelWidth = 140;
const BorderRadius kAgendaPillRadius = BorderRadius.all(Radius.circular(999));

class AgendaRoundedButton extends StatelessWidget {
  const AgendaRoundedButton({
    super.key,
    required this.label,
    required this.onTap,
  });

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
      height: kAgendaControlHeight,
      child: OutlinedButton(
        style:
            OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: kAgendaPillRadius,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: kAgendaControlHorizontalPadding,
              ),
              side: BorderSide(color: Colors.grey.withOpacity(0.35)),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) return pressedFill;
                if (states.contains(MaterialState.hovered)) return hoverFill;
                return colorScheme.surface;
              }),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              elevation: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.hovered) ? 6 : 0,
              ),
              shadowColor: MaterialStateProperty.all(
                Colors.black.withOpacity(0.08),
              ),
            ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class AgendaDateSwitcher extends StatefulWidget {
  const AgendaDateSwitcher({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  State<AgendaDateSwitcher> createState() => _AgendaDateSwitcherState();
}

class _AgendaDateSwitcherState extends State<AgendaDateSwitcher> {
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
        height: kAgendaControlHeight,
        decoration: BoxDecoration(
          borderRadius: kAgendaPillRadius,
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
                minWidth: kAgendaMinDateLabelWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kAgendaControlHorizontalPadding,
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
        interactions?.pressedFill ??
        Theme.of(context).colorScheme.primary.withOpacity(0.1);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: kAgendaPillRadius,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: splashColor,
        onTap: onTap,
        child: SizedBox(
          width: kAgendaControlHeight,
          height: kAgendaControlHeight,
          child: Center(child: Icon(icon, size: 18)),
        ),
      ),
    );
  }
}

class AgendaLocationSelector extends StatefulWidget {
  const AgendaLocationSelector({
    super.key,
    required this.locations,
    required this.current,
    required this.onSelected,
  });

  final List<Location> locations;
  final Location current;
  final void Function(int id) onSelected;

  @override
  State<AgendaLocationSelector> createState() => _AgendaLocationSelectorState();
}

class _AgendaLocationSelectorState extends State<AgendaLocationSelector> {
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
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          popupMenuTheme: const PopupMenuThemeData(
            shape: RoundedRectangleBorder(borderRadius: kAgendaPillRadius),
          ),
        ),
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
              child: ClipRRect(
                borderRadius: kAgendaPillRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  height: kAgendaControlHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: kAgendaPillRadius,
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
                    horizontal: kAgendaControlHorizontalPadding,
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
        ),
      ),
    );
  }
}
