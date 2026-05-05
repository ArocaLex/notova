import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../repositories/calendar_repository.dart';

/// Gestiona el estado y las operaciones de Google Calendar con soporte multi-cuenta.
///
/// Persiste las cuentas conectadas y sus calendarios en SQLite mediante
/// [AppDatabase]. Delega las llamadas a la API de Google Calendar a
/// [CalendarRepository]. Permite conectar y desconectar cuentas, filtrar
/// calendarios por visibilidad y crear o eliminar eventos en calendarios
/// propios.
class CalendarViewModel extends ChangeNotifier {
  final CalendarRepository _repository = CalendarRepository();
  final AppDatabase _db = AppDatabase();

  DateTime selectedDate = DateTime.now();
  DateTime focusedMonth = DateTime.now();

  /// Todas las cuentas conectadas simultáneamente (multi-cuenta).
  final List<CalendarAccount> accounts = [];

  /// Índices de la paleta ya usados — evita repetir color entre cuentas.
  final Set<int> _usedColorIndices = {};

  /// Mapa email → índice de paleta usado, persistido en SQLite. Permite
  /// recuperar el color exacto al restaurar y evitar repeticiones.
  final Map<String, int> _accountColorIndex = {};

  List<CalendarEvent> events = [];

  /// Próximos eventos agregados de todas las cuentas conectadas, a partir
  /// de ahora y hasta [_upcomingDays] días adelante. Lo usa la lista de
  /// agenda del Home.
  List<CalendarEvent> upcomingEvents = [];

  /// Calcula los días que quedan hasta el próximo domingo (inclusive).
  /// Si hoy es domingo devuelve 1 (solo hoy). Usado para "próximos eventos".
  static int get _daysUntilEndOfWeek {
    final now = DateTime.now();
    final daysToSunday = (DateTime.sunday - now.weekday) % 7;
    return daysToSunday + 1;
  }

  /// Mapa día-del-mes → colores de las cuentas que tienen eventos ese día.
  /// Se usa para pintar los "puntitos" en el grid.
  Map<int, List<Color>> eventDayColors = {};

  /// Caché local de resultados de [fetchEventDaysForMonth] para evitar
  /// llamadas repetidas a la API al navegar entre meses.
  ///
  /// Clave: `"YYYY-MM"`. Se invalida al conectar o desconectar una cuenta.
  final Map<String, Map<int, List<Color>>> _monthCache = {};

  bool isLoading = false;
  bool isSavingEvent = false;
  String? errorMessage;

  /// Email de la última cuenta conectada exitosamente. La UI lo consume para
  /// mostrar un snackbar de confirmación y debe limpiarlo llamando a
  /// [clearLastConnectedEmail] tras mostrarlo.
  String? lastConnectedEmail;

  /// `true` cuando hay cuentas guardadas en SQLite pero su sesión OAuth con
  /// Google no se pudo restaurar silenciosamente al abrir la app — la UI
  /// muestra un banner "Reconectar" para que el usuario refresque el acceso
  /// con un solo gesto.
  bool needsReconnect = false;

  /// `true` si en esta sesión el usuario ya pulsó desconectar al menos una
  /// cuenta. Usado por la UI para no reusar la sesión Google cacheada al
  /// reconectar — si el usuario desconectó intencionadamente, el siguiente
  /// clic en "Conectar" debe abrir el picker en vez de volver a adjuntar
  /// silenciosamente la misma cuenta.
  bool userHasDisconnected = false;

  StreamSubscription<User?>? _authSub;

