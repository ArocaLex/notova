import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP centralizado para la API REST de Notova (PythonAnywhere).
///
/// Gestiona automáticamente la autenticación: obtiene el Firebase ID Token
/// del usuario ya logueado en la app y lo inyecta como Bearer token en cada
/// petición. Los repositorios que necesiten llamar a la API solo hacen:
///
/// ```dart
/// final api = ApiClient();
/// final response = await api.get('/tareas');
/// final response = await api.post('/exportar/csv', body: {...});
/// ```
///
class ApiClient {
  final FirebaseAuth _auth;
  final http.Client _http;

  /// URL base del microservicio REST desplegado en PythonAnywhere.
  static const baseUrl = 'https://arocaalex.pythonanywhere.com';

  /// Crea un cliente API con instancias opcionales de [FirebaseAuth] y
  /// [http.Client] para facilitar la inyección en tests.
  ApiClient({
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _http = httpClient ?? http.Client();

  /// Obtiene el Firebase ID Token del usuario actualmente logueado.
  ///
  /// Retorna `null` si no hay sesión activa.
  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Construye los headers con el Bearer token automáticamente.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _getIdToken();
    if (token == null) {
      throw ApiException(401, 'No hay sesión activa — inicia sesión primero.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Realiza una petición GET autenticada.
  ///
  /// Si no hay sesión activa, lanza [ApiException]. Para errores HTTP (4xx/5xx)
  /// devuelve igualmente un [ApiResponse] con [ApiResponse.isOk] en `false`.
  Future<ApiResponse> get(String path) async {
    final headers = await _authHeaders();
    final response = await _http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  /// Realiza una petición POST autenticada con cuerpo JSON opcional.
  ///
  /// Si no hay sesión activa, lanza [ApiException]. Para errores HTTP (4xx/5xx)
  /// devuelve igualmente un [ApiResponse] con [ApiResponse.isOk] en `false`.
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await _http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Realiza una petición PUT autenticada con cuerpo JSON opcional.
  ///
  /// Si no hay sesión activa, lanza [ApiException]. Para errores HTTP (4xx/5xx)
  /// devuelve igualmente un [ApiResponse] con [ApiResponse.isOk] en `false`.
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await _http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Realiza una petición DELETE autenticada.
  ///
  /// Si no hay sesión activa, lanza [ApiException]. Para errores HTTP (4xx/5xx)
  /// devuelve igualmente un [ApiResponse] con [ApiResponse.isOk] en `false`.
  Future<ApiResponse> delete(String path) async {
    final headers = await _authHeaders();
    final response = await _http.delete(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  /// Procesa la respuesta HTTP y la encapsula en un [ApiResponse].
  ApiResponse _handleResponse(http.Response response) {
    final apiResponse = ApiResponse(
      statusCode: response.statusCode,
      body: response.body,
    );

    if (response.statusCode >= 400) {
      debugPrint('[API] Error ${response.statusCode}: ${response.body}');
    }

    return apiResponse;
  }
}

/// Respuesta tipada devuelta por [ApiClient] tras cada petición HTTP.
class ApiResponse {
  /// Código de estado HTTP de la respuesta.
  final int statusCode;

  /// Cuerpo de la respuesta como texto plano.
  final String body;

  const ApiResponse({required this.statusCode, required this.body});

  /// Indica si la respuesta tiene un código de estado exitoso (2xx).
  bool get isOk => statusCode >= 200 && statusCode < 300;

  /// Decodifica el cuerpo de la respuesta como un mapa JSON.
  Map<String, dynamic> get json =>
      jsonDecode(body) as Map<String, dynamic>;

  /// Decodifica el cuerpo de la respuesta como una lista JSON.
  List<dynamic> get jsonList => jsonDecode(body) as List<dynamic>;
}

/// Excepción lanzada por [ApiClient] cuando no hay sesión activa o la
/// respuesta indica un error HTTP.
class ApiException implements Exception {
  /// Código de estado HTTP asociado al error.
  final int statusCode;

  /// Mensaje descriptivo del error.
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
