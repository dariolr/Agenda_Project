// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookingsRepository)
const bookingsRepositoryProvider = BookingsRepositoryProvider._();

final class BookingsRepositoryProvider
    extends
        $FunctionalProvider<
          BookingsRepository,
          BookingsRepository,
          BookingsRepository
        >
    with $Provider<BookingsRepository> {
  const BookingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookingsRepository create(Ref ref) {
    return bookingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingsRepository>(value),
    );
  }
}

String _$bookingsRepositoryHash() =>
    r'50ae33d4ab0eb3eea9df1a6cfa054ae2ac09cdbb';

@ProviderFor(bookingsApi)
const bookingsApiProvider = BookingsApiProvider._();

final class BookingsApiProvider
    extends $FunctionalProvider<BookingsApi, BookingsApi, BookingsApi>
    with $Provider<BookingsApi> {
  const BookingsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingsApiHash();

  @$internal
  @override
  $ProviderElement<BookingsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BookingsApi create(Ref ref) {
    return bookingsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingsApi>(value),
    );
  }
}

String _$bookingsApiHash() => r'7dc61534698fed8f7bb33402d8ac248b42c292c5';
