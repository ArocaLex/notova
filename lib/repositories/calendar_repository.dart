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

/// Cliente HTTP que inyecta el token OAuth de Google en cada petición saliente.
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

/// Repositorio de acceso a Google Calendar para Notova.
///
/// Gestiona la autenticación OAuth, la obtención de calendarios y eventos, y
/// la creación y eliminación de eventos a través de la API de Google Calendar.
/// Utiliza [GoogleSignIn] de forma silenciosa cuando es posible o interactiva
/// cuando se requiere autorización inicial.
class CalendarRepository {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  /// Paleta de colores para asignar aleatoriamente a cada cuenta conectada.
  static const List<Color> _accountPalette = [
    Color(0xFF7B2CBF),
    Color(0xFF2D5AF7),
    Color(0xFFE91E63),
    Color(0xFF00BFA5),
    Color(0xFFFF7043),
    Color(0xFF26C6DA),
    Color(0xFFAB47BC),
    Color(0xFFFFB300),
  ];

  final _rand = Random();

  ({int index, Color color}) _pickColor(Set<int> used) {
    final unused = <int>[];
    for (var i = 0; i < _accountPalette.length; i++) {
      if (!used.contains(i)) unused.add(i);
    }
    final idx = unused.isNotEmpty
        ? unused[_rand.nextInt(unused.length)]
        : _rand.nextInt(_accountPalette.length);
    used.add(idx);
    return (index: idx, color: _accountPalette[idx]);
  }

  /// Inicia sesión con Google y devuelve una nueva [CalendarAccount] cargada
  /// con la lista de calendarios y un color aleatorio de la paleta.
  ///
  /// [usedColorIndices] se pasa para evitar repetir colores cuando ya hay
  /// otras cuentas conectadas.
  Future<({CalendarAccount account, int colorIndex})> connectAccount({
    required Set<int> usedColorIndices,
  }) async {
    await _ensureInitialized();
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.attemptLightweightAuthentication();
    } catch (_) {
      account = null;
    }
    if (account == null) {
      try {
        account = await _googleSignIn.authenticate(
          scopeHint: const [gcal.CalendarApi.calendarScope],
        );
      } on GoogleSignInException catch (e) {
        throw CalendarException(_friendlyAuthError(e));
      } catch (_) {
        throw CalendarException('No se pudo iniciar sesión con Google.');
      }
    }

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

    final picked = _pickColor(usedColorIndices);

    final calendars = await _fetchCalendars(
      accessToken: auth.accessToken,
      email: account.email,
    );

