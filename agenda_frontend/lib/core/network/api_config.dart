/// Configurazione API
class ApiConfig {
  /// Base URL dell'API - configurabile via environment
  /// Default: produzione (https://api.romeolab.it)
  /// Dev locale: --dart-define=API_BASE_URL=http://localhost:8888/agenda_core/public
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.romeolab.it',
  );

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

  /// POST /v1/customer/{business_id}/auth/forgot-password
  static String customerForgotPassword(int businessId) =>
      '/v1/customer/$businessId/auth/forgot-password';

  /// POST /v1/customer/auth/reset-password
  static const String customerResetPassword =
      '/v1/customer/auth/reset-password';

  /// GET /v1/customer/me
  static const String customerMe = '/v1/customer/me';

  /// PUT /v1/customer/me - Aggiorna profilo cliente
  static const String customerUpdateProfile = '/v1/customer/me';

  /// POST /v1/customer/me/change-password
  static const String customerChangePassword =
      '/v1/customer/me/change-password';

  /// GET /v1/customer/bookings
  static const String customerBookings = '/v1/customer/bookings';

  /// PUT /v1/customer/bookings/{booking_id}
  static String customerUpdateBooking(int bookingId) =>
      '/v1/customer/bookings/$bookingId';

  /// DELETE /v1/customer/bookings/{booking_id}
  static String customerDeleteBooking(int bookingId) =>
      '/v1/customer/bookings/$bookingId';

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

  // ========== STAFF PLANNING ENDPOINTS (read-only) ==========
  /// GET /v1/staff/{id}/plannings - tutti i planning per uno staff
  static String staffPlannings(int staffId) => '/v1/staff/$staffId/plannings';

  /// GET /v1/staff/{id}/planning?date=YYYY-MM-DD - planning valido per data
  static String staffPlanningForDate(int staffId) =>
      '/v1/staff/$staffId/planning';

  /// GET /v1/staff/{id}/planning-availability?date=YYYY-MM-DD - slot disponibili per data
  static String staffPlanningAvailability(int staffId) =>
      '/v1/staff/$staffId/planning-availability';

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
