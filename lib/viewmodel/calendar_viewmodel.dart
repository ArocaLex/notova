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

  /// Próximos eventos agregados de todas las cuentas conectadas, próximos 7 días.
  List<CalendarEvent> upcomingEvents = [];

  static const int _upcomingDays = 30;

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
  /// cuenta. La UI lo usa para no reusar la sesión Google cacheada al
  /// reconectar — si el usuario desconectó intencionadamente, el siguiente
  /// clic en "Conectar" debe abrir el picker en vez de volver a adjuntar
  /// silenciosamente la misma cuenta.
  bool userHasDisconnected = false;

  StreamSubscription<User?>? _authSub;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Future que se resuelve cuando `_restoreFromLocal` ha cargado las cuentas
  /// desde SQLite. El splash lo espera antes de intentar refrescar tokens
  /// silenciosamente para evitar race conditions.
  late final Future<void> _initialLoad;

  late final Completer<void> _loadCompleter;

  CalendarViewModel() {
    _loadCompleter = Completer<void>();
    _initialLoad = _loadCompleter.future;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        accounts.clear();
        _usedColorIndices.clear();
        _accountColorIndex.clear();
        events.clear();
        upcomingEvents.clear();
        eventDayColors.clear();
        _monthCache.clear();
        needsReconnect = false;
        if (!_loadCompleter.isCompleted) _loadCompleter.complete();
        notifyListeners();
      } else {
        await _restoreFromLocal();
        if (!_loadCompleter.isCompleted) _loadCompleter.complete();
        notifyListeners();
      }
    });
  }

  bool get isSignedIn => accounts.isNotEmpty;

  /// Todos los calendarios de todas las cuentas (para la UI de filtros).
  List<CalendarInfo> get allCalendars => [
        for (final a in accounts) ...a.calendars,
      ];

  /// Calendarios propios del usuario en todas las cuentas (permite crear,
  /// editar y eliminar eventos).
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

  /// Carga las cuentas guardadas en SQLite.
  Future<void> _restoreFromLocal() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final saved = await _db.obtenerTodasLasCuentas(uid);
      accounts.clear();
      _usedColorIndices.clear();
      _accountColorIndex.clear();

      for (final acc in saved) {
        final cals = await _db.obtenerCalendariosDeCuenta(uid, acc.email);
        accounts.add(
          CalendarAccount(
            email: acc.email,
            color: Color(acc.valorColor),
            accessToken: acc.tokenAcceso,
            tokenExpiry: acc.expiracionToken,
            calendars: cals
                .map(
                  (c) => CalendarInfo(
                    id: c.id,
                    summary: c.resumen,
                    backgroundColor: c.colorFondo,
                    accessRole: c.rolAcceso,
                    accountEmail: c.emailCuenta,
                    isVisible: c.esVisible,
                  ),
                )
                .toList(),
          ),
        );
        if (acc.indiceColor >= 0) {
          _usedColorIndices.add(acc.indiceColor);
          _accountColorIndex[acc.email] = acc.indiceColor;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CalendarVM] restore from local failed: $e');
    }

    if (accounts.isEmpty) return;

    _recomputeNeedsReconnect();
    await _reloadEverything();
    _recomputeNeedsReconnect();
    notifyListeners();
  }

  /// Marca [needsReconnect] como `true` si Google rechazó el token de alguna
  /// cuenta con un 401. El simple paso del tiempo no activa el banner: el
  /// token cacheado puede seguir siendo válido para Google aunque nuestra
  /// ventana conservadora local diga que caducó.
  void _recomputeNeedsReconnect() {
    needsReconnect = accounts.any((a) => a.tokenRejected);
  }

  /// Refresca silenciosamente los tokens de las cuentas guardadas reusando
  /// el `refresh_token` cifrado en `flutter_secure_storage`.
  ///
  /// Pensado para invocarse desde el splash screen aprovechando el tiempo de
  /// la animación inicial: el usuario no ve nada y al llegar a Home/Calendar
  /// los tokens ya están actualizados. Si Google rechaza el refresh_token
  /// (revocado, sesión caducada por inactividad de meses), las cuentas
  /// quedan marcadas como expiradas y la UI muestra el banner "Reconectar".
  ///
  /// Es seguro llamarlo varias veces: hace early-return si todas las cuentas
  /// tienen el access token aún vigente.
  Future<void> restoreTokensSilently() async {
    await _initialLoad;

    if (accounts.isEmpty) return;
    if (accounts.every((a) => !a.isTokenExpired)) return;

    try {
      bool anyRefreshed = false;
      for (final account in accounts) {
        if (!account.isTokenExpired) continue;
        final fresh = await _repository.silentRefresh(account);
        if (fresh == null) {
          account.tokenRejected = true;
          continue;
        }
        account.accessToken = fresh.accessToken;
        account.tokenExpiry = fresh.expiry;
        account.tokenRejected = false;
        anyRefreshed = true;
        await _persistAccount(account);
      }

      _recomputeNeedsReconnect();
      if (anyRefreshed) {
        await _reloadEverything();
        _recomputeNeedsReconnect();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CalendarVM] silent token restore on splash failed: $e');
    }
  }

  /// Reabre el flujo OAuth para refrescar las credenciales de las cuentas
  /// cuyo refresh_token fue rechazado. Llamado desde el banner "Reconectar".
  ///
  /// Antes de abrir el flujo de consentimiento, intenta refrescar
  /// silenciosamente con el refresh_token guardado. Si funciona, el usuario
  /// no ve nada. Solo si Google rechaza el refresh_token caemos al flujo
  /// completo con `connectGoogleCalendar` (consent en Chrome Custom Tab).
  Future<void> reconnectExpired() async {
    needsReconnect = false;
    notifyListeners();

    await restoreTokensSilently();
    if (!accounts.any((a) => a.isTokenExpired)) {
      _recomputeNeedsReconnect();
      notifyListeners();
      return;
    }

    await connectGoogleCalendar();
    _recomputeNeedsReconnect();
    notifyListeners();
  }

  /// Persiste una [CalendarAccount] y sus calendarios en SQLite.
  Future<void> _persistAccount(CalendarAccount account) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.insertarCuenta(
        AccountsTableCompanion(
          idUsuario: drift.Value(uid),
          email: drift.Value(account.email),
          valorColor: drift.Value(_colorIntFromAccount(account)),
          indiceColor: drift.Value(_accountColorIndex[account.email] ?? -1),
          tokenAcceso: drift.Value(account.accessToken),
          expiracionToken: drift.Value(account.tokenExpiry),
          conectadaEl: drift.Value(DateTime.now()),
        ),
      );
      await _db.reemplazarCalendariosDeCuenta(
        uid,
        account.email,
        account.calendars
            .map(
              (c) => CalendarsTableCompanion(
                id: drift.Value(c.id),
                emailCuenta: drift.Value(account.email),
                resumen: drift.Value(c.summary),
                colorFondo: drift.Value(c.backgroundColor),
                rolAcceso: drift.Value(c.accessRole),
                esVisible: drift.Value(c.isVisible),
              ),
            )
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
  /// en SQLite y recarga los eventos. Si el usuario cancela el flujo OAuth,
  /// establece [errorMessage] con un mensaje descriptivo.
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

  /// Inserta o reemplaza una cuenta y persiste con el índice de color real.
  Future<void> _registerAccount(
    CalendarAccount account,
    int colorIndex,
  ) async {
    final normalized = account.email.toLowerCase();
    accounts.removeWhere((a) => a.email.toLowerCase() == normalized);
    accounts.add(account);
    _accountColorIndex[account.email] = colorIndex;
    await _persistAccount(account);
  }

  /// Desconecta una cuenta concreta identificada por su email.
  ///
  /// Si no se proporciona email, desconecta todas las cuentas. Limpia los
  /// datos locales asociados y reinicia la lista de eventos.
  Future<void> disconnectGoogleCalendar({String? email}) async {
    final uid = _uid;
    if (uid == null) return;
    errorMessage = null;
    userHasDisconnected = true;
    try {
      if (email == null) {
        // Revoca el grant de cada cuenta y borra el refresh_token cifrado.
        for (final a in accounts) {
          await _repository.disconnect(a.email);
        }
        await _repository.disconnectAll();
        accounts.clear();
        _usedColorIndices.clear();
        _accountColorIndex.clear();
        await _db.borrarTodasLasCuentas(uid);
      } else {
        await _repository.disconnect(email);
        final normalized = email.toLowerCase();
        accounts.removeWhere((a) => a.email.toLowerCase() == normalized);
        final colorIdx =
            _accountColorIndex.remove(email) ??
            _accountColorIndex.remove(normalized);
        if (colorIdx != null) _usedColorIndices.remove(colorIdx);
        await _db.borrarCuenta(uid, email);
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

  /// Recarga los eventos del día seleccionado y los indicadores del mes
  /// en paralelo, luego lanza la carga de próximos eventos en segundo plano.
  Future<void> _reloadEverything() async {
    try {
      final results = await Future.wait([
        _repository.fetchEventsForDate(accounts, selectedDate),
        _repository.fetchEventDaysForMonth(accounts, focusedMonth),
      ]);
      events = results[0] as List<CalendarEvent>;
      eventDayColors = results[1] as Map<int, List<Color>>;
    } catch (_) {}
    notifyListeners();
    unawaited(_loadUpcomingEvents());
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
      upcomingEvents = await _repository.fetchUpcomingEvents(
        accounts,
        _upcomingDays,
        maxResults: 100,
      );
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
    } catch (_) {}
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
        selectedDate.day == today.day &&
        focusedMonth.year == thisMonth.year &&
        focusedMonth.month == thisMonth.month;

    if (alreadyToday) {
      if (isSignedIn) unawaited(_loadUpcomingEvents());
      return;
    }
    selectedDate = today;
    focusedMonth = thisMonth;
    errorMessage = null;
    notifyListeners();
    if (!isSignedIn) return;
    Future.wait([
      _loadEventsForDate(today),
      _loadEventDaysForMonth(thisMonth),
    ]).then((_) {
      notifyListeners();
      unawaited(_loadUpcomingEvents());
    });
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
    final uid = _uid;
    if (uid == null) return;

    CalendarInfo? tapped;
    for (final a in accounts) {
      tapped = a.calendars.where((c) => c.id == calendarId).firstOrNull;
      if (tapped != null) break;
    }
    if (tapped == null) return;

    final newVisible = !tapped.isVisible;
    final summaryKey = tapped.summary.trim().toLowerCase();

    // Sync all calendars with the same name across accounts (e.g. holiday
    // calendars that appear in every connected Google account).
    for (final a in accounts) {
      for (final cal in a.calendars) {
        if (cal.summary.trim().toLowerCase() == summaryKey) {
          cal.isVisible = newVisible;
          unawaited(
            _db.cambiarVisibilidadCalendario(uid, cal.id, a.email, newVisible),
          );
        }
      }
    }

    // Invalidate month cache so dots refresh on the next reload.
    _monthCache.clear();
    notifyListeners();
    unawaited(_reloadEverything());
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
    final cal =
        allCalendars.where((c) => c.id == calendarId).firstOrNull;
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

  /// Actualiza el título y el horario de [event] en Google Calendar.
  ///
  /// Solo permite la edición si el evento pertenece a un calendario propio.
  /// Aplica optimistic update: refleja el cambio en memoria inmediatamente y
  /// revierte si la API falla. Retorna `true` si se actualizó correctamente.
  Future<bool> updateEvent({
    required CalendarEvent event,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!event.isOwned) return false;

    final updatedEvent = CalendarEvent(
      id: event.id,
      calendarId: event.calendarId,
      accountEmail: event.accountEmail,
      title: title,
      location: event.location,
      start: start,
      end: end,
      isAllDay: event.isAllDay,
      isOwned: event.isOwned,
    );

    final previousEvents = List<CalendarEvent>.from(events);
    final previousUpcoming = List<CalendarEvent>.from(upcomingEvents);
    events = events.map((e) => e.id == event.id ? updatedEvent : e).toList();
    upcomingEvents = upcomingEvents
        .map((e) => e.id == event.id ? updatedEvent : e)
        .toList();
    notifyListeners();

    try {
      await _repository.updateEvent(
        accounts: accounts,
        calendarId: event.calendarId,
        eventId: event.id,
        title: title,
        start: start,
        end: end,
      );
      unawaited(
        Future.delayed(const Duration(seconds: 2), () async {
          await _reloadEverything();
          notifyListeners();
        }),
      );
      return true;
    } on CalendarException catch (e) {
      errorMessage = e.message;
      events = previousEvents;
      upcomingEvents = previousUpcoming;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo actualizar el evento.';
      events = previousEvents;
      upcomingEvents = previousUpcoming;
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
      unawaited(
        Future.delayed(const Duration(seconds: 2), () async {
          await _reloadEverything();
          notifyListeners();
        }),
      );
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
