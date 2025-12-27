// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(locationsRepository)
const locationsRepositoryProvider = LocationsRepositoryProvider._();

final class LocationsRepositoryProvider
    extends
        $FunctionalProvider<
          LocationsRepository,
          LocationsRepository,
          LocationsRepository
        >
    with $Provider<LocationsRepository> {
  const LocationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationsRepository create(Ref ref) {
    return locationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationsRepository>(value),
    );
  }
}

String _$locationsRepositoryHash() =>
    r'b7c903cb21a57814102a5236a124d97353234b6d';
