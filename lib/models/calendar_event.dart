import 'package:googleapis/calendar/v3.dart' as gcal;

class CalendarEvent {
  final String id;
  final String calendarId;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final bool isAllDay;
  final bool isOwned;

  const CalendarEvent({
    required this.id,
    required this.calendarId,
    required this.title,
    this.start,
    this.end,
    required this.isAllDay,
    required this.isOwned,
  });

  factory CalendarEvent.fromGoogleEvent(
    gcal.Event e,
    String calendarId,
    bool isOwned,
  ) {
    final isAllDay = e.start?.date != null;
    final start = isAllDay
        ? DateTime.tryParse(e.start!.date.toString())
        : e.start?.dateTime?.toLocal();
    final end = isAllDay
        ? DateTime.tryParse(e.end!.date.toString())
        : e.end?.dateTime?.toLocal();

    return CalendarEvent(
      id: e.id ?? '',
      calendarId: calendarId,
      title: e.summary ?? '(Sin título)',
      start: start,
      end: end,
      isAllDay: isAllDay,
      isOwned: isOwned,
    );
  }

  String get formattedTime {
    if (isAllDay) return 'Todo el día';
    if (start == null) return '';
    final h = start!.hour;
    final m = start!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayH:$m $period';
  }

  String get formattedHour {
    if (isAllDay || start == null) return '--';
    final h = start!.hour;
    final m = start!.minute.toString().padLeft(2, '0');
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayH:$m';
  }

  String get meridian {
    if (isAllDay || start == null) return '';
    return start!.hour >= 12 ? 'PM' : 'AM';
  }
}
