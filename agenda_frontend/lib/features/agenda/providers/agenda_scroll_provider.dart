import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/staff.dart';

/// Stato con tutti i controller di scroll sincronizzati
class AgendaScrollState {
  final ScrollController verticalScrollCtrl;
  final ScrollController horizontalScrollCtrl;
  final Map<int, ScrollController> staffScrollCtrls;

  const AgendaScrollState({
    required this.verticalScrollCtrl,
    required this.horizontalScrollCtrl,
    required this.staffScrollCtrls,
  });
}

@immutable
class AgendaScrollKey {
  final Object identity;
  final List<Staff> staff;
  final DateTime date;
  final double initialOffset;

  const AgendaScrollKey({
    required this.identity,
    required this.staff,
    required this.date,
    required this.initialOffset,
  });

  @override
  bool operator ==(Object other) {
    return other is AgendaScrollKey && identical(other.identity, identity);
  }

  @override
  int get hashCode => identity.hashCode;
}

final agendaScrollProvider = Provider.family.autoDispose<AgendaScrollState, AgendaScrollKey>((ref, key) {
  final staffList = key.staff;
  final verticalCtrl = ScrollController(initialScrollOffset: key.initialOffset);
  final horizontalCtrl = ScrollController();
  final Map<int, ScrollController> staffCtrls = {
    for (final s in staffList) s.id: ScrollController(),
  };

  ref.onDispose(() {
    verticalCtrl.dispose();
    horizontalCtrl.dispose();
    for (final controller in staffCtrls.values) {
      controller.dispose();
    }
  });

  return AgendaScrollState(
    verticalScrollCtrl: verticalCtrl,
    horizontalScrollCtrl: horizontalCtrl,
    staffScrollCtrls: staffCtrls,
  );
});
