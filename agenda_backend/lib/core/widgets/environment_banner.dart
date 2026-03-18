import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/app/providers/form_factor_provider.dart';
import '/core/environment/app_environment_config.dart';

class EnvironmentBanner extends ConsumerWidget {
  const EnvironmentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = AppEnvironmentConfig.current;
    if (!config.showDemoBanner) {
      return const SizedBox.shrink();
    }

    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;
    final location = isDesktop
        ? BannerLocation.bottomEnd
        : BannerLocation.topStart;

    return IgnorePointer(
      child: SafeArea(
        child: Banner(
          message: 'DEMO',
          location: location,
          color: Colors.red,
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
