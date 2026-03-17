import 'package:agenda_backend/core/environment/app_environment.dart';
import 'package:agenda_backend/core/environment/app_environment_config.dart';
import 'package:agenda_backend/core/environment/environment_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EnvironmentPolicy mirrors config capabilities', () {
    const config = AppEnvironmentConfig(
      environment: AppEnvironment.demo,
      environmentName: 'demo',
      apiBaseUrl: 'https://demo-api.romeolab.it',
      webBaseUrl: 'https://demo-gestionale.romeolab.it',
      isLocal: false,
      isDemo: true,
      isProduction: false,
      showDemoBanner: true,
      allowRealEmails: false,
      allowRealWhatsapp: false,
      allowRealPayments: false,
      allowExternalWebhooks: false,
      allowDestructiveBusinessActions: false,
      allowPlanChanges: false,
      allowRealExports: false,
      demoResetExpected: true,
      demoAutoLoginEnabled: false,
    );

    final policy = EnvironmentPolicy(config);

    expect(policy.isDemoEnvironment(), isTrue);
    expect(policy.canSendRealEmails(), isFalse);
    expect(policy.canSendRealWhatsapp(), isFalse);
    expect(policy.canUseRealPayments(), isFalse);
    expect(policy.canExecuteDestructiveBusinessActions(), isFalse);
    expect(policy.canChangeSubscriptionPlan(), isFalse);
    expect(policy.canCallExternalWebhooks(), isFalse);
    expect(policy.canRunRealNotifications(), isFalse);
    expect(policy.canRunRealExports(), isFalse);
  });
}
