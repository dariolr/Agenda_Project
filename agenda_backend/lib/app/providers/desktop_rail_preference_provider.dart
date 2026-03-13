import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/preferences_service.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Preferenza UI globale (solo superadmin):
/// se true, su desktop il navigation rail parte dall'alto.
class DesktopRailStartsAtTopNotifier extends Notifier<bool> {
  static const bool _defaultValue = true;

  @override
  bool build() {
    final isSuperadmin = ref.watch(authProvider).user?.isSuperadmin ?? false;
    if (!isSuperadmin) {
      return _defaultValue;
    }
    return ref.read(preferencesServiceProvider).getDesktopRailStartsAtTop();
  }

  void set(bool enabled) {
    if (state == enabled) return;
    state = enabled;

    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    if (!isSuperadmin) return;

    unawaited(
      ref.read(preferencesServiceProvider).setDesktopRailStartsAtTop(enabled),
    );
  }
}

final desktopRailStartsAtTopProvider =
    NotifierProvider<DesktopRailStartsAtTopNotifier, bool>(
      DesktopRailStartsAtTopNotifier.new,
    );
