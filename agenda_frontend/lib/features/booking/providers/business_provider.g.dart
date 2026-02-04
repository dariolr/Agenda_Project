// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider per il business corrente (caricato da slug nel path URL)
///
/// L'URL segue il pattern: /{slug}/booking, /{slug}/login, ecc.
/// Il router estrae lo slug e lo aggiorna in routeSlugProvider.
/// Questo provider reagisce ai cambi di slug e carica il business.

@ProviderFor(CurrentBusiness)
const currentBusinessProvider = CurrentBusinessProvider._();

/// Provider per il business corrente (caricato da slug nel path URL)
///
/// L'URL segue il pattern: /{slug}/booking, /{slug}/login, ecc.
/// Il router estrae lo slug e lo aggiorna in routeSlugProvider.
/// Questo provider reagisce ai cambi di slug e carica il business.
final class CurrentBusinessProvider
    extends $AsyncNotifierProvider<CurrentBusiness, Business?> {
  /// Provider per il business corrente (caricato da slug nel path URL)
  ///
  /// L'URL segue il pattern: /{slug}/booking, /{slug}/login, ecc.
  /// Il router estrae lo slug e lo aggiorna in routeSlugProvider.
  /// Questo provider reagisce ai cambi di slug e carica il business.
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

String _$currentBusinessHash() => r'2f00cc58e347ca0a27ea6647bd55565535f95823';

/// Provider per il business corrente (caricato da slug nel path URL)
///
/// L'URL segue il pattern: /{slug}/booking, /{slug}/login, ecc.
/// Il router estrae lo slug e lo aggiorna in routeSlugProvider.
/// Questo provider reagisce ai cambi di slug e carica il business.

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
/// (slug presente e business trovato nel database)

@ProviderFor(IsBusinessValid)
const isBusinessValidProvider = IsBusinessValidProvider._();

/// Provider per verificare se il business slug è valido
/// (slug presente e business trovato nel database)
final class IsBusinessValidProvider
    extends $NotifierProvider<IsBusinessValid, bool> {
  /// Provider per verificare se il business slug è valido
  /// (slug presente e business trovato nel database)
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

String _$isBusinessValidHash() => r'4d0814c4ad8b342b9ca7225311cb5e49a929041e';

/// Provider per verificare se il business slug è valido
/// (slug presente e business trovato nel database)

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

/// Provider semplice per lo slug corrente (letto dal path URL)

@ProviderFor(businessSlug)
const businessSlugProvider = BusinessSlugProvider._();

/// Provider semplice per lo slug corrente (letto dal path URL)

final class BusinessSlugProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Provider semplice per lo slug corrente (letto dal path URL)
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

String _$businessSlugHash() => r'2b426e8d5b02f0bf413dc03053031703750be5df';

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

/// Provider che verifica se l'utente è autenticato per un business DIVERSO
/// da quello corrente (basato su URL slug).
///
/// Restituisce:
/// - `null` se l'utente non è autenticato o dati non ancora caricati
/// - `true` se l'utente è autenticato per un business DIVERSO
/// - `false` se l'utente è autenticato per lo STESSO business o non autenticato
///
/// Utile per mostrare un avviso quando l'utente naviga su un business
/// diverso da quello per cui si è autenticato.

@ProviderFor(IsAuthenticatedForDifferentBusiness)
const isAuthenticatedForDifferentBusinessProvider =
    IsAuthenticatedForDifferentBusinessProvider._();

/// Provider che verifica se l'utente è autenticato per un business DIVERSO
/// da quello corrente (basato su URL slug).
///
/// Restituisce:
/// - `null` se l'utente non è autenticato o dati non ancora caricati
/// - `true` se l'utente è autenticato per un business DIVERSO
/// - `false` se l'utente è autenticato per lo STESSO business o non autenticato
///
/// Utile per mostrare un avviso quando l'utente naviga su un business
/// diverso da quello per cui si è autenticato.
final class IsAuthenticatedForDifferentBusinessProvider
    extends $AsyncNotifierProvider<IsAuthenticatedForDifferentBusiness, bool> {
  /// Provider che verifica se l'utente è autenticato per un business DIVERSO
  /// da quello corrente (basato su URL slug).
  ///
  /// Restituisce:
  /// - `null` se l'utente non è autenticato o dati non ancora caricati
  /// - `true` se l'utente è autenticato per un business DIVERSO
  /// - `false` se l'utente è autenticato per lo STESSO business o non autenticato
  ///
  /// Utile per mostrare un avviso quando l'utente naviga su un business
  /// diverso da quello per cui si è autenticato.
  const IsAuthenticatedForDifferentBusinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedForDifferentBusinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$isAuthenticatedForDifferentBusinessHash();

  @$internal
  @override
  IsAuthenticatedForDifferentBusiness create() =>
      IsAuthenticatedForDifferentBusiness();
}

String _$isAuthenticatedForDifferentBusinessHash() =>
    r'f5d1cb4db2d0827c8cb31f2a8bb0be419d3b11ee';

/// Provider che verifica se l'utente è autenticato per un business DIVERSO
/// da quello corrente (basato su URL slug).
///
/// Restituisce:
/// - `null` se l'utente non è autenticato o dati non ancora caricati
/// - `true` se l'utente è autenticato per un business DIVERSO
/// - `false` se l'utente è autenticato per lo STESSO business o non autenticato
///
/// Utile per mostrare un avviso quando l'utente naviga su un business
/// diverso da quello per cui si è autenticato.

abstract class _$IsAuthenticatedForDifferentBusiness
    extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
