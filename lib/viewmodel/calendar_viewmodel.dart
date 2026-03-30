import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';
import '../repositories/calendar_repository.dart';

class CalendarViewModel extends ChangeNotifier {
  final CalendarRepository _repository = CalendarRepository();

  // ── State ─────────────────────────────────────────────────────────────────

  DateTime selectedDate = DateTime.now();
  List<CalendarInfo> calendars = [];
  List<CalendarEvent> events = [];
  bool isLoading = false;
  bool isSignedIn = false;
  String? errorMessage;

  String? get connectedEmail => _repository.connectedEmail;

  /// Calendars the user owns (can create/edit/delete events — RF-09).
  List<CalendarInfo> get ownedCalendars =>
      calendars.where((c) => c.isOwned).toList();

  // ── Init ──────────────────────────────────────────────────────────────────

  CalendarViewModel() {
    // No silent sign-in attempt: user must explicitly connect Google Calendar.
    isSignedIn = false;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> connectGoogleCalendar() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    isSignedIn = await _repository.signIn();

    if (isSignedIn) {
      await _loadAll();
    } else {
      errorMessage = 'No se pudo conectar con Google Calendar.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> disconnectGoogleCalendar() async {
    await _repository.signOut();
    isSignedIn = false;
    calendars = [];
    events = [];
    notifyListeners();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    try {
      calendars = await _repository.fetchCalendarList();
      await _loadEventsForDate(selectedDate);
    } catch (e) {
      errorMessage = 'Error al cargar calendarios: $e';
    }
  }

  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      events = await _repository.fetchEventsForDate(calendars, date);
    } catch (e) {
      errorMessage = 'Error al cargar eventos: $e';
    }
  }

  void onDateSelected(DateTime date) {
    selectedDate = date;
    errorMessage = null;
    _loadEventsForDate(date).then((_) => notifyListeners());
  }

  Future<void> refresh() async {
    if (!isSignedIn) return;
    isLoading = true;
    notifyListeners();
    await _loadAll();
    isLoading = false;
    notifyListeners();
  }

  // ── Calendar visibility ───────────────────────────────────────────────────

  void toggleCalendarVisibility(String calendarId) {
    final idx = calendars.indexWhere((c) => c.id == calendarId);
    if (idx == -1) return;
    calendars[idx].isVisible = !calendars[idx].isVisible;
    _loadEventsForDate(selectedDate).then((_) => notifyListeners());
  }

  // ── Events — write (RF-09, only owned calendars) ──────────────────────────

  Future<bool> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final cal = calendars.firstWhere(
      (c) => c.id == calendarId,
      orElse: () => CalendarInfo(id: '', summary: '', accessRole: 'reader'),
    );
    if (!cal.isOwned) return false; // enforce RF-09 / RF-10

    try {
      await _repository.createEvent(
        calendarId: calendarId,
        title: title,
        start: start,
        end: end,
      );
      await _loadEventsForDate(selectedDate);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error al crear el evento: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(CalendarEvent event) async {
    if (!event.isOwned) return false; // enforce RF-10 read-only rule

    try {
      await _repository.deleteEvent(
        calendarId: event.calendarId,
        eventId: event.id,
      );
      await _loadEventsForDate(selectedDate);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error al eliminar el evento: $e';
      notifyListeners();
      return false;
    }
  }
}
