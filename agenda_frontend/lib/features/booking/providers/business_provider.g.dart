// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider per il business corrente (caricato da slug)
///
/// Se l'URL è un sottodominio business (es. salonemario.prenota.romeolab.it),
/// carica automaticamente i dati del business.
/// Altrimenti ritorna null (l'app mostrerà una selezione manuale).

@ProviderFor(CurrentBusiness)
const currentBusinessProvider = CurrentBusinessProvider._();

/// Provider per il business corrente (caricato da slug)
///
/// Se l'URL è un sottodominio business (es. salonemario.prenota.romeolab.it),
/// carica automaticamente i dati del business.
/// Altrimenti ritorna null (l'app mostrerà una selezione manuale).
final class CurrentBusinessProvider
    extends $AsyncNotifierProvider<CurrentBusiness, Business?> {
  /// Provider per il business corrente (caricato da slug)
  ///
  /// Se l'URL è un sottodominio business (es. salonemario.prenota.romeolab.it),
  /// carica automaticamente i dati del business.
  /// Altrimenti ritorna null (l'app mostrerà una selezione manuale).
  const CurrentBusinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentBusinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentBusinessHash();

  @$internal
  @override
  CurrentBusiness create() => CurrentBusiness();
}

String _$currentBusinessHash() => r'9bab89caeb9c8b34f935723daf71f1beefef513a';

/// Provider per il business corrente (caricato da slug)
///
/// Se l'URL è un sottodominio business (es. salonemario.prenota.romeolab.it),
/// carica automaticamente i dati del business.
/// Altrimenti ritorna null (l'app mostrerà una selezione manuale).

abstract class _$CurrentBusiness extends $AsyncNotifier<Business?> {
  FutureOr<Business?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Business?>, Business?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Business?>, Business?>,
              AsyncValue<Business?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider per l'ID del business corrente (sincrono, utility)

@ProviderFor(CurrentBusinessId)
const currentBusinessIdProvider = CurrentBusinessIdProvider._();

/// Provider per l'ID del business corrente (sincrono, utility)
final class CurrentBusinessIdProvider
    extends $NotifierProvider<CurrentBusinessId, int?> {
  /// Provider per l'ID del business corrente (sincrono, utility)
  const CurrentBusinessIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentBusinessIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentBusinessIdHash();

  @$internal
  @override
  CurrentBusinessId create() => CurrentBusinessId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$currentBusinessIdHash() => r'dbb21b4e931947e9e1f0a0e7d3927a478d463ae0';

/// Provider per l'ID del business corrente (sincrono, utility)

abstract class _$CurrentBusinessId extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider per verificare se il business slug è valido

@ProviderFor(IsBusinessValid)
const isBusinessValidProvider = IsBusinessValidProvider._();

/// Provider per verificare se il business slug è valido
final class IsBusinessValidProvider
    extends $NotifierProvider<IsBusinessValid, bool> {
  /// Provider per verificare se il business slug è valido
  const IsBusinessValidProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isBusinessValidProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isBusinessValidHash();

  @$internal
  @override
  IsBusinessValid create() => IsBusinessValid();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isBusinessValidHash() => r'7d49c025f2b52cad0a233621496bfe00434482c5';

/// Provider per verificare se il business slug è valido

abstract class _$IsBusinessValid extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider semplice per lo slug corrente

@ProviderFor(businessSlug)
const businessSlugProvider = BusinessSlugProvider._();

/// Provider semplice per lo slug corrente

final class BusinessSlugProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Provider semplice per lo slug corrente
  const BusinessSlugProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessSlugProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessSlugHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return businessSlug(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$businessSlugHash() => r'd8e29a503c13fbfeb8e7353bfa60cc519c6a4d0c';

/// Provider per verificare se siamo su un sottodominio business

@ProviderFor(isBusinessSubdomain)
const isBusinessSubdomainProvider = IsBusinessSubdomainProvider._();

/// Provider per verificare se siamo su un sottodominio business

final class IsBusinessSubdomainProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider per verificare se siamo su un sottodominio business
  const IsBusinessSubdomainProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isBusinessSubdomainProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isBusinessSubdomainHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isBusinessSubdomain(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isBusinessSubdomainHash() =>
    r'7af66aeaae959e3aa4b1de252d5328627d90c0a1';
