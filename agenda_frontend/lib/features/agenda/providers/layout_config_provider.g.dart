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
    extends $NotifierProvider<LayoutConfigNotifier, LayoutConfig> {
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
  Override overrideWithValue(LayoutConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LayoutConfig>(value),
    );
  }
}

String _$layoutConfigNotifierHash() =>
    r'850083366aea0ce85343fe700d326c9e075842cf';

/// Provider responsabile di mantenere aggiornata la configurazione del layout
/// (in particolare l’altezza degli slot e dell’header)

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
