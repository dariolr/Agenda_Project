/// Configurazione API
class ApiConfig {
  /// Base URL dell'API - configurabile via environment
  /// Default: produzione (https://api.romeolab.it)
  /// Dev locale: --dart-define=API_BASE_URL=http://localhost:8888/agenda_core/public
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.romeolab.it',
  );

  /// Location ID di default (per MVP single-location)
  static const int defaultLocationId = 1;

  /// Timeout per le richieste (ridotti per risposta rapida)
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // ========== AUTH ENDPOINTS ==========
  static const String authLogin = '/v1/auth/login';
  static const String authRegister = '/v1/auth/register';
  static const String authRefresh = '/v1/auth/refresh';
  static const String authLogout = '/v1/auth/logout';
  static const String authForgotPassword = '/v1/auth/forgot-password';
  static const String authResetPassword = '/v1/auth/reset-password';
  static const String authMe = '/v1/me';
  static const String meChangePassword = '/v1/me/change-password';
  static const String meBookings = '/v1/me/bookings';

  // ========== PUBLIC BROWSE ENDPOINTS ==========
  static const String services = '/v1/services';
  static const String staff = '/v1/staff';
  static const String availability = '/v1/availability';

  // ========== BUSINESS ENDPOINTS ==========
  /// Get business by slug (public, no auth required)
  static String businessBySlug(String slug) => '/v1/businesses/by-slug/$slug';

  /// Get locations for a business (public, no auth required)
  static String businessLocations(int businessId) =>
      '/v1/businesses/$businessId/locations/public';

  // ========== BOOKINGS ENDPOINTS ==========
  static String bookings(int locationId) =>
      '/v1/locations/$locationId/bookings';
}
