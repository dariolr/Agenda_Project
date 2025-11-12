import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/models/location.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    this.useWeekRangePicker = false,
    this.onPrevious,
    this.onPreviousWeek,
    this.onNext,
    this.onNextWeek,
    this.onPreviousMonth,
    this.onNextMonth,
    required this.onSelectDate,
  });

  final String label;
  final DateTime selectedDate;
  // When true, tapping the label opens a DateRangePicker pre-filled with the
  // week (Mon-Sun) containing selectedDate, and normalizes user choice to that week.
  final bool useWeekRangePicker;
  final VoidCallback? onPrevious;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNext;
  final VoidCallback? onNextWeek;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  State<AgendaDateSwitcher> createState() => _AgendaDateSwitcherState();
}

class _AgendaDateSwitcherState extends State<AgendaDateSwitcher> {
  Future<void> _handleTap(BuildContext context) async {
    final initialDate = widget.selectedDate;
    final firstDate = DateTime(initialDate.year - 3);
    final lastDate = DateTime(initialDate.year + 3);

    if (widget.useWeekRangePicker) {
      // Custom lightweight week picker: tap qualsiasi giorno -> settimana Mon-Dom
      final selectedMonday = await _showWeekPickerDialog(
        context: context,
        anchor: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
      if (selectedMonday != null &&
          !DateUtils.isSameDay(selectedMonday, widget.selectedDate)) {
        widget.onSelectDate(selectedMonday);
      }
      return;
    }

    // Default single-date dialog
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
    final backgroundColor = colorScheme.surface;
    final l10n = context.l10n;
    final borderColor = Colors.grey.withOpacity(0.35);

    const double dividerWidth = kAgendaDividerWidth;
    final double arrowExtent = kAgendaControlHeight;
    const BorderRadius leftRadius = BorderRadius.only(
      topLeft: Radius.circular(999),
      bottomLeft: Radius.circular(999),
    );
    const BorderRadius rightRadius = BorderRadius.only(
      topRight: Radius.circular(999),
      bottomRight: Radius.circular(999),
    );

    return Container(
      height: kAgendaControlHeight,
      decoration: BoxDecoration(
        borderRadius: kAgendaPillRadius,
        border: Border.all(color: borderColor),
        color: backgroundColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          // Treat widths below ~330px as compact to avoid horizontal overflow.
          // Breakdown of minimum non-compact width:
          // - 4 arrows @40px = 160
          // - 4 dividers @1px = 4
          // - label min width 120 + default padding 20*2 = 160
          // Total ≈ 324px (use some safety margin)
          const compactBreakpoint = 330.0;
          final isCompact =
              maxWidth.isFinite && maxWidth > 0 && maxWidth < compactBreakpoint;
          final horizontalPadding = isCompact
              ? 12.0
              : kAgendaControlHorizontalPadding;
          final labelSemantics = MaterialLocalizations.of(
            context,
          ).datePickerHelpText;

          // Use app l10n via context.l10n for semantics labels

          Widget buildDivider(VoidCallback onTap) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: dividerWidth,
              height: kAgendaControlHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: borderColor.withOpacity(0.5)),
              ),
            ),
          );

          Widget buildArrowButton({
            required IconData icon,
            required VoidCallback onTap,
            required String semanticsLabel,
            required BorderRadius borderRadius,
          }) {
            return _HoverableRegion(
              onTap: onTap,
              semanticsLabel: semanticsLabel,
              hoverColor: hoverFill,
              width: arrowExtent,
              borderRadius: borderRadius,
              child: Center(
                child: Icon(icon, size: arrowExtent <= 32 ? 16.0 : 18.0),
              ),
            );
          }

          Widget buildLabelRegion() => _HoverableRegion(
            onTap: () => _handleTap(context),
            semanticsLabel: labelSemantics,
            hoverColor: hoverFill,
            minWidth: kAgendaMinDateLabelWidth,
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

          final labelRegion = buildLabelRegion();
          final children = <Widget>[
            if (widget.onPreviousMonth != null) ...[
              buildArrowButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: widget.onPreviousMonth!,
                semanticsLabel: l10n.agendaPrevMonth,
                borderRadius: leftRadius,
              ),
              buildDivider(widget.onPreviousMonth!),
            ] else if (widget.onPreviousWeek != null) ...[
              buildArrowButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: widget.onPreviousWeek!,
                semanticsLabel: l10n.agendaPrevWeek,
                borderRadius: leftRadius,
              ),
              buildDivider(widget.onPreviousWeek!),
            ] else ...[
              SizedBox(width: arrowExtent, height: kAgendaControlHeight),
              SizedBox(width: dividerWidth),
            ],
            buildArrowButton(
              icon: Icons.keyboard_arrow_left,
              onTap: widget.onPrevious ?? () {},
              semanticsLabel: l10n.agendaPrevDay,
              borderRadius: BorderRadius.zero,
            ),
            buildDivider(() => _handleTap(context)),
          ];

          if (isCompact) {
            children.add(Expanded(child: labelRegion));
          } else {
            children.add(labelRegion);
          }

          children.addAll([
            buildDivider(() => _handleTap(context)),
            buildArrowButton(
              icon: Icons.keyboard_arrow_right,
              onTap: widget.onNext ?? () {},
              semanticsLabel: l10n.agendaNextDay,
              borderRadius: BorderRadius.zero,
            ),
            if (widget.onNextMonth != null) ...[
              buildDivider(widget.onNextMonth!),
              buildArrowButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: widget.onNextMonth!,
                semanticsLabel: l10n.agendaNextMonth,
                borderRadius: rightRadius,
              ),
            ] else if (widget.onNextWeek != null) ...[
              buildDivider(widget.onNextWeek!),
              buildArrowButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: widget.onNextWeek!,
                semanticsLabel: l10n.agendaNextWeek,
                borderRadius: rightRadius,
              ),
            ] else ...[
              SizedBox(width: dividerWidth),
              SizedBox(width: arrowExtent, height: kAgendaControlHeight),
            ],
          ]);

          return Row(
            mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
            children: children,
          );
        },
      ),
    );
  }
}

