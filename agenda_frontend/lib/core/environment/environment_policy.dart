import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment_config.dart';

class EnvironmentPolicy {
  const EnvironmentPolicy(this.config);

  final AppEnvironmentConfig config;

  bool isDemoEnvironment() => config.isDemo;
  bool canUseRealPayments() => config.allowRealPayments;
  bool canCallExternalWebhooks() => config.allowExternalWebhooks;
  bool canRunRealExports() => config.allowRealExports;
}

final appEnvironmentConfigProvider = Provider<AppEnvironmentConfig>((ref) {
  return AppEnvironmentConfig.current;
});

final environmentPolicyProvider = Provider<EnvironmentPolicy>((ref) {
  final config = ref.watch(appEnvironmentConfigProvider);
  return EnvironmentPolicy(config);
});