    return (
      account: CalendarAccount(
        email: account.email,
        color: picked.color,
        accessToken: auth.accessToken,
        calendars: calendars,
        tokenExpiry: DateTime.now().add(const Duration(minutes: 55)),
      ),
      colorIndex: picked.index,
    );
  }

  /// Adjunta una cuenta de Google Calendar reusando la sesión obtenida durante
  /// el login con Google (sin abrir el selector de cuentas).
  ///
  /// Lanza [CalendarException] si la API de Google Calendar rechaza el token.
  Future<({CalendarAccount account, int colorIndex})> attachFromAuthSession({
    required String email,
    required String accessToken,
    required DateTime expiry,
    required Set<int> usedColorIndices,
  }) async {
    final picked = _pickColor(usedColorIndices);
    final List<CalendarInfo> calendars;
    try {
      calendars = await _fetchCalendars(
        accessToken: accessToken,
        email: email,
      );
    } catch (_) {
      throw CalendarException(
          'No se pudieron cargar los calendarios de $email.');
    }
    return (
      account: CalendarAccount(
        email: email,
        color: picked.color,
        accessToken: accessToken,
        calendars: calendars,
        tokenExpiry: expiry,
      ),
      colorIndex: picked.index,
    );
  }

  /// Desconecta todas las cuentas. Ignora errores (por ejemplo si la sesión
  /// ya había caducado, o el usuario ya había revocado el permiso).
  Future<void> disconnectAll() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
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

  /// Intenta refrescar el access token de [account] de forma SILENCIOSA.
  ///
  /// Usa [GoogleSignIn.attemptLightweightAuthentication] para no mostrar
  /// ningún diálogo. Si no hay sesión restaurable o la cuenta no coincide,
  /// retorna `null` sin disparar UI; el llamante tratará el fallo de red
  /// de forma silenciosa y el usuario reconectará manualmente si necesita
  /// acceder al calendario.
  Future<String?> refreshToken(CalendarAccount account) async {
    try {
        final acc = await _googleSignIn.attemptLightweightAuthentication();
      if (acc == null) return null;
      if (acc.email.toLowerCase() != account.email.toLowerCase()) return null;
      final auth = await acc.authorizationClient
          .authorizationForScopes([gcal.CalendarApi.calendarScope]);
      if (auth == null) return null;
      account.accessToken = auth.accessToken;
      account.tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Timeout aplicado a cualquier llamada a la API de Google Calendar.
  /// Si en este margen no hubo respuesta, devolvemos lo que tengamos en
  /// caché (vacío) y dejamos al usuario navegar sin que la UI se cuelgue.
  static const _apiTimeout = Duration(seconds: 10);

  /// Obtiene la lista de calendarios de una cuenta usando su [accessToken].
  Future<List<CalendarInfo>> _fetchCalendars({
    required String accessToken,
    required String email,
  }) async {
    final api = gcal.CalendarApi(_AuthClient(accessToken));
    final result = await api.calendarList.list().timeout(_apiTimeout);
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

  /// Verifica que el access token de [account] esté vigente; lo refresca si no.
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
    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    final futures = <Future<List<CalendarEvent>>>[];

    for (final account in accounts) {
      await _ensureValidToken(account);
      final api = gcal.CalendarApi(_AuthClient(account.accessToken));
      final visibleCals = account.calendars.where((c) => c.isVisible).toList();
      
      for (final cal in visibleCals) {
        futures.add(_fetchEventsForCalendar(api, cal, account, dayStart, dayEnd));
      }
    }

    final results = await Future.wait(futures);
    final events = results.expand((e) => e).toList();

    events.sort((a, b) {
      if (a.start == null) return 1;
      if (b.start == null) return -1;
      return a.start!.compareTo(b.start!);
    });
    return events;
  }

  Future<List<CalendarEvent>> _fetchEventsForCalendar(
    gcal.CalendarApi api,
    CalendarInfo cal,
    CalendarAccount account,
    DateTime timeMin,
    DateTime timeMax,
  ) async {
    Future<List<CalendarEvent>> doFetch(gcal.CalendarApi client) async {
      final result = await client.events.list(
        cal.id,
        timeMin: timeMin,
        timeMax: timeMax,
        singleEvents: true,
        orderBy: 'startTime',
      ).timeout(_apiTimeout);
      return (result.items ?? [])
          .map((e) => CalendarEvent.fromGoogleEvent(
                e,
                cal.id,
                account.email,
                cal.isOwned,
              ))
          .toList();
    }

    try {
      return await doFetch(api);
    } catch (e) {
      if (!e.toString().contains('401')) return [];
      // Token vencido antes de los 55 min estimados: refrescar y reintentar.
      final newToken = await refreshToken(account);
      if (newToken == null) {
        _markExpired(account);
        return [];
      }
      try {
        return await doFetch(gcal.CalendarApi(_AuthClient(newToken)));
      } catch (_) {
        return [];
      }
    }
  }

  /// Devuelve los próximos eventos de todas las cuentas conectadas en los
  /// siguientes [days] días, ordenados por fecha de inicio.
  ///
  /// Resultado truncado a [maxResults] eventos. Los eventos de todo el día y
  /// los de hora puntual se incluyen por igual, siempre que su inicio sea
  /// posterior a ahora.
  Future<List<CalendarEvent>> fetchUpcomingEvents(
    List<CalendarAccount> accounts,
    int days, {
    int maxResults = 20,
  }) async {
    final now = DateTime.now();
    final timeMin = now.toUtc();
    final timeMax = now.add(Duration(days: days)).toUtc();

    final futures = <Future<List<CalendarEvent>>>[];
    for (final account in accounts) {
      await _ensureValidToken(account);
      final api = gcal.CalendarApi(_AuthClient(account.accessToken));
      for (final cal in account.calendars.where((c) => c.isVisible)) {
        futures.add(_fetchEventsForCalendar(api, cal, account, timeMin, timeMax));
      }
    }

    final results = await Future.wait(futures);
    final events = results.expand((e) => e).toList()
      ..sort((a, b) {
        if (a.start == null) return 1;
        if (b.start == null) return -1;
        return a.start!.compareTo(b.start!);
      });

    return events.take(maxResults).toList();
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

    final futures = <Future<void>>[];

    for (final account in accounts) {
      await _ensureValidToken(account);
      final api = gcal.CalendarApi(_AuthClient(account.accessToken));
      
      for (final cal in account.calendars.where((c) => c.isVisible)) {
        futures.add(_fetchEventDaysForCalendar(api, cal, account, month, monthStart, monthEnd, result));
      }
    }

    await Future.wait(futures);
    return result;
  }

  Future<void> _fetchEventDaysForCalendar(
    gcal.CalendarApi api,
    CalendarInfo cal,
    CalendarAccount account,
    DateTime month,
    DateTime monthStart,
    DateTime monthEnd,
    Map<int, List<Color>> result,
  ) async {
    Future<void> doFetch(gcal.CalendarApi client) async {
      final res = await client.events.list(
        cal.id,
        timeMin: monthStart,
        timeMax: monthEnd,
        singleEvents: true,
        orderBy: 'startTime',
      ).timeout(_apiTimeout);
      for (final e in res.items ?? []) {
        final start = e.start?.dateTime?.toLocal() ??
            (e.start?.date != null
                ? DateTime.tryParse(e.start!.date.toString())
                : null);
        if (start == null) continue;
        if (start.month != month.month || start.year != month.year) continue;
        final list = result.putIfAbsent(start.day, () => <Color>[]);
        if (!list.contains(account.color)) list.add(account.color);
      }
    }

    try {
      await doFetch(api);
    } catch (e) {
      if (!e.toString().contains('401')) return;
      final newToken = await refreshToken(account);
      if (newToken == null) {
        _markExpired(account);
        return;
      }
      try {
        await doFetch(gcal.CalendarApi(_AuthClient(newToken)));
      } catch (_) {}
    }
  }

  /// Fuerza el estado "token caducado" en [account] para que el ViewModel
  /// active el banner "Reconectar" en la próxima reevaluación.
  void _markExpired(CalendarAccount account) {
    account.tokenExpiry =
        DateTime.now().subtract(const Duration(minutes: 1));
  }

  /// Crea un evento en el calendario identificado por [calendarId].
  ///
  /// Resuelve la [CalendarAccount] que contiene el calendario. El llamante
  /// debe verificar que [CalendarInfo.isOwned] sea `true` antes de invocar
  /// este método.
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
      ).timeout(_apiTimeout);
    } catch (_) {
      throw CalendarException('No se pudo crear el evento.');
    }
  }

  /// Elimina el evento identificado por [eventId] del calendario [calendarId].
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
      await api.events.delete(calendarId, eventId).timeout(_apiTimeout);
    } catch (_) {
      throw CalendarException('No se pudo eliminar el evento.');
    }
  }

  /// Retorna la [CalendarAccount] que contiene el calendario con [calendarId],
  /// o `null` si ninguna cuenta lo incluye.
  CalendarAccount? _accountForCalendar(
    List<CalendarAccount> accounts,
    String calendarId,
  ) {
    for (final a in accounts) {
      if (a.calendars.any((c) => c.id == calendarId)) return a;
    }
    return null;
  }

  /// Traduce un [GoogleSignInException] a un mensaje legible en español.
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