/// Shows a simple dialog with a month grid. Selecting any day returns the Monday
/// of that week. Month navigation supported. Highlights the whole week.
Future<DateTime?> _showWeekPickerDialog({
  required BuildContext context,
  required DateTime anchor,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.12),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, _, __) {
      return _WeekPickerContent(
        anchor: anchor,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

class _WeekPickerContent extends StatefulWidget {
  const _WeekPickerContent({
    required this.anchor,
    required this.firstDate,
    required this.lastDate,
  });
  final DateTime anchor;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_WeekPickerContent> createState() => _WeekPickerContentState();
}

class _WeekPickerContentState extends State<_WeekPickerContent> {
  late DateTime _focusedMonth; // first day of focused month
  DateTime? _hoverDay;
  late DateTime _selectedMonday;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.anchor.year, widget.anchor.month, 1);
    _selectedMonday = _mondayOf(widget.anchor);
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - DateTime.monday));

  bool _inSameWeek(DateTime day, DateTime monday) {
    final diff = day.difference(monday).inDays;
    return diff >= 0 && diff < 7;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat('MMMM y', locale).format(_focusedMonth);
    final localizations = MaterialLocalizations.of(context);
    final firstGridDay = _mondayOf(_focusedMonth);
    // 6 weeks grid
    final days = List.generate(42, (i) => firstGridDay.add(Duration(days: i)));
    final hoveredWeekMonday = _hoverDay != null ? _mondayOf(_hoverDay!) : null;

    Color weekBg(bool inSelected, bool inHovered) {
      final base = theme.colorScheme.primary;
      if (inSelected) return base.withOpacity(0.18);
      if (inHovered) return base.withOpacity(0.10);
      return Colors.transparent;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          elevation: 12,
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: localizations.previousMonthTooltip,
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            monthLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: localizations.nextMonthTooltip,
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Weekday headers (Mon-Sun)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Row(
                    children: [
                      // Use MaterialLocalizations (shortWeekdays) starting from Monday.
                      // MaterialLocalizations non espone shortWeekdays; generiamo abbreviazioni
                      // localizzate usando DateFormat('E'). Partiamo dal lunedì.
                      for (int i = 0; i < 7; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              DateFormat('E', locale).format(
                                _mondayOf(_focusedMonth).add(Duration(days: i)),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      // end weekday headers
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      for (int w = 0; w < 6; w++) ...[
                        Row(
                          children: [
                            for (int d = 0; d < 7; d++) ...[
                              Builder(
                                builder: (context) {
                                  final day = days[w * 7 + d];
                                  // final mondayOfDay = _mondayOf(day); // not needed after normalization on tap
                                  final inSelectedWeek = _inSameWeek(
                                    day,
                                    _selectedMonday,
                                  );
                                  final inHoveredWeek =
                                      hoveredWeekMonday != null &&
                                      _inSameWeek(day, hoveredWeekMonday);
                                  final isOutOfRange =
                                      day.isBefore(widget.firstDate) ||
                                      day.isAfter(widget.lastDate);
                                  final isCurrentMonth =
                                      day.month == _focusedMonth.month;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: isOutOfRange
                                          ? null
                                          : () {
                                              final newMonday = _mondayOf(day);
                                              Navigator.of(context).pop(
                                                DateUtils.dateOnly(newMonday),
                                              );
                                            },
                                      child: MouseRegion(
                                        onEnter: (_) =>
                                            setState(() => _hoverDay = day),
                                        onExit: (_) =>
                                            setState(() => _hoverDay = null),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 120,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: weekBg(
                                              inSelectedWeek,
                                              inHoveredWeek,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${day.day}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: isOutOfRange
                                                      ? theme.disabledColor
                                                      : (isCurrentMonth
                                                            ? theme
                                                                  .colorScheme
                                                                  .onSurface
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.45,
                                                                  )),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localizations.cancelButtonLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverableRegion extends StatefulWidget {
  const _HoverableRegion({
    required this.onTap,
    required this.semanticsLabel,
    required this.hoverColor,
    required this.child,
    this.width,
    this.minWidth,
    this.padding,
    this.borderRadius = BorderRadius.zero,
  });

  final VoidCallback onTap;
  final String semanticsLabel;
  final Color hoverColor;
  final Widget child;
  final double? width;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  @override
  State<_HoverableRegion> createState() => _HoverableRegionState();
}

class _HoverableRegionState extends State<_HoverableRegion> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final constraints = widget.minWidth != null
        ? BoxConstraints(minWidth: widget.minWidth!)
        : const BoxConstraints();

    Widget content = widget.child;
    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: widget.width,
              constraints: constraints,
              height: kAgendaControlHeight,
              color: _hovered ? widget.hoverColor : Colors.transparent,
              child: content,
            ),
          ),
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
      highlightColor: Colors.transparent,
      borderRadius: kAgendaPillRadius,
      child: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
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
