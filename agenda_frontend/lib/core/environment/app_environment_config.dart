import 'package:flutter/foundation.dart';

import 'app_environment.dart';

@immutable
class AppEnvironmentRawConfig {
  const AppEnvironmentRawConfig({
    required this.appEnv,
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.demoMode,
    required this.showDemoBanner,
    required this.demoResetExpected,
    required this.demoAutoLoginEnabled,
    required this.allowRealPayments,
    required this.allowExternalWebhooks,
    required this.allowRealExports,
  });

  final String appEnv;
  final String apiBaseUrl;
  final String webBaseUrl;
  final bool? demoMode;
  final bool? showDemoBanner;
  final bool? demoResetExpected;
  final bool? demoAutoLoginEnabled;
  final bool? allowRealPayments;
  final bool? allowExternalWebhooks;
  final bool? allowRealExports;
}

@immutable
class AppEnvironmentConfig {
  const AppEnvironmentConfig({
    required this.environment,
    required this.environmentName,
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.isLocal,
    required this.isDemo,
    required this.isProduction,
    required this.showDemoBanner,
    required this.demoResetExpected,
    required this.demoAutoLoginEnabled,
    required this.allowRealPayments,
    required this.allowExternalWebhooks,
    required this.allowRealExports,
  });

  final AppEnvironment environment;
  final String environmentName;
  final String apiBaseUrl;
  final String webBaseUrl;

  final bool isLocal;
  final bool isDemo;
  final bool isProduction;

  final bool showDemoBanner;
  final bool demoResetExpected;
  final bool demoAutoLoginEnabled;
  final bool allowRealPayments;
  final bool allowExternalWebhooks;
  final bool allowRealExports;

  static late final AppEnvironmentConfig current;

  static void bootstrap() {
    current = fromRaw(_rawFromDefines);
  }

  static AppEnvironmentConfig fromRaw(AppEnvironmentRawConfig raw) {
    final environment = AppEnvironment.parse(raw.appEnv);

    final isDemo = environment == AppEnvironment.demo;
    final isProduction = environment == AppEnvironment.production;
    final isLocal = environment == AppEnvironment.local;

    final apiBaseUrl = raw.apiBaseUrl.trim();
    final webBaseUrl = raw.webBaseUrl.trim();

    _assertValidUrl('API_BASE_URL', apiBaseUrl);
    _assertValidUrl('WEB_BASE_URL', webBaseUrl);

    final resolvedDemoMode = raw.demoMode ?? isDemo;
    if (resolvedDemoMode != isDemo) {
      throw StateError(
        'Configurazione incoerente: APP_ENV=$environment ma DEMO_MODE=$resolvedDemoMode.',
      );
    }

    final showDemoBanner = raw.showDemoBanner ?? isDemo;
    final demoResetExpected = raw.demoResetExpected ?? isDemo;
    final demoAutoLoginEnabled = raw.demoAutoLoginEnabled ?? false;
    final allowRealPayments = raw.allowRealPayments ?? isProduction;
    final allowExternalWebhooks = raw.allowExternalWebhooks ?? isProduction;
    final allowRealExports = raw.allowRealExports ?? isProduction;

    if (isDemo) {
      if (allowRealPayments || allowExternalWebhooks || allowRealExports) {
        throw StateError(
          'Configurazione demo non sicura: i flag ALLOW_REAL_* sensibili devono essere false.',
        );
      }
      if (!showDemoBanner) {
        throw StateError(
          'Configurazione demo non sicura: SHOW_DEMO_BANNER deve essere true in demo.',
        );
      }
      if (apiBaseUrl == _defaultProductionApiBaseUrl) {
        throw StateError(
          'Configurazione demo non sicura: API demo non puo\' puntare a $_defaultProductionApiBaseUrl.',
        );
      }
    }

    return AppEnvironmentConfig(
      environment: environment,
      environmentName: environment.name,
      apiBaseUrl: apiBaseUrl,
      webBaseUrl: webBaseUrl,
      isLocal: isLocal,
      isDemo: isDemo,
      isProduction: isProduction,
      showDemoBanner: showDemoBanner,
      demoResetExpected: demoResetExpected,
      demoAutoLoginEnabled: demoAutoLoginEnabled,
      allowRealPayments: allowRealPayments,
      allowExternalWebhooks: allowExternalWebhooks,
      allowRealExports: allowRealExports,
    );
  }

  static void _assertValidUrl(String name, String value) {
    if (value.isEmpty) {
      throw StateError('$name mancante.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('$name non valido: "$value".');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw StateError('$name deve usare http/https: "$value".');
    }
  }

  static const String _defaultProductionApiBaseUrl = 'https://api.romeolab.it';

  static const AppEnvironmentRawConfig _rawFromDefines =
      AppEnvironmentRawConfig(
        appEnv: String.fromEnvironment('APP_ENV', defaultValue: 'production'),
        apiBaseUrl: String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: _defaultProductionApiBaseUrl,
        ),
        webBaseUrl: String.fromEnvironment(
          'WEB_BASE_URL',
          defaultValue: 'https://prenota.romeolab.it',
        ),
        demoMode: bool.hasEnvironment('DEMO_MODE')
            ? bool.fromEnvironment('DEMO_MODE')
            : null,
        showDemoBanner: bool.hasEnvironment('SHOW_DEMO_BANNER')
            ? bool.fromEnvironment('SHOW_DEMO_BANNER')
            : null,
        demoResetExpected: bool.hasEnvironment('DEMO_RESET_EXPECTED')
            ? bool.fromEnvironment('DEMO_RESET_EXPECTED')
            : null,
        demoAutoLoginEnabled: bool.hasEnvironment('DEMO_AUTO_LOGIN_ENABLED')
            ? bool.fromEnvironment('DEMO_AUTO_LOGIN_ENABLED')
            : null,
        allowRealPayments: bool.hasEnvironment('ALLOW_REAL_PAYMENTS')
            ? bool.fromEnvironment('ALLOW_REAL_PAYMENTS')
            : null,
        allowExternalWebhooks: bool.hasEnvironment('ALLOW_EXTERNAL_WEBHOOKS')
            ? bool.fromEnvironment('ALLOW_EXTERNAL_WEBHOOKS')
            : null,
        allowRealExports: bool.hasEnvironment('ALLOW_REAL_EXPORTS')
            ? bool.fromEnvironment('ALLOW_REAL_EXPORTS')
            : null,
      );
}
