import 'package:googleapis/calendar/v3.dart' as gcal;

class CalendarEvent {
  final String id;
  final String calendarId;
  final String accountEmail;
  final String title;
  final String? location;
  final DateTime? start;
  final DateTime? end;
  final bool isAllDay;
  final bool isOwned;

  const CalendarEvent({
    required this.id,
    required this.calendarId,
    required this.accountEmail,
    required this.title,
    this.location,
    this.start,
    this.end,
    required this.isAllDay,
    required this.isOwned,
  });

  factory CalendarEvent.fromGoogleEvent(
    gcal.Event e,
    String calendarId,
    String accountEmail,
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
      accountEmail: accountEmail,
      title: e.summary ?? '(Sin título)',
      location: e.location,
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

  /// Rango horario formateado: "10:00 - 11:30 AM"
  String get formattedTimeRange {
    if (isAllDay) return 'Todo el día';
    if (start == null) return '';

    String fmt(DateTime d) {
      final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    String period(DateTime d) => d.hour >= 12 ? 'PM' : 'AM';

    if (end == null) return '${fmt(start!)} ${period(start!)}';
    return '${fmt(start!)} - ${fmt(end!)} ${period(end!)}';
  }
}
