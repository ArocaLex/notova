import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

import '../models/calendar_event.dart';
import '../models/calendar_info.dart';

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
  // v7 uses a singleton instance, shared with AuthRepository.
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  GoogleSignInAccount? _account;

  bool get isSignedIn => _account != null;
  String? get connectedEmail => _account?.email;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  /// Interactive Google sign-in. Requests Calendar scope authorization after.
  Future<bool> signIn() async {
    try {
      await _ensureInitialized();
      _account = await _googleSignIn.authenticate();
      // Ensure the Calendar scope is authorized (may show a consent dialog).
      await _ensureCalendarScope();
      return _account != null;
    } catch (_) {
      _account = null;
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    _account = null;
  }

  /// Ensures the Calendar scope is authorized (may show a consent dialog).
  Future<void> _ensureCalendarScope() async {
    if (_account == null) return;
    await _account!.authorizationClient
        .authorizationForScopes([gcal.CalendarApi.calendarScope]);
  }

  /// Returns a CalendarApi authenticated with a fresh access token.
  Future<gcal.CalendarApi> _api() async {
    if (_account == null) throw Exception('Not signed in to Google Calendar');
    final authorization = await _account!.authorizationClient
        .authorizationForScopes([gcal.CalendarApi.calendarScope]);
    if (authorization == null) throw Exception('Calendar scope not authorized');
    return gcal.CalendarApi(_AuthClient(authorization.accessToken));
  }

  // ── Calendars ─────────────────────────────────────────────────────────────

  /// Returns all calendars in the user's list with their access role.
  ///   'owner' | 'writer' → user can create/edit/delete (RF-09)
  ///   'reader' | 'freeBusyReader' → read-only, e.g. Classroom calendars (RF-10)
  Future<List<CalendarInfo>> fetchCalendarList() async {
    final result = await (await _api()).calendarList.list();
    return (result.items ?? [])
        .map((item) => CalendarInfo(
              id: item.id ?? '',
              summary: item.summary ?? 'Calendar',
              backgroundColor: item.backgroundColor,
              accessRole: item.accessRole ?? 'reader',
            ))
        .toList();
  }

  // ── Events ────────────────────────────────────────────────────────────────

  /// Fetches all events for [date] across visible [calendars].
  Future<List<CalendarEvent>> fetchEventsForDate(
    List<CalendarInfo> calendars,
    DateTime date,
  ) async {
    final api = await _api();
    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));
    final events = <CalendarEvent>[];

    for (final cal in calendars.where((c) => c.isVisible)) {
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
            (e) => CalendarEvent.fromGoogleEvent(e, cal.id, cal.isOwned),
          ),
        );
      } catch (_) {
        // Skip calendars that are inaccessible or error out.
      }
    }

    events.sort((a, b) {
      if (a.start == null) return 1;
      if (b.start == null) return -1;
      return a.start!.compareTo(b.start!);
    });
    return events;
  }

  /// Creates an event. Caller MUST verify [CalendarInfo.isOwned] before calling.
  Future<void> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    await (await _api()).events.insert(
      gcal.Event(
        summary: title,
        start: gcal.EventDateTime(dateTime: start.toUtc()),
        end: gcal.EventDateTime(dateTime: end.toUtc()),
      ),
      calendarId,
    );
  }

  /// Deletes an event. Caller MUST verify [CalendarInfo.isOwned] before calling.
  Future<void> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    await (await _api()).events.delete(calendarId, eventId);
  }
}
