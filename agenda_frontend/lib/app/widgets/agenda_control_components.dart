import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/models/location.dart';
import 'package:flutter/material.dart';

const double kAgendaControlHeight = 40;
const double kAgendaControlHorizontalPadding = 20;
const double kAgendaMinDateLabelWidth = 120;
const BorderRadius kAgendaPillRadius = BorderRadius.all(Radius.circular(999));
const double kAgendaDividerWidth = 1;

class AgendaRoundedButton extends StatelessWidget {
  const AgendaRoundedButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final pressedFill =
        interactions?.pressedFill ?? colorScheme.primary.withOpacity(0.1);
    final disabledFill = colorScheme.surface.withOpacity(0.6);
    final disabledForeground = colorScheme.onSurface.withOpacity(0.38);
    final enabledText = colorScheme.onSurface;
    final disabledBorder = colorScheme.onSurface.withOpacity(0.12);
    final enabledBorder = Colors.grey.withOpacity(0.35);

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
              side: BorderSide(color: enabledBorder),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return disabledFill;
                }
                if (states.contains(MaterialState.pressed)) return pressedFill;
                if (states.contains(MaterialState.hovered)) return hoverFill;
                return colorScheme.surface;
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return disabledForeground;
                }
                return enabledText;
              }),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              elevation: MaterialStateProperty.resolveWith(
                (states) =>
                    states.contains(MaterialState.hovered) &&
                        !states.contains(MaterialState.disabled)
                    ? 6
                    : 0,
              ),
              shadowColor: MaterialStateProperty.all(
                Colors.black.withOpacity(0.08),
              ),
              side: MaterialStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(MaterialState.disabled)
                      ? disabledBorder
                      : enabledBorder,
                ),
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
    required this.selectedDate,
    required this.onPrevious,
    required this.onPreviousWeek,
    required this.onNext,
    required this.onNextWeek,
    required this.onSelectDate,
  });

  final String label;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNext;
  final VoidCallback onNextWeek;
  final ValueChanged<DateTime> onSelectDate;

  @override
  State<AgendaDateSwitcher> createState() => _AgendaDateSwitcherState();
}

class _AgendaDateSwitcherState extends State<AgendaDateSwitcher> {
  bool _isHovered = false;

