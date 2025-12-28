# Token Storage Best Practices — Flutter Web

## Problema

Su Flutter Web, i token devono essere gestiti in modo sicuro:
- **Access token**: breve vita (15 min), può stare in memoria
- **Refresh token**: lunga vita (90 giorni), NON deve stare in localStorage

## Soluzione Implementata (agenda_frontend)

### 1. Access Token in Memoria

```dart
class TokenStorage {
  String? _accessToken;  // Solo in memoria
  
  String? getAccessToken() => _accessToken;
  
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
  void clear() {
    _accessToken = null;
  }
}
```

**Pro**: 
- Immune a XSS (non accessibile da JS)
- Cancellato automaticamente al refresh pagina

**Contro**:
- Richiede re-login ad ogni reload

---

### 2. Refresh Token in HttpOnly Cookie

**Server-side (agenda_core)** — AuthController.php:

```php
$response->setCookie(
    'refresh_token',
    $result['refresh_token'],
    [
        'httpOnly' => true,     // ✅ Non accessibile da JavaScript
        'secure' => true,       // ✅ Solo HTTPS
        'sameSite' => 'Strict', // ✅ Protezione CSRF
        'maxAge' => 90 * 24 * 60 * 60,
        'path' => '/v1/auth',   // ✅ Solo su endpoint auth
    ]
);
```

**Client-side (Flutter Web)**:

```dart
// Login
final response = await dio.post('/v1/auth/login', data: {...});
// Cookie refresh_token settato automaticamente dal browser

// Refresh automatico
final refreshResponse = await dio.post('/v1/auth/refresh');
// Cookie inviato automaticamente dal browser
```

**Pro**:
- Immune a XSS (cookie httpOnly)
- Immune a CSRF (sameSite=Strict)
- Persistent across reload

**Contro**:
- Richiede configurazione CORS corretta

---

### 3. Refresh Automatico su Reload

```dart
class AuthProvider extends StateNotifier<AuthState> {
  Future<void> init() async {
    try {
      // Prova a refresh usando cookie
      final response = await _apiClient.post('/v1/auth/refresh');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _tokenStorage.setAccessToken(data['access_token']);
        state = AuthState.authenticated(user: data['user']);
      }
    } catch (e) {
      // Cookie non valido o scaduto → logout
      state = AuthState.unauthenticated();
    }
  }
}
```

**Chiamata in main.dart**:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  await container.read(authProvider.notifier).init();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );
}
```

---

### 4. Interceptor per Auto-Refresh

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Access token scaduto, prova refresh
      try {
        final refreshResponse = await _dio.post('/v1/auth/refresh');
        
        if (refreshResponse.statusCode == 200) {
          final newAccessToken = refreshResponse.data['data']['access_token'];
          _tokenStorage.setAccessToken(newAccessToken);
          
          // Retry request originale
          final opts = Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newAccessToken',
            },
          );
          
          final response = await _dio.request(
            err.requestOptions.path,
            options: opts,
            data: err.requestOptions.data,
          );
          
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh fallito → logout
        _authProvider.logout();
      }
    }
    
    handler.next(err);
  }
}
```

---

## Configurazione CORS Server

**agenda_core — Nginx**:

```nginx
# Permettere credenziali (cookie)
add_header Access-Control-Allow-Credentials "true" always;

# Specificare origine esatta (NO wildcard con credentials)
add_header Access-Control-Allow-Origin "https://app.tuodominio.com" always;
```

**agenda_core — Headers controller** (se gestiti da PHP):

```php
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Origin: https://app.tuodominio.com');
```

---

## Checklist Implementazione

### Server (agenda_core)
- [ ] Refresh token settato come httpOnly cookie
- [ ] Cookie con `secure=true` (solo HTTPS)
- [ ] Cookie con `sameSite=Strict`
- [ ] Cookie path limitato a `/v1/auth`
- [ ] CORS Allow-Credentials: true
- [ ] CORS Allow-Origin specifico (NO *)

### Client (agenda_frontend)
- [ ] Access token solo in memoria (mai localStorage)
- [ ] Refresh token MAI toccato lato client (solo cookie)
- [ ] Init() chiama refresh al bootstrap
- [ ] Interceptor gestisce 401 con auto-refresh
- [ ] Logout pulisce access token memoria
- [ ] Dio configurato con `withCredentials: true`

---

## Codice Flutter Web

### ApiClient con credentials

```dart
class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.tuodominio.com',
      headers: {
        'Content-Type': 'application/json',
      },
      withCredentials: true,  // ✅ Invia cookie automaticamente
    ),
  );
  
  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  void clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }
}
```

### Login Flow

```dart
Future<void> login(String email, String password) async {
  final response = await _apiClient.post('/v1/auth/login', data: {
    'email': email,
    'password': password,
  });
  
  final data = response.data['data'];
  
  // Salva access token in memoria
  _tokenStorage.setAccessToken(data['access_token']);
  _apiClient.setAccessToken(data['access_token']);
  
  // Refresh token salvato automaticamente in cookie dal server
  
  state = AuthState.authenticated(user: data['user']);
}
```

### Logout Flow

```dart
Future<void> logout() async {
  try {
    await _apiClient.post('/v1/auth/logout');
  } catch (e) {
    // Ignora errori, cancella comunque stato locale
  }
  
  _tokenStorage.clear();
  _apiClient.clearAccessToken();
  
  // Cookie cancellato dal server (Set-Cookie con maxAge=0)
  
  state = AuthState.unauthenticated();
}
```

---

## Test

### 1. Login → Reload → Still Authenticated

```
1. Login
2. Access token in memoria
3. Refresh token in cookie
4. F5 (reload page)
5. init() chiama /v1/auth/refresh
6. Cookie inviato automaticamente
7. Nuovo access token in memoria
8. ✅ Authenticated
```

### 2. Logout → Reload → Not Authenticated

```
1. Logout
2. Cookie cancellato dal server
3. F5 (reload page)
4. init() chiama /v1/auth/refresh
5. 401 Unauthorized (no cookie)
6. ✅ Unauthenticated
```

### 3. API Call → 401 → Auto Refresh

```
1. API call con access token scaduto
2. 401 Unauthorized
3. Interceptor chiama /v1/auth/refresh
4. Cookie inviato automaticamente
5. Nuovo access token
6. Retry API call originale
7. ✅ Success
```

---

## Security Notes

**❌ MAI fare**:
- Salvare refresh token in localStorage (vulnerabile XSS)
- Usare CORS wildcard (*) con credentials
- Cookie senza httpOnly
- Cookie senza secure in produzione
- Cookie SameSite=None senza motivo valido

**✅ SEMPRE fare**:
- Refresh token in httpOnly cookie
- Access token in memoria (cancellato a reload)
- CORS origine specifica
- HTTPS obbligatorio in produzione
- SameSite=Strict per massima sicurezza
