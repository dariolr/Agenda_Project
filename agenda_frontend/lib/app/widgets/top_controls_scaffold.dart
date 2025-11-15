import 'dart:math' as math;

import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/l10n/l10n.dart';
import 'package:agenda_frontend/core/models/location.dart';
import 'package:agenda_frontend/features/agenda/domain/config/layout_config.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef TopControlsBuilder =
    Widget Function(BuildContext context, TopControlsData data);

typedef AdaptiveControlsBuilder =
    Widget Function(BuildContext context, TopControlsData data);

class TopControlsData {
  const TopControlsData({
    required this.l10n,
    required this.locale,
    required this.agendaDate,
    required this.layoutConfig,
    required this.formFactor,
    required this.locations,
    required this.currentLocation,
    required this.dateController,
    required this.locationController,
  });

  final L10n l10n;
  final Locale locale;
  final DateTime agendaDate;
  final LayoutConfig layoutConfig;
  final AppFormFactor formFactor;
  final List<Location> locations;
  final Location currentLocation;
  final AgendaDateNotifier dateController;
  final CurrentLocationId locationController;

  bool get isToday => DateUtils.isSameDay(agendaDate, DateTime.now());
}

/// Widget wrapper riutilizzabile per i controlli superiori dell'agenda/staff.
///
/// Si occupa di:
/// - leggere i provider condivisi (data corrente, locations, ecc.)
/// - calcolare gli offset comuni (hour column + navigation rail)
/// - mostrare automaticamente il fallback se non ci sono locations
class TopControlsScaffold extends ConsumerWidget {
  const TopControlsScaffold({
    super.key,
    required this.builder,
    this.alignment = AlignmentDirectional.centerStart,
    this.expandToWidth = false,
    this.padding = EdgeInsets.zero,
  });

  final TopControlsBuilder builder;
  final AlignmentGeometry alignment;
  final bool expandToWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final locations = ref.watch(locationsProvider);
    if (locations.isEmpty) {
      return Text(l10n.agendaNoLocations);
    }

    final agendaDate = ref.watch(agendaDateProvider);
    final currentLocation = ref.watch(currentLocationProvider);

    final data = TopControlsData(
      l10n: l10n,
      locale: Localizations.localeOf(context),
      agendaDate: agendaDate,
      layoutConfig: layoutConfig,
      formFactor: formFactor,
      locations: locations,
      currentLocation: currentLocation,
      dateController: ref.read(agendaDateProvider.notifier),
      locationController: ref.read(currentLocationIdProvider.notifier),
    );

    final leftInset = _computeLeftInset(context, layoutConfig, formFactor);
    Widget child = builder(context, data);

    if (expandToWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: leftInset).add(padding),
        child: child,
      ),
    );
  }

  double _computeLeftInset(
    BuildContext context,
    LayoutConfig layoutConfig,
    AppFormFactor formFactor,
  ) {
    final railTheme = NavigationRailTheme.of(context);
    final railWidth = railTheme.minWidth ?? 72.0;
    const railDividerWidth = 1.0;
    final baseInset =
        layoutConfig.hourColumnWidth - NavigationToolbar.kMiddleSpacing;
    final railInset = formFactor != AppFormFactor.mobile
        ? railWidth + railDividerWidth
        : 0.0;

    return math.max(0.0, baseInset + railInset);
  }
}

/// Builder adattivo che sceglie automaticamente il layout corretto
/// (mobile/tablet/desktop) riusando il [TopControlsScaffold].
class TopControlsAdaptiveBuilder extends StatelessWidget {
  const TopControlsAdaptiveBuilder({
    super.key,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
    this.alignment = AlignmentDirectional.centerStart,
    this.expandToWidth = false,
    this.padding = EdgeInsets.zero,
    this.logConstraints = false,
    this.debugLabel,
  }) : assert(
         mobileBuilder != null ||
             tabletBuilder != null ||
             desktopBuilder != null,
         'Almeno un builder deve essere fornito',
       );

  final AdaptiveControlsBuilder? mobileBuilder;
  final AdaptiveControlsBuilder? tabletBuilder;
  final AdaptiveControlsBuilder? desktopBuilder;
  final AlignmentGeometry alignment;
  final bool expandToWidth;
  final EdgeInsetsGeometry padding;
  final bool logConstraints;
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    return TopControlsScaffold(
      alignment: alignment,
      expandToWidth: expandToWidth,
      padding: padding,
      builder: (context, data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (logConstraints) {
              debugPrint(
                '${debugLabel ?? 'TopControlsAdaptiveBuilder'} - '
                'constraints.maxWidth: ${constraints.maxWidth}, '
                'formFactor: ${data.formFactor}',
              );
            }
            final builder = _resolveBuilder(data.formFactor);
            return builder(context, data);
          },
        );
      },
    );
  }

  AdaptiveControlsBuilder _resolveBuilder(AppFormFactor factor) {
    AdaptiveControlsBuilder? selected;
    switch (factor) {
      case AppFormFactor.mobile:
        selected = mobileBuilder ?? tabletBuilder ?? desktopBuilder;
      case AppFormFactor.tablet:
        selected = tabletBuilder ?? desktopBuilder ?? mobileBuilder;
      case AppFormFactor.desktop:
        selected = desktopBuilder ?? tabletBuilder ?? mobileBuilder;
    }
    return selected ??
        (throw StateError('Nessun builder disponibile per $factor'));
  }
}

/// Row standardizzata per i controlli desktop con pulsante "Oggi",
/// date switcher e sezione location opzionale.
class TopControlsRow extends StatelessWidget {
  const TopControlsRow({
    super.key,
    required this.todayLabel,
    required this.onTodayPressed,
    required this.dateSwitcherBuilder,
    this.isTodayDisabled = false,
    this.locationSection,
    this.trailing = const [],
    this.gapAfterToday = 16,
    this.gapAfterDate = 16,
    this.gapAfterLocation = 16,
  });

  final String todayLabel;
  final VoidCallback onTodayPressed;
  final WidgetBuilder dateSwitcherBuilder;
  final bool isTodayDisabled;
  final Widget? locationSection;
  final List<Widget> trailing;
  final double gapAfterToday;
  final double gapAfterDate;
  final double gapAfterLocation;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      AgendaRoundedButton(
        label: todayLabel,
        onTap: isTodayDisabled ? null : onTodayPressed,
      ),
      SizedBox(width: gapAfterToday),
      Flexible(child: Builder(builder: dateSwitcherBuilder)),
    ];

    if (locationSection != null) {
      if (gapAfterDate > 0) {
        children.add(SizedBox(width: gapAfterDate));
      }
      children.add(locationSection!);
      if (trailing.isNotEmpty && gapAfterLocation > 0) {
        children.add(SizedBox(width: gapAfterLocation));
      }
    } else if (trailing.isNotEmpty && gapAfterDate > 0) {
      children.add(SizedBox(width: gapAfterDate));
    }

    if (trailing.isNotEmpty) {
      children.addAll(trailing);
    }

    return Row(children: children);
  }
}
