import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/google_oauth2_client.dart';

import '../config/google_oauth_config.dart';

/// Excepción del flujo OAuth para Google Calendar.
class GoogleOAuthException implements Exception {
  final String message;
  GoogleOAuthException(this.message);
  @override
  String toString() => message;
}

/// Resultado de una autorización exitosa.
class GoogleOAuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiry;

  const GoogleOAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiry,
  });
}

/// Servicio único responsable de obtener, refrescar y revocar credenciales
/// de Google Calendar.
///
/// A diferencia de `google_sign_in` (que usa Credential Manager y no entrega
/// `refresh_token`), este servicio usa el flujo OAuth 2.0 estándar con
/// `access_type=offline`. El usuario consiente UNA vez en una pestaña de
/// Chrome y la app guarda el `refresh_token` en el almacenamiento seguro;
/// a partir de ese momento renovamos el `access_token` infinitas veces sin
/// mostrar UI alguna mediante el endpoint `oauth2.googleapis.com/token`.
///
/// La persistencia es total mientras Google no revoque el grant (lo cual
/// solo ocurre si el usuario desconecta explícitamente o tras un periodo
/// muy largo de inactividad — meses).
class GoogleOAuthService {
  static final _client = GoogleOAuth2Client(
    redirectUri: GoogleOAuthConfig.redirectUri,
    customUriScheme: GoogleOAuthConfig.redirectScheme,
  );

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Prefijo para las claves de refresh_token en el storage seguro.
  /// Indexado por email para soportar multi-cuenta.
  static const _refreshTokenPrefix = 'gcal_refresh_token_';

  void _assertConfigured() {
    if (!GoogleOAuthConfig.isConfigured) {
      throw GoogleOAuthException(
        'Falta configurar el Web Client ID de OAuth en '
        'lib/config/google_oauth_config.dart. Ver instrucciones en el archivo.',
      );
    }
  }

  /// Lanza el flujo de consentimiento del usuario.
  ///
  /// Abre Chrome Custom Tabs, lleva al usuario a la pantalla de consentimiento
  /// de Google con `access_type=offline`, y al volver intercambia el código
  /// por un par `(access_token, refresh_token)`.
  ///
  /// [isFirstTime] controla el parámetro `prompt`:
  /// - `true` (primera conexión): `prompt=consent` para que Google entregue
  ///   un `refresh_token` garantizado, incluso si el usuario ya autorizó.
  /// - `false` (reconexión con refresh_token previo): `prompt=select_account`
  ///   muestra sólo el selector de cuenta, sin el aviso de "app no verificada".
  ///
  /// Devuelve `null` si el usuario cancela el flujo.
  Future<GoogleOAuthSession?> authorize({bool isFirstTime = true}) async {
    _assertConfigured();
    try {
      final response = await _client.getTokenWithAuthCodeFlow(
        clientId: GoogleOAuthConfig.androidClientId,
        scopes: GoogleOAuthConfig.scopes,
        authCodeParams: {
          'access_type': 'offline',
          'prompt': isFirstTime ? 'consent' : 'select_account',
        },
      );

      if (!response.isValid()) {
        if (response.error == 'access_denied') return null;
        throw GoogleOAuthException(
          'Autorización rechazada por Google: ${response.error}',
        );
      }

      final accessToken = response.accessToken;
      final refreshToken = response.refreshToken;
      if (accessToken == null || refreshToken == null) {
        throw GoogleOAuthException(
          'Google no entregó refresh_token. Revisa que el Client ID sea de '
          'tipo "Web application" y que access_type=offline esté presente.',
        );
      }

      return GoogleOAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiry: _expiryFromResponse(response),
      );
    } on GoogleOAuthException {
      rethrow;
    } catch (e) {
      throw GoogleOAuthException('Error en el flujo OAuth: $e');
    }
  }

  /// Renueva el `access_token` de forma totalmente silenciosa usando un
  /// `refresh_token` previamente almacenado. No muestra UI bajo ninguna
  /// circunstancia.
  ///
  /// Devuelve `null` si Google rechaza el refresh_token (revocado por el
  /// usuario, expirado por inactividad de meses, etc.). En ese caso la UI
  /// debe pedir al usuario que vuelva a autorizar.
  Future<GoogleOAuthSession?> refresh(String refreshToken) async {
    _assertConfigured();
    try {
      final response = await _client.refreshToken(
        refreshToken,
        clientId: GoogleOAuthConfig.androidClientId,
      );
      if (!response.isValid()) return null;
      final accessToken = response.accessToken;
      if (accessToken == null) return null;
      // Google a veces devuelve un refresh_token nuevo, a veces no. Si lo
      // entrega, lo usamos; si no, conservamos el anterior.
      final newRefreshToken = response.refreshToken ?? refreshToken;
      return GoogleOAuthSession(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        expiry: _expiryFromResponse(response),
      );
    } catch (e) {
      debugPrint('[GoogleOAuthService] refresh failed: $e');
      return null;
    }
  }

  /// Revoca un refresh_token en Google. Llamado al desconectar la cuenta.
  /// Tras esto, el siguiente `refresh()` fallará y el usuario tendrá que
  /// volver a autorizar.
  Future<void> revoke(String refreshToken) async {
    try {
      await _client.revokeToken(
        AccessTokenResponse.fromMap({
          'refresh_token': refreshToken,
          'token_type': 'Bearer',
          'http_status_code': 200,
        }),
        clientId: GoogleOAuthConfig.androidClientId,
      );
    } catch (e) {
      debugPrint('[GoogleOAuthService] revoke failed (ignored): $e');
    }
  }

  /// Persiste un refresh_token cifrado para [email].
  Future<void> storeRefreshToken(String email, String refreshToken) async {
    await _storage.write(
      key: '$_refreshTokenPrefix${email.toLowerCase()}',
      value: refreshToken,
    );
  }

  /// Recupera el refresh_token cifrado de [email], o `null` si no existe.
  Future<String?> readRefreshToken(String email) async {
    return _storage.read(
      key: '$_refreshTokenPrefix${email.toLowerCase()}',
    );
  }

  /// Elimina el refresh_token de [email] del almacenamiento seguro.
  Future<void> deleteRefreshToken(String email) async {
    await _storage.delete(
      key: '$_refreshTokenPrefix${email.toLowerCase()}',
    );
  }

  /// Borra TODOS los refresh_tokens guardados (todas las cuentas).
  Future<void> deleteAllRefreshTokens() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_refreshTokenPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }

  DateTime _expiryFromResponse(AccessTokenResponse response) {
    final seconds = response.expiresIn ?? 3600;
    // Margen de seguridad de 5 minutos para evitar usar tokens al borde
    // de caducar y recibir 401 inesperados.
    return DateTime.now().add(Duration(seconds: seconds - 300));
  }
}
