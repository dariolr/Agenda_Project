import 'package:agenda_frontend/core/environment/app_environment.dart';
import 'package:agenda_frontend/core/environment/app_environment_config.dart';
import 'package:agenda_frontend/core/environment/environment_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EnvironmentPolicy mirrors config', () {
    const config = AppEnvironmentConfig(
      environment: AppEnvironment.demo,
      environmentName: 'demo',
      apiBaseUrl: 'https://demo-api.romeolab.it',
      webBaseUrl: 'https://demo-prenota.romeolab.it',
      isLocal: false,
      isDemo: true,
      isStaging: false,
      isProduction: false,
      showDemoBanner: true,
      demoResetExpected: true,
      demoAutoLoginEnabled: false,
      allowRealPayments: false,
      allowExternalWebhooks: false,
      allowRealExports: false,
    );

    const policy = EnvironmentPolicy(config);

    expect(policy.isDemoEnvironment(), isTrue);
    expect(policy.canUseRealPayments(), isFalse);
    expect(policy.canCallExternalWebhooks(), isFalse);
    expect(policy.canRunRealExports(), isFalse);
  });
}