  Future<void> _handleTap(BuildContext context) async {
    final initialDate = widget.selectedDate;
    final firstDate = DateTime(initialDate.year - 3);
    final lastDate = DateTime(initialDate.year + 3);

    final picked = await showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.12),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, _, __) {
        final theme = Theme.of(dialogContext);
        final localizations = MaterialLocalizations.of(dialogContext);
        final borderColor = theme.dividerColor.withOpacity(0.24);
        final baseHeadline =
            theme.datePickerTheme.headerHeadlineStyle ??
            theme.textTheme.titleLarge ??
            const TextStyle(fontSize: 18);
        final datePickerTheme = theme.datePickerTheme.copyWith(
          headerHeadlineStyle: baseHeadline.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Material(
              elevation: 12,
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Theme(
                        data: theme.copyWith(datePickerTheme: datePickerTheme),
                        child: CalendarDatePicker(
                          initialDate: initialDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (selected) {
                            Navigator.of(
                              dialogContext,
                            ).pop(DateUtils.dateOnly(selected));
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(localizations.cancelButtonLabel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null && !DateUtils.isSameDay(picked, widget.selectedDate)) {
      widget.onSelectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final interactions = Theme.of(context).extension<AppInteractionColors>();
    final hoverFill =
        interactions?.hoverFill ?? colorScheme.primary.withOpacity(0.06);
    final backgroundColor = _isHovered
        ? Color.alphaBlend(hoverFill, colorScheme.surface)
        : colorScheme.surface;
    final l10n = context.l10n;
    final borderColor = Colors.grey.withOpacity(0.35);
    return InkWell(
      onHover: (hovering) {
        if (hovering != _isHovered) {
          setState(() => _isHovered = hovering);
        }
      },
      onTap: () => _handleTap(context),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: kAgendaPillRadius,
      child: Container(
        height: kAgendaControlHeight,
        decoration: BoxDecoration(
          borderRadius: kAgendaPillRadius,
          border: Border.all(color: borderColor),
          color: backgroundColor,
          boxShadow: null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            const compactBreakpoint = 260.0;
            final isCompact =
                maxWidth.isFinite &&
                maxWidth > 0 &&
                maxWidth < compactBreakpoint;
            final horizontalPadding = isCompact
                ? 12.0
                : kAgendaControlHorizontalPadding;
            final arrowExtent = isCompact ? 32.0 : kAgendaControlHeight;

            Widget label = Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            );

            if (!isCompact) {
              label = ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: kAgendaMinDateLabelWidth,
                ),
                child: label,
              );
            }

            Widget buildDivider(VoidCallback onTap) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: SizedBox(
                width: kAgendaDividerWidth,
                height: kAgendaControlHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.5),
                  ),
                ),
              ),
            );

            Widget buildArrowButton({
              required IconData icon,
              required VoidCallback onTap,
              required String semanticsLabel,
            }) {
              return Semantics(
                button: true,
                label: semanticsLabel,
                child: InkWell(
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: onTap,
                  child: SizedBox(
                    width: arrowExtent,
                    height: kAgendaControlHeight,
                    child: Center(
                      child: Icon(icon, size: arrowExtent <= 32 ? 16.0 : 18.0),
                    ),
                  ),
                ),
              );
            }

            Widget buildLabelArea() {
              final semanticsLabel = MaterialLocalizations.of(
                context,
              ).datePickerHelpText;

              final labelInkWell = Semantics(
                button: true,
                label: semanticsLabel,
                child: InkWell(
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () => _handleTap(context),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.label,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              );

              if (isCompact) {
                return Expanded(child: labelInkWell);
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: kAgendaMinDateLabelWidth,
                ),
                child: SizedBox(
                  height: kAgendaControlHeight,
                  child: labelInkWell,
                ),
              );
            }

            return Row(
              mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                buildArrowButton(
                  icon: Icons.keyboard_double_arrow_left,
                  onTap: widget.onPreviousWeek,
                  semanticsLabel: l10n.agendaPrevWeek,
                ),
                buildDivider(widget.onPreviousWeek),
                buildArrowButton(
                  icon: Icons.keyboard_arrow_left,
                  onTap: widget.onPrevious,
                  semanticsLabel: l10n.agendaPrevDay,
                ),
                buildDivider(() => _handleTap(context)),
                buildLabelArea(),
                buildDivider(() => _handleTap(context)),
                buildArrowButton(
                  icon: Icons.keyboard_arrow_right,
                  onTap: widget.onNext,
                  semanticsLabel: l10n.agendaNextDay,
                ),
                buildDivider(widget.onNextWeek),
                buildArrowButton(
                  icon: Icons.keyboard_double_arrow_right,
                  onTap: widget.onNextWeek,
                  semanticsLabel: l10n.agendaNextWeek,
                ),
              ],
            );
          },
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
    final backgroundColor = _isHovered
        ? Color.alphaBlend(hoverFill, colorScheme.surface)
        : colorScheme.surface;
    final l10n = context.l10n;

    return InkWell(
      onHover: (hovering) {
        if (hovering != _isHovered) {
          setState(() => _isHovered = hovering);
        }
      },
      onTap: () {},
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: kAgendaPillRadius,
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
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
                child: Container(
                  height: kAgendaControlHeight,
                  decoration: BoxDecoration(
                    borderRadius: kAgendaPillRadius,
                    border: Border.all(color: Colors.grey.withOpacity(0.35)),
                    color: backgroundColor,
                    boxShadow: null,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const compactBreakpoint = 220.0;
                      final maxWidth = constraints.maxWidth;
                      final isCompact =
                          maxWidth.isFinite &&
                          maxWidth > 0 &&
                          maxWidth < compactBreakpoint;
                      final horizontalPadding = isCompact
                          ? 12.0
                          : kAgendaControlHorizontalPadding;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.current.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
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
