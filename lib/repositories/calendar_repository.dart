import 'dart:math';

import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../services/google_oauth_service.dart';

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
/// Auth: usa [GoogleOAuthService] para obtener `refresh_token` mediante el
/// flujo OAuth 2.0 estándar con `access_type=offline`. El usuario consiente
/// UNA vez en una pestaña de Chrome y a partir de ese momento la app puede
/// renovar `access_token` infinitas veces sin UI hasta que el grant sea
/// revocado explícitamente.
class CalendarRepository {
  final GoogleOAuthService _oauth = GoogleOAuthService();

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
    Color(0xFF43A047),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFFAD1457),
    Color(0xFF558B2F),
    Color(0xFF4527A0),
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

  /// Lanza el flujo OAuth 2.0 estándar con `access_type=offline`.
  ///
  /// Abre Chrome Custom Tabs, el usuario consiente acceso a Calendar UNA
  /// vez, y la app recibe `(access_token, refresh_token)`. El refresh_token
  /// se persiste cifrado en `flutter_secure_storage` (`GoogleOAuthService`)
  /// y permite renovar `access_token` infinitas veces sin UI.
  Future<({CalendarAccount account, int colorIndex})> connectAccount({
    required Set<int> usedColorIndices,
  }) async {
    final GoogleOAuthSession session;
    try {
      final result = await _oauth.authorize();
      if (result == null) {
        throw CalendarException('Has cancelado la conexión con Google.');
      }
      session = result;
    } on GoogleOAuthException catch (e) {
      throw CalendarException(e.message);
    } catch (_) {
      throw CalendarException('No se pudo iniciar sesión con Google.');
    }

    // Resolvemos el email de la cuenta consultando el endpoint userinfo
    // de Google con el access_token recién obtenido.
    final String email;
    try {
      email = await _fetchUserEmail(session.accessToken);
    } catch (_) {
      throw CalendarException('No se pudo identificar la cuenta de Google.');
    }

    final picked = _pickColor(usedColorIndices);

    final List<CalendarInfo> calendars;
    try {
      calendars = await _fetchCalendars(
        accessToken: session.accessToken,
        email: email,
      );
    } catch (_) {
      throw CalendarException(
          'No se pudieron cargar los calendarios de $email.');
    }

    // Persistimos el refresh_token cifrado para esta cuenta.
    await _oauth.storeRefreshToken(email, session.refreshToken);

    return (
      account: CalendarAccount(
        email: email,
        color: picked.color,
        accessToken: session.accessToken,
        calendars: calendars,
        tokenExpiry: session.expiry,
      ),
      colorIndex: picked.index,
    );
  }

  /// Desconecta una cuenta concreta: revoca el grant en Google, borra el
  /// refresh_token cifrado y deja a Google sin acceso a la cuenta.
  ///
  /// Tras esto, una nueva conexión exigirá consentir de nuevo (correcto:
  /// el usuario ha decidido desconectar explícitamente).
  Future<void> disconnect(String email) async {
    final rt = await _oauth.readRefreshToken(email);
    if (rt != null) {
      await _oauth.revoke(rt);
    }
    await _oauth.deleteRefreshToken(email);
  }

  /// Desconecta TODAS las cuentas. Limpia los refresh_tokens residuales del
  /// almacenamiento seguro. El ViewModel debe iterar y llamar a [disconnect]
  /// para revocar el grant individual de cada cuenta antes de invocarlo.
  Future<void> disconnectAll() async {
    await _oauth.deleteAllRefreshTokens();
  }

  /// Refresca silenciosamente el `access_token` de [account] usando el
  /// refresh_token guardado en el storage seguro.
  ///
  /// Devuelve `null` si Google rechaza el refresh_token (revocado, sesión
  /// caducada por inactividad de meses, etc.). En ese caso, el ViewModel
  /// debe activar el banner "Reconectar" para que el usuario reautorice.
  ///
  /// Si Google entrega un refresh_token nuevo, lo guarda automáticamente
  /// reemplazando el anterior. NO muestra UI bajo ningún caso.
  Future<({String accessToken, DateTime expiry})?> silentRefresh(
    CalendarAccount account,
  ) async {
    final stored = await _oauth.readRefreshToken(account.email);
    if (stored == null) return null;
    final session = await _oauth.refresh(stored);
    if (session == null) return null;
    if (session.refreshToken != stored) {
      await _oauth.storeRefreshToken(account.email, session.refreshToken);
    }
    return (accessToken: session.accessToken, expiry: session.expiry);
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

  /// Verifica el estado del token sin tocar al SDK de Google.
  ///
  /// La política de la app es: nunca disparar el picker de cuenta
  /// automáticamente. Si el access token cacheado está caducado, se deja
  /// caducado — la llamada saliente fallará con 401 y el handler del 401
  /// marcará la cuenta como expirada para que la UI muestre el banner
  /// "Reconectar". El usuario decide cuándo reautenticar.
  Future<void> _ensureValidToken(CalendarAccount account) async {
    // No-op intencionado.
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
    return _deduplicateEvents(events);
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
      if (_is401(e)) _markExpired(account);
      return [];
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
    final timeMin = DateTime(now.year, now.month, now.day).toUtc();
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

    return _deduplicateEvents(events).take(maxResults).toList();
  }

  /// Elimina eventos duplicados que provienen de calendarios suscritos en
  /// varias cuentas (e.g. "Festivos en España" presente en 4 cuentas).
  /// Dos eventos se consideran duplicados si tienen el mismo título y el
  /// mismo día de inicio. Se conserva el primero encontrado.
  List<CalendarEvent> _deduplicateEvents(List<CalendarEvent> events) {
    final seen = <String>{};
    return events.where((e) {
      // Never deduplicate owned events — two personal events can legitimately
      // share the same title and day on different calendars.
      if (e.isOwned) return true;
      final start = e.start;
      final day = start != null
          ? '${start.year}-${start.month}-${start.day}'
          : '_';
      final key = '${e.title.trim().toLowerCase()}|$day';
      return seen.add(key);
    }).toList();
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

    final futures = <Future<List<({int day, Color color, String title, bool isOwned})>>>[];

    for (final account in accounts) {
      await _ensureValidToken(account);
      final api = gcal.CalendarApi(_AuthClient(account.accessToken));
      for (final cal in account.calendars.where((c) => c.isVisible)) {
        futures.add(_fetchEventDaysRaw(api, cal, account, month, monthStart, monthEnd));
      }
    }

    final allResults = await Future.wait(futures);
    final allEntries = allResults.expand((e) => e).toList();

    // Deduplicate non-owned entries by (title, day) so shared subscription
    // calendars (e.g. holidays) only contribute one dot per day.
    final seen = <String>{};
    final result = <int, List<Color>>{};
    for (final entry in allEntries) {
      if (!entry.isOwned) {
        final key = '${entry.title.trim().toLowerCase()}|${entry.day}';
        if (!seen.add(key)) continue;
      }
      final list = result.putIfAbsent(entry.day, () => <Color>[]);
      if (!list.contains(entry.color)) list.add(entry.color);
    }

    return result;
  }

  Future<List<({int day, Color color, String title, bool isOwned})>>
      _fetchEventDaysRaw(
    gcal.CalendarApi api,
    CalendarInfo cal,
    CalendarAccount account,
    DateTime month,
    DateTime monthStart,
    DateTime monthEnd,
  ) async {
    final entries = <({int day, Color color, String title, bool isOwned})>[];

    Future<void> doFetch(gcal.CalendarApi client) async {
      final res = await client.events
          .list(
            cal.id,
            timeMin: monthStart,
            timeMax: monthEnd,
            singleEvents: true,
            orderBy: 'startTime',
          )
          .timeout(_apiTimeout);
      for (final e in res.items ?? []) {
        final start = e.start?.dateTime?.toLocal() ??
            (e.start?.date != null
                ? DateTime.tryParse(e.start!.date.toString())
                : null);
        if (start == null) continue;
        if (start.month != month.month || start.year != month.year) continue;
        entries.add((
          day: start.day,
          color: account.color,
          title: e.summary ?? '',
          isOwned: cal.isOwned,
        ));
      }
    }

    try {
      await doFetch(api);
    } catch (e) {
      if (e.toString().contains('401')) _markExpired(account);
    }
    return entries;
  }

  bool _is401(Object e) {
    final s = e.toString();
    return s.contains('401') || s.contains('Unauthorized');
  }

  /// Marca el token de [account] como rechazado por Google (recibido un 401)
  /// para que el ViewModel active el banner "Reconectar" en la próxima
  /// reevaluación. El timestamp también se invalida para forzar un intento
  /// de refresh silencioso en el siguiente arranque.
  void _markExpired(CalendarAccount account) {
    account.tokenExpiry =
        DateTime.now().subtract(const Duration(minutes: 1));
    account.tokenRejected = true;
  }

  /// Crea un evento en el calendario identificado por [calendarId].
  ///
  /// Lanza [CalendarException] si el calendario es de solo lectura o no
  /// pertenece a ninguna cuenta conectada.
  Future<void> createEvent({
    required List<CalendarAccount> accounts,
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final (:api, account: _) = _resolveWritable(accounts, calendarId);
    try {
      await api.events
          .insert(
            gcal.Event(
              summary: title,
              start: gcal.EventDateTime(dateTime: start.toUtc()),
              end: gcal.EventDateTime(dateTime: end.toUtc()),
            ),
            calendarId,
          )
          .timeout(_apiTimeout);
    } on CalendarException {
      rethrow;
    } catch (_) {
      throw CalendarException('No se pudo crear el evento.');
    }
  }

  /// Actualiza el título y/o el horario de [eventId] en [calendarId].
  ///
  /// Usa `events.patch` para modificar solo los campos indicados sin
  /// sobreescribir el resto del evento (asistentes, descripción, etc.).
  /// Lanza [CalendarException] si el calendario es de solo lectura.
  Future<void> updateEvent({
    required List<CalendarAccount> accounts,
    required String calendarId,
    required String eventId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final (:api, account: _) = _resolveWritable(accounts, calendarId);
    try {
      await api.events
          .patch(
            gcal.Event(
              summary: title,
              start: gcal.EventDateTime(dateTime: start.toUtc()),
              end: gcal.EventDateTime(dateTime: end.toUtc()),
            ),
            calendarId,
            eventId,
          )
          .timeout(_apiTimeout);
    } on CalendarException {
      rethrow;
    } catch (_) {
      throw CalendarException('No se pudo actualizar el evento.');
    }
  }

  /// Elimina el evento identificado por [eventId] del calendario [calendarId].
  ///
  /// Lanza [CalendarException] si el calendario es de solo lectura o no
  /// pertenece a ninguna cuenta conectada.
  Future<void> deleteEvent({
    required List<CalendarAccount> accounts,
    required String calendarId,
    required String eventId,
  }) async {
    final (:api, account: _) = _resolveWritable(accounts, calendarId);
    try {
      await api.events.delete(calendarId, eventId).timeout(_apiTimeout);
    } on CalendarException {
      rethrow;
    } catch (_) {
      throw CalendarException('No se pudo eliminar el evento.');
    }
  }

  /// Resuelve el par `(account, calendarInfo)` para [calendarId] y lanza
  /// [CalendarException] si no existe o si el calendario es de solo lectura.
  ///
  /// Centraliza la validación de permisos de escritura para que todos los
  /// métodos mutantes (`createEvent`, `updateEvent`, `deleteEvent`) la apliquen
  /// de forma uniforme, independientemente de lo que haga la UI.
  ({CalendarAccount account, gcal.CalendarApi api}) _resolveWritable(
    List<CalendarAccount> accounts,
    String calendarId,
  ) {
    for (final a in accounts) {
      final cal = a.calendars.where((c) => c.id == calendarId).firstOrNull;
      if (cal == null) continue;
      if (cal.isReadOnly) {
        throw CalendarException(
          'No tienes permisos de escritura en este calendario.',
        );
      }
      return (account: a, api: gcal.CalendarApi(_AuthClient(a.accessToken)));
    }
    throw CalendarException('Calendario no encontrado.');
  }

  /// Consulta el email de la cuenta autenticada usando el endpoint userinfo.
  /// Necesario porque oauth2_client no devuelve la identidad del usuario,
  /// solo el access_token.
  Future<String> _fetchUserEmail(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://openidconnect.googleapis.com/v1/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(_apiTimeout);
    if (response.statusCode != 200) {
      throw Exception('userinfo HTTP ${response.statusCode}');
    }
    final body = response.body;
    final emailMatch = RegExp(r'"email"\s*:\s*"([^"]+)"').firstMatch(body);
    if (emailMatch == null) {
      throw Exception('userinfo response sin email');
    }
    return emailMatch.group(1)!;
  }
}
