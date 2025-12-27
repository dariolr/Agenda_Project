// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(staffRepository)
const staffRepositoryProvider = StaffRepositoryProvider._();

final class StaffRepositoryProvider
    extends
        $FunctionalProvider<StaffRepository, StaffRepository, StaffRepository>
    with $Provider<StaffRepository> {
  const StaffRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffRepositoryHash();

  @$internal
  @override
  $ProviderElement<StaffRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StaffRepository create(Ref ref) {
    return staffRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaffRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaffRepository>(value),
    );
  }
}

String _$staffRepositoryHash() => r'f2d32cabb396f95a9f8be7d15391f2dec04629c1';
