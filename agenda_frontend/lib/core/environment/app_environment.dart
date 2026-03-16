enum AppEnvironment {
  local,
  demo,
  staging,
  production;

  static AppEnvironment parse(String value) {
    switch (value.trim().toLowerCase()) {
      case 'local':
        return AppEnvironment.local;
      case 'demo':
        return AppEnvironment.demo;
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        throw StateError(
          'APP_ENV non riconosciuto: "$value". Valori ammessi: local, demo, staging, production.',
        );
    }
  }
}
