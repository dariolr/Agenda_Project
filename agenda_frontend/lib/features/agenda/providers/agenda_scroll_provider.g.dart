// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_scroll_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgendaScroll)
const agendaScrollProvider = AgendaScrollFamily._();

final class AgendaScrollProvider
    extends $NotifierProvider<AgendaScroll, AgendaScrollState> {
  const AgendaScrollProvider._({
    required AgendaScrollFamily super.from,
    required List<Staff> super.argument,
  }) : super(
         retry: null,
         name: r'agendaScrollProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agendaScrollHash();

  @override
  String toString() {
    return r'agendaScrollProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AgendaScroll create() => AgendaScroll();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgendaScrollState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgendaScrollState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AgendaScrollProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agendaScrollHash() => r'68ed618f8b12029a0d3177f2c9e8f146840ca836';

final class AgendaScrollFamily extends $Family
    with
        $ClassFamilyOverride<
          AgendaScroll,
          AgendaScrollState,
          AgendaScrollState,
          AgendaScrollState,
          List<Staff>
        > {
  const AgendaScrollFamily._()
    : super(
        retry: null,
        name: r'agendaScrollProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AgendaScrollProvider call(List<Staff> staffList) =>
      AgendaScrollProvider._(argument: staffList, from: this);

  @override
  String toString() => r'agendaScrollProvider';
}

abstract class _$AgendaScroll extends $Notifier<AgendaScrollState> {
  late final _$args = ref.$arg as List<Staff>;
  List<Staff> get staffList => _$args;

  AgendaScrollState build(List<Staff> staffList);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AgendaScrollState, AgendaScrollState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AgendaScrollState, AgendaScrollState>,
              AgendaScrollState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