  CalendarViewModel() {
    _restoreFromLocal();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        disconnectGoogleCalendar(email: null);
      }
    });
  }

  bool get isSignedIn => accounts.isNotEmpty;

  /// Todos los calendarios de todas las cuentas (para la UI de filtros).
  List<CalendarInfo> get allCalendars => [
        for (final a in accounts) ...a.calendars,
      ];

  /// Calendarios propios del usuario en todas las cuentas (permite crear, editar y eliminar eventos).
  List<CalendarInfo> get ownedCalendars =>
      allCalendars.where((c) => c.isOwned).toList();

  /// Email de la primera cuenta (compatibilidad con UI antigua).
  String? get connectedEmail =>
      accounts.isEmpty ? null : accounts.first.email;

  /// Devuelve el color de la cuenta a la que pertenece [calendarId], o
  /// [fallback] si no se encuentra.
  Color calendarColor(String calendarId, {Color? fallback}) {
    for (final a in accounts) {
      for (final c in a.calendars) {
        if (c.id == calendarId) return a.color;
      }
    }
    return fallback ?? const Color(0xFF7B2CBF);
  }

  /// Retorna el color asignado a la cuenta con [email], o el color primario
  /// de Notova si la cuenta no está conectada.
  Color accountColorFor(String email) {
    for (final a in accounts) {
      if (a.email == email) return a.color;
    }
    return const Color(0xFF7B2CBF);
  }

  /// Carga las cuentas guardadas en SQLite y, en background, intenta
  /// recuperar silenciosamente el access token (sin abrir diálogos de Google).
  Future<void> _restoreFromLocal() async {
    try {
      final savedAccounts = await _db.getAllCalendarAccounts();
      for (final acc in savedAccounts) {
        final cals = await _db.getCalendarsForAccount(acc.email);
        accounts.add(CalendarAccount(
          email: acc.email,
          color: Color(acc.colorValue),
          accessToken: acc.accessToken,
          tokenExpiry: acc.tokenExpiry,
          calendars: cals
              .map((c) => CalendarInfo(
                    id: c.id,
                    summary: c.summary,
                    backgroundColor: c.backgroundColor,
                    accessRole: c.accessRole,
                    accountEmail: c.accountEmail,
                    isVisible: c.isVisible,
                  ))
              .toList(),
        ));
        if (acc.colorIndex >= 0) {
          _usedColorIndices.add(acc.colorIndex);
          _accountColorIndex[acc.email] = acc.colorIndex;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CalendarVM] restore from local failed: $e');
    }

    if (accounts.isEmpty) return;

    // Refresca el access token de cada cuenta sin abrir diálogos y luego
    // carga los eventos de hoy y los marcadores del mes para que el usuario,
    // al abrir la pestaña Calendar tras reabrir la app, vea su agenda sin
    // tener que cambiar de día o pulsar refrescar.
    await _silentRestoreToken();
    _recomputeNeedsReconnect();
    await _reloadEverything();
    _recomputeNeedsReconnect();
    notifyListeners();
  }

  /// Marca [needsReconnect] como `true` si alguna cuenta tiene el token
  /// caducado tras una operación silenciosa o un 401 en runtime.
  void _recomputeNeedsReconnect() {
    needsReconnect = accounts.any((a) => a.isTokenExpired);
  }

  /// Reabre el flujo de Google para refrescar las credenciales de las cuentas
  /// cuyo token caducó cuando la sesión silenciosa no fue capaz de
  /// restaurarse. Llamado desde el banner "Reconectar".
  Future<void> reconnectExpired() async {
    needsReconnect = false;
    notifyListeners();
    await connectGoogleCalendar();
    _recomputeNeedsReconnect();
    notifyListeners();
  }

  /// Intenta restaurar el access token de las cuentas guardadas sin abrir
  /// diálogos.
  ///
  /// Primero pide a `attemptSilentRestore` la sesión Google activa del
  /// dispositivo y refresca esa cuenta. A continuación intenta refrescar las
  /// demás cuentas vía `_repository.refreshToken`. Las cuentas que no
  /// puedan refrescarse silenciosamente quedan marcadas como expiradas para
  /// que la UI muestre el banner "Reconectar".
  Future<void> _silentRestoreToken() async {
    try {
      final restored = await _repository.attemptSilentRestore();
      if (restored != null) {
        final idx = accounts.indexWhere(
            (a) => a.email.toLowerCase() == restored.email.toLowerCase());
        if (idx != -1) {
          accounts[idx].accessToken = restored.accessToken;
          accounts[idx].tokenExpiry = restored.expiry;
          await _persistAccount(accounts[idx]);
        }
      }

      for (final acc in accounts) {
        if (!acc.isTokenExpired) continue;
        final newToken = await _repository.refreshToken(acc);
        if (newToken == null) {
          // refreshToken solo devuelve el token si la sesión Google viva
          // coincide con la cuenta. Si no coincide, dejamos el token
          // caducado y _recomputeNeedsReconnect activará el banner.
          continue;
        }
        await _persistAccount(acc);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[CalendarVM] silent token restore failed: $e');
    }
  }

  /// Persiste una [CalendarAccount] y sus calendarios en SQLite.
  Future<void> _persistAccount(CalendarAccount account) async {
    try {
      await _db.upsertCalendarAccount(LocalCalendarAccountsCompanion(
        email: drift.Value(account.email),
        colorValue: drift.Value(_colorIntFromAccount(account)),
        colorIndex:
            drift.Value(_accountColorIndex[account.email] ?? -1),
        accessToken: drift.Value(account.accessToken),
        tokenExpiry: drift.Value(account.tokenExpiry),
        connectedAt: drift.Value(DateTime.now()),
      ));
      await _db.replaceCalendarsForAccount(
        account.email,
        account.calendars
            .map((c) => LocalCalendarsCompanion(
                  id: drift.Value(c.id),
                  accountEmail: drift.Value(account.email),
                  summary: drift.Value(c.summary),
                  backgroundColor: drift.Value(c.backgroundColor),
                  accessRole: drift.Value(c.accessRole),
                  isVisible: drift.Value(c.isVisible),
                ))
            .toList(),
      );
    } catch (e) {
      debugPrint('[CalendarVM] persist account failed: $e');
    }
  }

  /// Retorna el entero ARGB del color de [a] para persistirlo en SQLite.
  int _colorIntFromAccount(CalendarAccount a) {
    // ignore: deprecated_member_use
    return a.color.value;
  }

  /// Limpia el email de la última cuenta conectada tras mostrarlo en la UI.
  void clearLastConnectedEmail() => lastConnectedEmail = null;

  /// Conecta una nueva cuenta de Google Calendar sin eliminar las existentes.
  ///
  /// Asigna un color de paleta exclusivo a la cuenta, persiste la información
  /// en SQLite y recarga los eventos. Si el usuario cancela el diálogo de
  /// Google, establece [errorMessage] con un mensaje descriptivo.
  Future<void> connectGoogleCalendar() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.connectAccount(
        usedColorIndices: _usedColorIndices,
      );
      await _registerAccount(result.account, result.colorIndex);
      lastConnectedEmail = result.account.email;
      userHasDisconnected = false;
      _monthCache.clear();
      await _reloadEverything();
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudo conectar con Google Calendar.';
    } finally {
      _recomputeNeedsReconnect();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Adjunta la cuenta de Google obtenida durante el login (sin picker).
  ///
  /// Llamado desde la pantalla de autenticación tras un Google Sign-In
  /// exitoso. Si la cuenta ya está registrada, no hace nada.
  Future<void> attachGoogleAccountFromAuth({
    required String email,
    required String accessToken,
    required DateTime expiry,
  }) async {
    final normalized = email.toLowerCase();
    if (accounts
        .any((a) => a.email.toLowerCase() == normalized)) {
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.attachFromAuthSession(
        email: email,
        accessToken: accessToken,
        expiry: expiry,
        usedColorIndices: _usedColorIndices,
      );
      await _registerAccount(result.account, result.colorIndex);
      lastConnectedEmail = result.account.email;
      _monthCache.clear();
      await _reloadEverything();
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudo conectar con Google Calendar.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Intenta conectar la cuenta de Google del usuario actual sin mostrar
  /// el selector. Devuelve `true` si lo logra. Solo aplica cuando el usuario
  /// inició sesión con Google (la sesión sigue viva en GoogleSignIn).
  Future<bool> attemptSilentAttach() async {
    try {
      final restored = await _repository.attemptSilentRestore();
      if (restored == null) return false;
      final normalized = restored.email.toLowerCase();
      if (accounts.any((a) => a.email.toLowerCase() == normalized)) {
        return true;
      }
      isLoading = true;
      notifyListeners();
      try {
        final result = await _repository.attachFromAuthSession(
          email: restored.email,
          accessToken: restored.accessToken,
          expiry: restored.expiry,
          usedColorIndices: _usedColorIndices,
        );
        await _registerAccount(result.account, result.colorIndex);
        _monthCache.clear();
        await _reloadEverything();
        return true;
      } finally {
        isLoading = false;
        notifyListeners();
      }
    } catch (_) {
      return false;
    }
  }

  /// Inserta o reemplaza una cuenta y persiste con el índice de color real.
  Future<void> _registerAccount(CalendarAccount account, int colorIndex) async {
    final normalized = account.email.toLowerCase();
    accounts
        .removeWhere((a) => a.email.toLowerCase() == normalized);
    accounts.add(account);
    _accountColorIndex[account.email] = colorIndex;
    await _persistAccount(account);
  }

  /// Desconecta una cuenta concreta identificada por su email.
  ///
  /// Si no se proporciona email, desconecta todas las cuentas. Limpia los
  /// datos locales asociados y reinicia la lista de eventos.
  Future<void> disconnectGoogleCalendar({String? email}) async {
    errorMessage = null;
    userHasDisconnected = true;
    try {
      if (email == null) {
        await _repository.disconnectAll();
        accounts.clear();
        _usedColorIndices.clear();
        _accountColorIndex.clear();
        await _db.clearAllCalendarAccounts();
      } else {
        final normalized = email.toLowerCase();
        accounts.removeWhere((a) => a.email.toLowerCase() == normalized);
        final colorIdx = _accountColorIndex.remove(email) ??
            _accountColorIndex.remove(normalized);
        if (colorIdx != null) _usedColorIndices.remove(colorIdx);
        await _db.deleteCalendarAccount(email);
        if (accounts.isEmpty) {
          await _repository.disconnectAll();
          _usedColorIndices.clear();
          _accountColorIndex.clear();
        }
      }
      events = [];
      upcomingEvents = [];
      eventDayColors = {};
      _monthCache.clear();
    } catch (_) {}
    notifyListeners();
  }

  /// Recarga los eventos del día seleccionado y los indicadores del mes.
  Future<void> _reloadEverything() async {
    try {
      events = await _repository.fetchEventsForDate(accounts, selectedDate);
      eventDayColors =
          await _repository.fetchEventDaysForMonth(accounts, focusedMonth);
      unawaited(_loadUpcomingEvents());
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudieron cargar los eventos.';
    }
  }

  /// Carga la lista de próximos eventos agregada de todas las cuentas
  /// conectadas. Se invoca de forma oportunista cuando cambian cuentas o
  /// calendarios y no bloquea ninguna interacción de la UI.
  Future<void> _loadUpcomingEvents() async {
    if (accounts.isEmpty) {
      upcomingEvents = [];
      return;
    }
    try {
      upcomingEvents =
          await _repository.fetchUpcomingEvents(accounts, _daysUntilEndOfWeek);
      notifyListeners();
    } catch (_) {}
  }

  /// Fuerza una recarga de los próximos eventos desde la API. Útil cuando
  /// el Home se presenta tras conectar una cuenta o crear un evento.
  Future<void> refreshUpcoming() => _loadUpcomingEvents();

  /// Carga los eventos de [date] para las cuentas conectadas.
  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      events = await _repository.fetchEventsForDate(accounts, date);
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudieron cargar los eventos.';
    }
    _recomputeNeedsReconnect();
  }

  /// Carga los días con eventos de [month] para pintar los indicadores del grid.
  ///
  /// Devuelve el resultado desde [_monthCache] si ya fue descargado; si no,
  /// consulta la API, almacena el resultado y notifica a la UI.
  Future<void> _loadEventDaysForMonth(DateTime month) async {
    final key = '${month.year}-${month.month}';
    if (_monthCache.containsKey(key)) {
      eventDayColors = _monthCache[key]!;
      return;
    }
    try {
      final result =
          await _repository.fetchEventDaysForMonth(accounts, month);
      _monthCache[key] = result;
      eventDayColors = result;
    } catch (_) {}
    _recomputeNeedsReconnect();
  }

  /// Precarga los días con eventos de [month] en caché sin notificar a la UI.
  Future<void> _prefetchMonth(DateTime month) async {
    final key = '${month.year}-${month.month}';
    if (_monthCache.containsKey(key)) return;
    try {
      final result =
          await _repository.fetchEventDaysForMonth(accounts, month);
      _monthCache[key] = result;
    } catch (_) {}
  }

  /// Selecciona una fecha y recarga los eventos correspondientes.
  void onDateSelected(DateTime date) {
    selectedDate = date;
    errorMessage = null;
    _loadEventsForDate(date).then((_) => notifyListeners());
  }

  /// Reposiciona la vista del calendario al día de hoy y recarga los eventos
  /// del día y del mes correspondientes.
  ///
  /// Se invoca cada vez que el usuario abre la pestaña Calendario o regresa
  /// a la app desde background para que el día seleccionado no quede
  /// "atascado" en una fecha anterior.
  void resetToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonth = DateTime(now.year, now.month, 1);
    final alreadyToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
    if (alreadyToday && focusedMonth.year == thisMonth.year &&
        focusedMonth.month == thisMonth.month) {
      return;
    }
    selectedDate = today;
    focusedMonth = thisMonth;
    errorMessage = null;
    notifyListeners();
    if (!isSignedIn) return;
    _loadEventsForDate(today).then((_) => notifyListeners());
    _loadEventDaysForMonth(thisMonth).then((_) => notifyListeners());
  }

  /// Actualiza el mes enfocado, sirve el caché inmediatamente si existe y
  /// precarga los meses adyacentes para que la navegación sea instantánea.
  void onMonthChanged(DateTime newFocus) {
    focusedMonth = newFocus;
    notifyListeners();
    _loadEventDaysForMonth(newFocus).then((_) => notifyListeners());
    unawaited(_prefetchMonth(DateTime(newFocus.year, newFocus.month - 1)));
    unawaited(_prefetchMonth(DateTime(newFocus.year, newFocus.month + 1)));
  }

  /// Refresca la lista de calendarios y eventos de todas las cuentas conectadas.
  ///
  /// Consulta la API de Google para detectar calendarios agregados o
  /// eliminados, preservando la visibilidad configurada por el usuario.
  Future<void> refresh() async {
    if (!isSignedIn) return;
    isLoading = true;
    notifyListeners();
    for (final a in accounts) {
      try {
        final fresh = await _repository.fetchCalendarList(a);
        for (final c in fresh) {
          final existing = a.calendars
              .where((old) => old.id == c.id)
              .cast<CalendarInfo?>()
              .firstWhere((_) => true, orElse: () => null);
          if (existing != null) c.isVisible = existing.isVisible;
        }
        a.calendars = fresh;
        await _persistAccount(a);
      } catch (_) {}
    }
    await _reloadEverything();
    isLoading = false;
    notifyListeners();
  }

  /// Alterna la visibilidad del calendario identificado por su [calendarId].
  ///
  /// Persiste el cambio en SQLite y recarga los eventos para reflejar
  /// el filtro actualizado.
  void toggleCalendarVisibility(String calendarId) {
    for (final a in accounts) {
      final idx = a.calendars.indexWhere((c) => c.id == calendarId);
      if (idx != -1) {
        final cal = a.calendars[idx];
        cal.isVisible = !cal.isVisible;
        unawaited(_db.setCalendarVisibility(
            calendarId, a.email, cal.isVisible));
        break;
      }
    }
    notifyListeners();
    unawaited(_reloadEverything().then((_) => notifyListeners()));
  }

  /// Crea un evento en el calendario propio identificado por [calendarId].
  ///
  /// Solo permite la creación en calendarios donde el usuario tiene rol de
  /// propietario. Retorna `true` si el evento se creó correctamente o
  /// `false` en caso de error o si el calendario no es propio.
  Future<bool> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final cal = allCalendars.where((c) => c.id == calendarId).firstOrNull;
    if (cal == null || !cal.isOwned) return false;

    isSavingEvent = true;
    notifyListeners();
    try {
      await _repository.createEvent(
        accounts: accounts,
        calendarId: calendarId,
        title: title,
        start: start,
        end: end,
      );
      // Delay to allow Google Calendar API to propagate the new event.
      await Future.delayed(const Duration(seconds: 2));
      await _reloadEverything();
      isSavingEvent = false;
      notifyListeners();
      return true;
    } on CalendarException catch (e) {
      errorMessage = e.message;
      isSavingEvent = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo crear el evento.';
      isSavingEvent = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina el evento indicado de Google Calendar.
  ///
  /// Solo permite la eliminación si el evento pertenece a un calendario
  /// propio. Retorna `true` si se eliminó correctamente o `false` en caso
  /// de error.
  Future<bool> deleteEvent(CalendarEvent event) async {
    if (!event.isOwned) return false;

    // Optimistic removal: update local state immediately so the UI reflects
    // the deletion without waiting for the Google API propagation delay.
    final previousEvents = List<CalendarEvent>.from(events);
    final previousUpcoming = List<CalendarEvent>.from(upcomingEvents);
    events = events.where((e) => e.id != event.id).toList();
    upcomingEvents = upcomingEvents.where((e) => e.id != event.id).toList();
    if (event.start != null) {
      _monthCache.remove('${event.start!.year}-${event.start!.month}');
    }
    notifyListeners();

    try {
      await _repository.deleteEvent(
        accounts: accounts,
        calendarId: event.calendarId,
        eventId: event.id,
      );
      // Delayed reload for eventual consistency with the Google Calendar API.
      unawaited(Future.delayed(const Duration(seconds: 2), () async {
        await _reloadEverything();
        notifyListeners();
      }));
      return true;
    } on CalendarException catch (e) {
      errorMessage = e.message;
      events = previousEvents;
      upcomingEvents = previousUpcoming;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo eliminar el evento.';
      events = previousEvents;
      upcomingEvents = previousUpcoming;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
