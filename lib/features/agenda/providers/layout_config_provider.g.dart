// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider responsabile di mantenere aggiornata la configurazione del layout
/// (in particolare l’altezza degli slot e dell’header)

@ProviderFor(LayoutConfigNotifier)
const layoutConfigProvider = LayoutConfigNotifierProvider._();

/// Provider responsabile di mantenere aggiornata la configurazione del layout
/// (in particolare l’altezza degli slot e dell’header)
final class LayoutConfigNotifierProvider
    extends $NotifierProvider<LayoutConfigNotifier, double> {
  /// Provider responsabile di mantenere aggiornata la configurazione del layout
  /// (in particolare l’altezza degli slot e dell’header)
  const LayoutConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'layoutConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$layoutConfigNotifierHash();

  @$internal
  @override
  LayoutConfigNotifier create() => LayoutConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$layoutConfigNotifierHash() =>
    r'57a4ba295f79fbc4359b8a531d26239836ede945';

/// Provider responsabile di mantenere aggiornata la configurazione del layout
/// (in particolare l’altezza degli slot e dell’header)

abstract class _$LayoutConfigNotifier extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
