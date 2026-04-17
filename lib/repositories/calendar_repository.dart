import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';

/// Error amigable que el ViewModel/UI puede mostrar directamente al usuario
/// sin tener que parsear trazas o códigos.
class CalendarException implements Exception {
  final String message;
  CalendarException(this.message);

  @override
  String toString() => message;
}

/// Thin HTTP client that injects the Google OAuth Bearer token on every request.
class _AuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _AuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
}

class CalendarRepository {
  // v7 usa una única instancia de GoogleSignIn compartida con AuthRepository.
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  /// Paleta de colores para asignar aleatoriamente a cada cuenta conectada.
  static const List<Color> _accountPalette = [
    Color(0xFF7B2CBF), // morado Notova
    Color(0xFF2D5AF7), // azul
    Color(0xFFE91E63), // rosa
    Color(0xFF00BFA5), // verde agua
    Color(0xFFFF7043), // naranja
    Color(0xFF26C6DA), // cyan
    Color(0xFFAB47BC), // violeta
    Color(0xFFFFB300), // amarillo
  ];

  final _rand = Random();

  Color _pickColor(Set<int> used) {
    // Intenta no repetir color si hay disponibles.
    final unused = <int>[];
    for (var i = 0; i < _accountPalette.length; i++) {
      if (!used.contains(i)) unused.add(i);
    }
    final idx = unused.isNotEmpty
        ? unused[_rand.nextInt(unused.length)]
        : _rand.nextInt(_accountPalette.length);
    used.add(idx);
    return _accountPalette[idx];
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  /// Inicia sesión con Google y devuelve una nueva [CalendarAccount] cargada
  /// con la lista de calendarios y un color aleatorio de la paleta.
  ///
  /// [usedColorIndices] se pasa para evitar repetir colores cuando ya hay
  /// otras cuentas conectadas.
  Future<CalendarAccount> connectAccount({
    required Set<int> usedColorIndices,
  }) async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate(
        scopeHint: const [gcal.CalendarApi.calendarScope],
      );
    } on GoogleSignInException catch (e) {
      throw CalendarException(_friendlyAuthError(e));
    } catch (_) {
      throw CalendarException('No se pudo iniciar sesión con Google.');
    }

    // authorizationForScopes sólo devuelve tokens YA concedidos. La primera
    // vez que el usuario añade Calendar todavía no hay autorización, así que
    // hay que caer en authorizeScopes() para disparar el prompt interactivo.
    final GoogleSignInClientAuthorization auth;
    try {
      final existing = await account.authorizationClient
          .authorizationForScopes([gcal.CalendarApi.calendarScope]);
      auth = existing ??
          await account.authorizationClient
              .authorizeScopes([gcal.CalendarApi.calendarScope]);
    } on GoogleSignInException catch (e) {
      throw CalendarException(_friendlyAuthError(e));
    } catch (_) {
      throw CalendarException(
          'No se pudo obtener permiso para Google Calendar.');
    }

    final color = _pickColor(usedColorIndices);

    // Descargamos la lista de calendarios inmediatamente.
    final calendars = await _fetchCalendars(
      accessToken: auth.accessToken,
      email: account.email,
    );

