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

  // ========== CUSTOMER AUTH ENDPOINTS ==========
  // Usati dal frontend prenotazioni (agenda_frontend)
  // I clienti usano la tabella 'clients', non 'users'

  /// POST /v1/customer/{business_id}/auth/login
  static String customerLogin(int businessId) =>
      '/v1/customer/$businessId/auth/login';

  /// POST /v1/customer/{business_id}/auth/register
  static String customerRegister(int businessId) =>
      '/v1/customer/$businessId/auth/register';

  /// POST /v1/customer/{business_id}/auth/refresh
  static String customerRefresh(int businessId) =>
      '/v1/customer/$businessId/auth/refresh';

  /// POST /v1/customer/{business_id}/auth/logout
  static String customerLogout(int businessId) =>
      '/v1/customer/$businessId/auth/logout';

  /// GET /v1/customer/me
  static const String customerMe = '/v1/customer/me';

  /// GET /v1/customer/bookings
  static const String customerBookings = '/v1/customer/bookings';

  /// POST /v1/customer/{business_id}/bookings
  static String customerCreateBooking(int businessId) =>
      '/v1/customer/$businessId/bookings';

  // ========== LEGACY AUTH ENDPOINTS (DEPRECATI per frontend) ==========
  // Questi sono per OPERATORI (gestionale), non per clienti
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

  // ========== BOOKINGS ENDPOINTS (legacy, per operatori) ==========
  static String bookings(int locationId) =>
      '/v1/locations/$locationId/bookings';
}
