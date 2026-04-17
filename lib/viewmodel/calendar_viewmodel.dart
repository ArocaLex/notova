import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../repositories/calendar_repository.dart';

class CalendarViewModel extends ChangeNotifier {
  final CalendarRepository _repository = CalendarRepository();
  final AppDatabase _db = AppDatabase();

  // ── State ─────────────────────────────────────────────────────────────────

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

  /// Mapa día-del-mes → colores de las cuentas que tienen eventos ese día.
  /// Se usa para pintar los "puntitos" en el grid.
  Map<int, List<Color>> eventDayColors = {};

  bool isLoading = false;
  String? errorMessage;

  CalendarViewModel() {
    _restoreFromLocal();
  }

  bool get isSignedIn => accounts.isNotEmpty;

  /// Todos los calendarios de todas las cuentas (para la UI de filtros).
  List<CalendarInfo> get allCalendars => [
        for (final a in accounts) ...a.calendars,
      ];

  /// Calendars the user owns across all accounts (can create/edit/delete).
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

  Color accountColorFor(String email) {
    for (final a in accounts) {
      if (a.email == email) return a.color;
    }
    return const Color(0xFF7B2CBF);
  }

  // ── Restauración desde SQLite + intento silencioso de auth ────────────────

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

    // Mejor esfuerzo: refrescar token de la cuenta activa de Google.
    unawaited(_silentRestoreToken());
  }

  Future<void> _silentRestoreToken() async {
    try {
      final restored = await _repository.attemptSilentRestore();
      if (restored == null) return;
      final idx = accounts.indexWhere(
          (a) => a.email.toLowerCase() == restored.email.toLowerCase());
      if (idx == -1) return;
      accounts[idx].accessToken = restored.accessToken;
      accounts[idx].tokenExpiry = restored.expiry;
      // Persistimos el token nuevo para próximas sesiones.
      await _persistAccount(accounts[idx]);
      notifyListeners();
    } catch (e) {
      debugPrint('[CalendarVM] silent token restore failed: $e');
    }
  }

  // ── Persistencia ──────────────────────────────────────────────────────────

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

  int _colorIntFromAccount(CalendarAccount a) {
    // Color.value está deprecado en Flutter recientes; usamos toARGB32.
    // ignore: deprecated_member_use
    return a.color.value;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Conecta una cuenta nueva sin borrar las que ya estaban. Si el usuario
  /// cancela el diálogo de Google, muestra un mensaje amigable.
  Future<void> connectGoogleCalendar() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final account = await _repository.connectAccount(
        usedColorIndices: _usedColorIndices,
      );

      // Si el usuario volvió a conectar la misma cuenta, reemplazamos.
      accounts.removeWhere((a) => a.email == account.email);
      accounts.add(account);

      // El repo ya añadió el índice de color al set; recuperamos el último
      // añadido para asociarlo al email (no expone el índice directamente,
      // así que lo deducimos por exclusión: el que hay en _usedColorIndices
      // y aún no está en _accountColorIndex).
      for (final idx in _usedColorIndices) {
        if (!_accountColorIndex.containsValue(idx)) {
          _accountColorIndex[account.email] = idx;
          break;
        }
      }

      await _persistAccount(account);
      await _reloadEverything();
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudo conectar con Google Calendar.';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Desconecta una cuenta concreta. Si no se pasa email, desconecta todas.
  Future<void> disconnectGoogleCalendar({String? email}) async {
    errorMessage = null;
    try {
      if (email == null) {
        await _repository.disconnectAll();
        accounts.clear();
        _usedColorIndices.clear();
        _accountColorIndex.clear();
        await _db.clearAllCalendarAccounts();
      } else {
        accounts.removeWhere((a) => a.email == email);
        final colorIdx = _accountColorIndex.remove(email);
        if (colorIdx != null) _usedColorIndices.remove(colorIdx);
        await _db.deleteCalendarAccount(email);
        // Si ya no quedan cuentas, cerramos sesión de Google completamente.
        if (accounts.isEmpty) {
          await _repository.disconnectAll();
          _usedColorIndices.clear();
          _accountColorIndex.clear();
        }
      }
      events = [];
      eventDayColors = {};
    } catch (_) {
      // Nunca propagamos: el usuario no debe ver excepciones al desconectar.
    }
    notifyListeners();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _reloadEverything() async {
    try {
      events = await _repository.fetchEventsForDate(accounts, selectedDate);
      eventDayColors =
          await _repository.fetchEventDaysForMonth(accounts, focusedMonth);
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudieron cargar los eventos.';
    }
  }

  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      events = await _repository.fetchEventsForDate(accounts, date);
    } on CalendarException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'No se pudieron cargar los eventos.';
    }
  }

  Future<void> _loadEventDaysForMonth(DateTime month) async {
    try {
      eventDayColors =
          await _repository.fetchEventDaysForMonth(accounts, month);
    } catch (_) {
      // Silencioso: los puntitos son un extra visual, no bloquean la UI.
    }
  }

  void onDateSelected(DateTime date) {
    selectedDate = date;
    errorMessage = null;
    _loadEventsForDate(date).then((_) => notifyListeners());
  }

  void onMonthChanged(DateTime newFocus) {
    focusedMonth = newFocus;
    notifyListeners();
    _loadEventDaysForMonth(newFocus).then((_) => notifyListeners());
  }

  Future<void> refresh() async {
    if (!isSignedIn) return;
    isLoading = true;
    notifyListeners();
    // Refrescamos también la lista de calendarios de cada cuenta por si
    // el usuario añadió / quitó calendarios desde Google.
    for (final a in accounts) {
      try {
        final fresh = await _repository.fetchCalendarList(a);
        // Preservamos la visibilidad elegida por el usuario.
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

  // ── Calendar visibility ───────────────────────────────────────────────────

  void toggleCalendarVisibility(String calendarId) {
    for (final a in accounts) {
      final idx = a.calendars.indexWhere((c) => c.id == calendarId);
      if (idx != -1) {
        final cal = a.calendars[idx];
        cal.isVisible = !cal.isVisible;
        // Persistir el cambio puntual (sin reescribir todos).
        unawaited(_db.setCalendarVisibility(
            calendarId, a.email, cal.isVisible));
        break;
      }
    }
    _reloadEverything().then((_) => notifyListeners());
  }

  // ── Events — write (RF-09, only owned calendars) ──────────────────────────

  Future<bool> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final cal = allCalendars.where((c) => c.id == calendarId).firstOrNull;
    if (cal == null || !cal.isOwned) return false;

    try {
      await _repository.createEvent(
        accounts: accounts,
        calendarId: calendarId,
        title: title,
        start: start,
        end: end,
      );
      await _reloadEverything();
      notifyListeners();
      return true;
    } on CalendarException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo crear el evento.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(CalendarEvent event) async {
    if (!event.isOwned) return false;

    try {
      await _repository.deleteEvent(
        accounts: accounts,
        calendarId: event.calendarId,
        eventId: event.id,
      );
      await _reloadEverything();
      notifyListeners();
      return true;
    } on CalendarException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo eliminar el evento.';
      notifyListeners();
      return false;
    }
  }
}
