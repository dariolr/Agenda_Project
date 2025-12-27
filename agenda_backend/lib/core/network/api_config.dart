/// Configurazione API per agenda_backend (gestionale)
class ApiConfig {
  /// Base URL dell'API - configurabile via environment
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8888/agenda_core/public',
  );

  /// Location ID di default (per MVP single-location)
  static const int defaultLocationId = 1;

  /// Business ID di default
  static const int defaultBusinessId = 1;

  /// Timeout per le richieste
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ========== AUTH ENDPOINTS ==========
  static const String authLogin = '/v1/auth/login';
  static const String authRegister = '/v1/auth/register';
  static const String authRefresh = '/v1/auth/refresh';
  static const String authLogout = '/v1/auth/logout';
  static const String authForgotPassword = '/v1/auth/forgot-password';
  static const String authResetPassword = '/v1/auth/reset-password';
  static const String authMe = '/v1/me';

  // ========== PUBLIC BROWSE ENDPOINTS ==========
  static const String services = '/v1/services';
  static const String staff = '/v1/staff';
  static const String availability = '/v1/availability';

  // ========== GESTIONALE ENDPOINTS ==========
  static const String clients = '/v1/clients';

  /// Appointments endpoint con location_id nel path
  static String appointments(int locationId) =>
      '/v1/locations/$locationId/appointments';

  /// Singolo appointment endpoint
  static String appointment(int locationId, int appointmentId) =>
      '/v1/locations/$locationId/appointments/$appointmentId';

  /// Cancel appointment endpoint
  static String appointmentCancel(int locationId, int appointmentId) =>
      '/v1/locations/$locationId/appointments/$appointmentId/cancel';

  /// Bookings endpoint con location_id nel path
  static String bookings(int locationId) =>
      '/v1/locations/$locationId/bookings';

  /// Singolo booking endpoint
  static String booking(int locationId, int bookingId) =>
      '/v1/locations/$locationId/bookings/$bookingId';
}