    return CalendarAccount(
      email: account.email,
      color: color,
      accessToken: auth.accessToken,
      calendars: calendars,
      // google_sign_in v7 no expone expiry del access token; asumimos 55 min.
      tokenExpiry: DateTime.now().add(const Duration(minutes: 55)),
    );
  }

  /// Desconecta todas las cuentas. Ignora errores (por ejemplo si la sesión
  /// ya había caducado, o el usuario ya había revocado el permiso).
  Future<void> disconnectAll() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Silenciado intencionalmente: disconnect puede fallar si la sesión
      // no existe; el usuario no necesita ver una excepción por eso.
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Intenta restaurar de forma SILENCIOSA (sin diálogos) una sesión de
  /// Google previa. Devuelve la cuenta autenticada y un access token válido,
  /// o `null` si no hay sesión recuperable.
  ///
  /// Se usa al arrancar la app para refrescar el token de una de las cuentas
  /// previamente persistidas en SQLite. NO dispara UI.
  Future<({String email, String accessToken, DateTime expiry})?>
      attemptSilentRestore() async {
    try {
      await _ensureInitialized();
      final acc = await _googleSignIn.attemptLightweightAuthentication();
      if (acc == null) return null;
      final auth = await acc.authorizationClient
          .authorizationForScopes([gcal.CalendarApi.calendarScope]);
      if (auth == null) return null;
      return (
        email: acc.email,
        accessToken: auth.accessToken,
        expiry: DateTime.now().add(const Duration(minutes: 55)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Refresca el access token de una cuenta concreta. Si el usuario cerró
  /// sesión en Google mientras tanto, devuelve null y el llamante debe
  /// pedirle que reconecte.
  Future<String?> refreshToken(CalendarAccount account) async {
    try {
      // Con google_sign_in v7 no se puede refrescar un token de una cuenta
      // que ya no es la activa. La única forma fiable es reautenticar.
      await _ensureInitialized();
      final current = await _googleSignIn.authenticate();
      if (current.email.toLowerCase() != account.email.toLowerCase()) {
        return null;
      }
      final existing = await current.authorizationClient
          .authorizationForScopes([gcal.CalendarApi.calendarScope]);
      final auth = existing ??
          await current.authorizationClient
              .authorizeScopes([gcal.CalendarApi.calendarScope]);
      account.accessToken = auth.accessToken;
      account.tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  // ── Calendarios ───────────────────────────────────────────────────────────

  Future<List<CalendarInfo>> _fetchCalendars({
    required String accessToken,
    required String email,
  }) async {
    final api = gcal.CalendarApi(_AuthClient(accessToken));
    final result = await api.calendarList.list();
    return (result.items ?? [])
        .map((item) => CalendarInfo(
              id: item.id ?? '',
              summary: item.summary ?? 'Calendario',
              backgroundColor: item.backgroundColor,
              accessRole: item.accessRole ?? 'reader',
              accountEmail: email,
            ))
        .toList();
  }

  /// Recarga la lista de calendarios de una cuenta (por ejemplo al refrescar).
  Future<List<CalendarInfo>> fetchCalendarList(CalendarAccount account) async {
    try {
      return await _fetchCalendars(
        accessToken: account.accessToken,
        email: account.email,
      );
    } catch (e) {
      throw CalendarException(
          'No se pudieron cargar los calendarios de ${account.email}.');
    }
  }

  // ── Events ────────────────────────────────────────────────────────────────

  /// Asegura que el token de la cuenta está vigente; si no, lo refresca.
  Future<void> _ensureValidToken(CalendarAccount account) async {
    if (account.isTokenExpired) {
      await refreshToken(account);
    }
  }

  /// Devuelve los eventos de [date] para TODOS los calendarios visibles
  /// entre todas las cuentas conectadas.
  Future<List<CalendarEvent>> fetchEventsForDate(
    List<CalendarAccount> accounts,
    DateTime date,
  ) async {
    final events = <CalendarEvent>[];
    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    for (final account in accounts) {
      await _ensureValidToken(account);
      final api = gcal.CalendarApi(_AuthClient(account.accessToken));
      for (final cal in account.calendars.where((c) => c.isVisible)) {
        try {
          final result = await api.events.list(
            cal.id,
            timeMin: dayStart,
            timeMax: dayEnd,
            singleEvents: true,
            orderBy: 'startTime',
          );
          events.addAll(
            (result.items ?? []).map(
              (e) => CalendarEvent.fromGoogleEvent(
                e,
                cal.id,
                account.email,
                cal.isOwned,
              ),
            ),
          );
        } catch (_) {
          // Saltar calendarios inaccesibles sin romper el resto.
        }
      }
    }

    events.sort((a, b) {
      if (a.start == null) return 1;
      if (b.start == null) return -1;
      return a.start!.compareTo(b.start!);
    });
    return events;
  }

  /// Devuelve los días del mes que tienen al menos un evento, mapeados al
  /// color de la cuenta propietaria. Si varios calendarios coinciden, el
  /// color del primero gana. Para el pintado como "puntitos".
  Future<Map<int, List<Color>>> fetchEventDaysForMonth(
    List<CalendarAccount> accounts,
    DateTime month,
  ) async {
    final monthStart = DateTime(month.year, month.month, 1).toUtc();
    final monthEnd = DateTime(month.year, month.month + 1, 1).toUtc();
    final result = <int, List<Color>>{};

    for (final account in accounts) {
      await _ensureValidToken(account);
      final api = gcal.CalendarApi(_AuthClient(account.accessToken));
      for (final cal in account.calendars.where((c) => c.isVisible)) {
        try {
          final res = await api.events.list(
            cal.id,
            timeMin: monthStart,
            timeMax: monthEnd,
            singleEvents: true,
            orderBy: 'startTime',
          );
          for (final e in res.items ?? []) {
            final start = e.start?.dateTime?.toLocal() ??
                (e.start?.date != null
                    ? DateTime.tryParse(e.start!.date.toString())
                    : null);
            if (start == null) continue;
            if (start.month != month.month || start.year != month.year) {
              continue;
            }
            final list = result.putIfAbsent(start.day, () => <Color>[]);
            if (!list.contains(account.color)) {
              list.add(account.color);
            }
          }
        } catch (_) {}
      }
    }
    return result;
  }

  /// Crea un evento. Usa la primera cuenta cuyo calendario coincida con
  /// [calendarId]. Caller MUST verify [CalendarInfo.isOwned].
  Future<void> createEvent({
    required List<CalendarAccount> accounts,
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final account = _accountForCalendar(accounts, calendarId);
    if (account == null) {
      throw CalendarException('Calendario no encontrado.');
    }
    final api = gcal.CalendarApi(_AuthClient(account.accessToken));
    try {
      await api.events.insert(
        gcal.Event(
          summary: title,
          start: gcal.EventDateTime(dateTime: start.toUtc()),
          end: gcal.EventDateTime(dateTime: end.toUtc()),
        ),
        calendarId,
      );
    } catch (_) {
      throw CalendarException('No se pudo crear el evento.');
    }
  }

  Future<void> deleteEvent({
    required List<CalendarAccount> accounts,
    required String calendarId,
    required String eventId,
  }) async {
    final account = _accountForCalendar(accounts, calendarId);
    if (account == null) {
      throw CalendarException('Calendario no encontrado.');
    }
    final api = gcal.CalendarApi(_AuthClient(account.accessToken));
    try {
      await api.events.delete(calendarId, eventId);
    } catch (_) {
      throw CalendarException('No se pudo eliminar el evento.');
    }
  }

  CalendarAccount? _accountForCalendar(
    List<CalendarAccount> accounts,
    String calendarId,
  ) {
    for (final a in accounts) {
      if (a.calendars.any((c) => c.id == calendarId)) return a;
    }
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _friendlyAuthError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Has cancelado la conexión con Google.';
      case GoogleSignInExceptionCode.interrupted:
        return 'La conexión con Google se interrumpió. Revisa tu red.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'La app no está configurada correctamente para Google Sign-In.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Error de configuración del proveedor de Google.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'No se puede mostrar el diálogo de inicio de sesión ahora.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'La cuenta elegida no coincide con la esperada.';
      default:
        return 'No se pudo iniciar sesión con Google.';
    }
  }
}
