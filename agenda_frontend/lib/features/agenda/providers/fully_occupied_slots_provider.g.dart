// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fully_occupied_slots_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calcola gli indici degli slot completamente occupati per un dato staff.
/// Uno slot è "completamente occupato" quando la somma delle frazioni di larghezza
/// degli appuntamenti che lo coprono raggiunge o supera il 100%.

@ProviderFor(fullyOccupiedSlots)
const fullyOccupiedSlotsProvider = FullyOccupiedSlotsFamily._();

/// Calcola gli indici degli slot completamente occupati per un dato staff.
/// Uno slot è "completamente occupato" quando la somma delle frazioni di larghezza
/// degli appuntamenti che lo coprono raggiunge o supera il 100%.

final class FullyOccupiedSlotsProvider
    extends $FunctionalProvider<Set<int>, Set<int>, Set<int>>
    with $Provider<Set<int>> {
  /// Calcola gli indici degli slot completamente occupati per un dato staff.
  /// Uno slot è "completamente occupato" quando la somma delle frazioni di larghezza
  /// degli appuntamenti che lo coprono raggiunge o supera il 100%.
  const FullyOccupiedSlotsProvider._({
    required FullyOccupiedSlotsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'fullyOccupiedSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fullyOccupiedSlotsHash();

  @override
  String toString() {
    return r'fullyOccupiedSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<int> create(Ref ref) {
    final argument = this.argument as int;
    return fullyOccupiedSlots(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FullyOccupiedSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fullyOccupiedSlotsHash() =>
    r'cac3293a238229a07421123556e10d4471801e64';

/// Calcola gli indici degli slot completamente occupati per un dato staff.
/// Uno slot è "completamente occupato" quando la somma delle frazioni di larghezza
/// degli appuntamenti che lo coprono raggiunge o supera il 100%.

final class FullyOccupiedSlotsFamily extends $Family
    with $FunctionalFamilyOverride<Set<int>, int> {
  const FullyOccupiedSlotsFamily._()
    : super(
        retry: null,
        name: r'fullyOccupiedSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calcola gli indici degli slot completamente occupati per un dato staff.
  /// Uno slot è "completamente occupato" quando la somma delle frazioni di larghezza
  /// degli appuntamenti che lo coprono raggiunge o supera il 100%.

  FullyOccupiedSlotsProvider call(int staffId) =>
      FullyOccupiedSlotsProvider._(argument: staffId, from: this);

  @override
  String toString() => r'fullyOccupiedSlotsProvider';
}
