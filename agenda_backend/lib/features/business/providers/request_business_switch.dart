import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import 'superadmin_selected_business_provider.dart';

void requestBusinessSwitch(
  BuildContext context,
  WidgetRef ref, {
  required String source,
}) {
  final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;

  if (isSuperadmin) {
    context.go('/businesses?switch=1');
    return;
  }

  invalidateBusinessScopedProviders(ref);
  ref.invalidate(currentBusinessUserContextProvider);
  context.go('/my-businesses?switch=1');
}
