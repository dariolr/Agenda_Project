// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_users_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider per il repository degli operatori.

@ProviderFor(businessUsersRepository)
const businessUsersRepositoryProvider = BusinessUsersRepositoryProvider._();

/// Provider per il repository degli operatori.

final class BusinessUsersRepositoryProvider
    extends
        $FunctionalProvider<
          BusinessUsersRepository,
          BusinessUsersRepository,
          BusinessUsersRepository
        >
    with $Provider<BusinessUsersRepository> {
  /// Provider per il repository degli operatori.
  const BusinessUsersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessUsersRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessUsersRepositoryHash();

  @$internal
  @override
  $ProviderElement<BusinessUsersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BusinessUsersRepository create(Ref ref) {
    return businessUsersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusinessUsersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusinessUsersRepository>(value),
    );
  }
}

String _$businessUsersRepositoryHash() =>
    r'9f3d9ab7572fd99339bb7c1cf46784915cd0faf8';

/// Notifier per gestire gli operatori di un business.

@ProviderFor(BusinessUsersNotifier)
const businessUsersProvider = BusinessUsersNotifierFamily._();

/// Notifier per gestire gli operatori di un business.
final class BusinessUsersNotifierProvider
    extends $NotifierProvider<BusinessUsersNotifier, BusinessUsersState> {
  /// Notifier per gestire gli operatori di un business.
  const BusinessUsersNotifierProvider._({
    required BusinessUsersNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'businessUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$businessUsersNotifierHash();

  @override
  String toString() {
    return r'businessUsersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BusinessUsersNotifier create() => BusinessUsersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusinessUsersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusinessUsersState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BusinessUsersNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$businessUsersNotifierHash() =>
    r'ad5c91c0763998e097c8aedb9e969dfa063a0858';

/// Notifier per gestire gli operatori di un business.

final class BusinessUsersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BusinessUsersNotifier,
          BusinessUsersState,
          BusinessUsersState,
          BusinessUsersState,
          int
        > {
  const BusinessUsersNotifierFamily._()
    : super(
        retry: null,
        name: r'businessUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier per gestire gli operatori di un business.

  BusinessUsersNotifierProvider call(int businessId) =>
      BusinessUsersNotifierProvider._(argument: businessId, from: this);

  @override
  String toString() => r'businessUsersProvider';
}

/// Notifier per gestire gli operatori di un business.

abstract class _$BusinessUsersNotifier extends $Notifier<BusinessUsersState> {
  late final _$args = ref.$arg as int;
  int get businessId => _$args;

  BusinessUsersState build(int businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<BusinessUsersState, BusinessUsersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BusinessUsersState, BusinessUsersState>,
              BusinessUsersState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
