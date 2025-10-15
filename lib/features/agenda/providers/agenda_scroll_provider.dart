import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/staff.dart';

part 'agenda_scroll_provider.g.dart';

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

@riverpod
class AgendaScroll extends _$AgendaScroll {
  @override
  AgendaScrollState build(List<Staff> staffList) {
    final verticalCtrl = ScrollController();
    final horizontalCtrl = ScrollController();
    final staffCtrls = {for (final s in staffList) s.id: ScrollController()};

    ref.onDispose(() {
      verticalCtrl.dispose();
      horizontalCtrl.dispose();
      for (final c in staffCtrls.values) {
        c.dispose();
      }
    });

    return AgendaScrollState(
      verticalScrollCtrl: verticalCtrl,
      horizontalScrollCtrl: horizontalCtrl,
      staffScrollCtrls: staffCtrls,
    );
  }

  /// Sincronizza orizzontalmente lo scroll (se serve)
  void syncHorizontal(double offset) {
    final st = state;
    if (st.horizontalScrollCtrl.hasClients) {
      st.horizontalScrollCtrl.jumpTo(offset);
    }
  }
}
