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

  ApiClient({
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _http = httpClient ?? http.Client();

  // ── Token automático ────────────────────────────────────────────────────

  /// Obtiene el Firebase ID Token del usuario actualmente logueado.
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

  // ── Métodos HTTP ────────────────────────────────────────────────────────

  /// GET autenticado. Lanza [ApiException] si la respuesta no es 2xx.
  Future<ApiResponse> get(String path) async {
    final headers = await _authHeaders();
    final response = await _http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  /// POST autenticado con body JSON.
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await _http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT autenticado con body JSON.
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final response = await _http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// DELETE autenticado.
  Future<ApiResponse> delete(String path) async {
    final headers = await _authHeaders();
    final response = await _http.delete(Uri.parse('$baseUrl$path'), headers: headers);
    return _handleResponse(response);
  }

  // ── Respuesta ───────────────────────────────────────────────────────────

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

/// Respuesta tipada de la API.
class ApiResponse {
  final int statusCode;
  final String body;

  const ApiResponse({required this.statusCode, required this.body});

  bool get isOk => statusCode >= 200 && statusCode < 300;

  /// Parsea el body como JSON Map.
  Map<String, dynamic> get json =>
      jsonDecode(body) as Map<String, dynamic>;

  /// Parsea el body como JSON List.
  List<dynamic> get jsonList => jsonDecode(body) as List<dynamic>;
}

/// Error lanzado cuando no hay sesión activa.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
