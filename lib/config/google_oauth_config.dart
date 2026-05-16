/// Configuración del flujo OAuth 2.0 para Google Calendar API.
///
/// Pasos en Google Cloud Console:
///   1. Activa "Google Calendar API" en tu proyecto.
///   2. APIs & Services → Credentials → Create Credentials → OAuth Client ID
///   3. Tipo: "Web application"
///   4. Authorized redirect URIs: añade `com.notova.notova:/oauth2redirect`
///   5. Copia el Client ID generado y pégalo en [webClientId] aquí abajo.
///
/// El client_secret NO es necesario para el flujo PKCE en apps instaladas
/// (Android), pero si tu Web Client lo entrega también, oauth2_client lo
/// gestiona automáticamente.
class GoogleOAuthConfig {
  /// OAuth 2.0 Web Client ID. Sustituir por el real antes de compilar.
  /// El ID de cliente de Android (Notova Android)
  static const String androidClientId =
      '925903473414-pnhi2vak19t2kigbr6sohdpunpuc7754.apps.googleusercontent.com';

  /// Custom URI scheme registrado en `AndroidManifest.xml`.
  /// Usamos el scheme generado por Google Console para el cliente de iOS.
  static const String redirectScheme = 'com.googleusercontent.apps.925903473414-pnhi2vak19t2kigbr6sohdpunpuc7754';

  /// URI completa de redirección.
  static const String redirectUri = '$redirectScheme:/oauth2redirect';

  /// Scopes solicitados. `calendar` ya incluye lectura/escritura de eventos,
  /// por lo que `calendar.events` es redundante y se omite para reducir
  /// la superficie de permisos mostrada en el consentimiento de Google.
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  /// Indica si la config está completa. Si no, la app fallará con un
  /// mensaje claro en vez de intentar autenticar con un client id falso.
  static bool get isConfigured => true;
}
