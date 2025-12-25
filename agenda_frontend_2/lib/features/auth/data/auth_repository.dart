import '../../../core/models/user.dart';

/// Repository per l'autenticazione (Mock API)
class AuthRepository {
  // Simula utente salvato
  User? _currentUser;

  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock: accetta qualsiasi email/password valida
    if (email.isEmpty || password.length < 6) {
      throw Exception('Credenziali non valide');
    }

    _currentUser = User(
      id: 1,
      email: email,
      firstName: 'Mario',
      lastName: 'Rossi',
      phone: '+39 333 1234567',
      createdAt: DateTime.now(),
    );

    return _currentUser!;
  }

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Mock: crea utente
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      createdAt: DateTime.now(),
    );

    return _currentUser!;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock: simula invio email
  }
}
