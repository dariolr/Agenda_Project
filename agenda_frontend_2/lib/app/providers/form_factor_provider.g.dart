// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_factor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FormFactorNotifier)
const formFactorProvider = FormFactorNotifierProvider._();

final class FormFactorNotifierProvider
    extends $NotifierProvider<FormFactorNotifier, AppFormFactor> {
  const FormFactorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formFactorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formFactorNotifierHash();

  @$internal
  @override
  FormFactorNotifier create() => FormFactorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppFormFactor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppFormFactor>(value),
    );
  }
}

String _$formFactorNotifierHash() =>
    r'c2d345138b8b938ff84a110cd4b6bf3dda7a605e';

abstract class _$FormFactorNotifier extends $Notifier<AppFormFactor> {
  AppFormFactor build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AppFormFactor, AppFormFactor>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppFormFactor, AppFormFactor>,
              AppFormFactor,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
