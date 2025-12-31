import 'dart:math' as math;

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/location.dart';
import 'package:agenda_backend/features/agenda/domain/config/layout_config.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef TopControlsBuilderFn =
    Widget Function(BuildContext context, TopControlsData data);

class TopControlsBuilder {
  TopControlsBuilder.single(TopControlsBuilderFn builder)
    : _single = builder,
      mobile = null,
      tablet = null,
      desktop = null;

  TopControlsBuilder.adaptive({this.mobile, this.tablet, this.desktop})
    : _single = null,
      assert(
        mobile != null || tablet != null || desktop != null,
        L10n.current.errorFormFactorBuilderRequired,
      );

  final TopControlsBuilderFn? _single;
  final TopControlsBuilderFn? mobile;
  final TopControlsBuilderFn? tablet;
  final TopControlsBuilderFn? desktop;

  Widget build(BuildContext context, TopControlsData data) {
    if (_single != null) {
      return _single(context, data);
    }
    final builder = _resolve(data.formFactor);
    return builder(context, data);
  }

  TopControlsBuilderFn _resolve(AppFormFactor factor) {
    TopControlsBuilderFn? resolved;
    switch (factor) {
      case AppFormFactor.mobile:
        resolved = mobile ?? tablet ?? desktop;
        break;
      case AppFormFactor.tablet:
        resolved = tablet ?? desktop ?? mobile;
        break;
      case AppFormFactor.desktop:
        resolved = desktop ?? tablet ?? mobile;
        break;
    }
    if (resolved == null) {
      throw StateError(L10n.current.errorFormFactorBuilderMissing(factor.name));
    }
    return resolved;
  }
}

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
    this.padding = EdgeInsets.zero,
    this.applyLayoutInset = true,
  });

  final TopControlsBuilder builder;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;
  // Permette di applicare l'offset calcolato per allineare ai contenuti
  // principali (hour column + navigation rail). Disattivato di default per
  // far partire i controlli esattamente a sinistra nell'app bar.
  final bool applyLayoutInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final locations = ref.watch(locationsProvider);
    if (locations.isEmpty) {
      return const SizedBox.shrink();
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

    final leftInset = applyLayoutInset
        ? _computeLeftInset(context, layoutConfig, formFactor)
        : 0.0;
    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        return builder.build(context, data);
      },
    );

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
