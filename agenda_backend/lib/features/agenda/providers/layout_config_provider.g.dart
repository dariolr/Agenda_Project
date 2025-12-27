// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mantiene aggiornata la configurazione del layout agenda (slot/header/hour column).

@ProviderFor(LayoutConfigNotifier)
const layoutConfigProvider = LayoutConfigNotifierProvider._();

/// Mantiene aggiornata la configurazione del layout agenda (slot/header/hour column).
final class LayoutConfigNotifierProvider
    extends $NotifierProvider<LayoutConfigNotifier, LayoutConfig> {
  /// Mantiene aggiornata la configurazione del layout agenda (slot/header/hour column).
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
  Override overrideWithValue(LayoutConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LayoutConfig>(value),
    );
  }
}

String _$layoutConfigNotifierHash() =>
    r'a50c2234a17993d2106f79a9dcb393e753f97c9b';

/// Mantiene aggiornata la configurazione del layout agenda (slot/header/hour column).

abstract class _$LayoutConfigNotifier extends $Notifier<LayoutConfig> {
  LayoutConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LayoutConfig, LayoutConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LayoutConfig, LayoutConfig>,
              LayoutConfig,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
