// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_bookings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyBookings)
const myBookingsProvider = MyBookingsProvider._();

final class MyBookingsProvider
    extends $NotifierProvider<MyBookings, MyBookingsState> {
  const MyBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myBookingsHash();

  @$internal
  @override
  MyBookings create() => MyBookings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MyBookingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MyBookingsState>(value),
    );
  }
}

String _$myBookingsHash() => r'c1c0e43f3b187527bcf855f1e9451fb613e1ddd5';

abstract class _$MyBookings extends $Notifier<MyBookingsState> {
  MyBookingsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MyBookingsState, MyBookingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MyBookingsState, MyBookingsState>,
              MyBookingsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
