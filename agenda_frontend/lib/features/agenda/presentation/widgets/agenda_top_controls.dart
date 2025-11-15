import 'package:agenda_frontend/app/widgets/top_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgendaTopControls extends ConsumerWidget {
  const AgendaTopControls({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TopControls.agenda(compact: compact);
  }
}
