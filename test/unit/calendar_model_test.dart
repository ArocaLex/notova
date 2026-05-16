import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notova/models/calendar_event.dart';
import 'package:notova/models/calendar_info.dart';

void main() {
  // ── CalendarEvent ────────────────────────────────────────────────────────
  group('CalendarEvent getters', () {
    test('formattedTime devuelve hora correcta para AM', () {
      final event = CalendarEvent(
        id: '1',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Meeting',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 9, 30),
      );

      expect(event.formattedTime, '9:30 AM');
      expect(event.meridian, 'AM');
      expect(event.formattedHour, '9:30');
    });

    test('formattedTime devuelve hora correcta para PM', () {
      final event = CalendarEvent(
        id: '2',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Meeting 2',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 14, 15),
      );

      expect(event.formattedTime, '2:15 PM');
      expect(event.meridian, 'PM');
      expect(event.formattedHour, '2:15');
    });

    test('medianoche (0:00) → 12:00 AM', () {
      final event = CalendarEvent(
        id: '3',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Midnight',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 0, 0),
      );

      expect(event.formattedTime, '12:00 AM');
      expect(event.meridian, 'AM');
    });

    test('mediodía (12:00) → 12:00 PM', () {
      final event = CalendarEvent(
        id: '4',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Noon',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 12, 0),
      );

      expect(event.formattedTime, '12:00 PM');
      expect(event.meridian, 'PM');
    });

    test('evento sin hora (start null) → cadena vacía', () {
      final event = CalendarEvent(
        id: '5',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'No time',
        isAllDay: false,
        isOwned: true,
      );

      expect(event.formattedTime, '');
      expect(event.formattedHour, '--');
      expect(event.meridian, '');
    });

    test('evento de todo el día', () {
      final event = CalendarEvent(
        id: '6',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Festivo',
        isAllDay: true,
        isOwned: true,
        start: DateTime(2026, 1, 1),
      );

      expect(event.formattedTime, 'Todo el día');
      expect(event.formattedTimeRange, 'Todo el día');
      expect(event.formattedHour, '--');
      expect(event.meridian, '');
    });

    test('formattedTimeRange con inicio y fin en el mismo meridiano', () {
      final event = CalendarEvent(
        id: '7',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Meeting',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 10, 0),
        end: DateTime(2026, 1, 1, 11, 30),
      );

      expect(event.formattedTimeRange, '10:00 - 11:30 AM');
    });

    test('formattedTimeRange cruzando mediodía', () {
      final event = CalendarEvent(
        id: '8',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Long meeting',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 11, 0),
        end: DateTime(2026, 1, 1, 13, 0),
      );

      expect(event.formattedTimeRange, '11:00 - 1:00 PM');
    });

    test('formattedTimeRange sin end devuelve solo inicio', () {
      final event = CalendarEvent(
        id: '9',
        calendarId: 'cal_1',
        accountEmail: 'test@test.com',
        title: 'Open',
        isAllDay: false,
        isOwned: true,
        start: DateTime(2026, 1, 1, 15, 0),
      );

      expect(event.formattedTimeRange, '3:00 PM');
    });
  });

  // ── CalendarInfo ──────────────────────────────────────────────────────────
  group('CalendarInfo.isOwned / isReadOnly', () {
    CalendarInfo makeCalendar(String role) => CalendarInfo(
          id: 'cal1',
          summary: 'Test Calendar',
          accessRole: role,
          accountEmail: 'user@test.com',
        );

    test('accessRole owner → isOwned true', () {
      expect(makeCalendar('owner').isOwned, isTrue);
    });

    test('accessRole writer → isOwned true', () {
      expect(makeCalendar('writer').isOwned, isTrue);
    });

    test('accessRole reader → isOwned false', () {
      expect(makeCalendar('reader').isOwned, isFalse);
    });

    test('accessRole freeBusyReader → isOwned false', () {
      expect(makeCalendar('freeBusyReader').isOwned, isFalse);
    });

    test('isReadOnly es inverso de isOwned (reader)', () {
      expect(makeCalendar('reader').isReadOnly, isTrue);
      expect(makeCalendar('owner').isReadOnly, isFalse);
    });

    test('isVisible por defecto es true', () {
      expect(makeCalendar('owner').isVisible, isTrue);
    });

    test('isVisible se puede cambiar tras construcción', () {
      final cal = makeCalendar('owner');
      cal.isVisible = false;
      expect(cal.isVisible, isFalse);
    });
  });

  group('CalendarInfo.parsedBackgroundColor', () {
    test('color hex válido #4285F4 → Color correcto', () {
      final cal = CalendarInfo(
        id: 'c', summary: 's', accessRole: 'owner',
        accountEmail: 'a@b.com', backgroundColor: '#4285F4',
      );
      expect(cal.parsedBackgroundColor, const Color(0xFF4285F4));
    });

    test('color hex válido sin # no parseable → null', () {
      final cal = CalendarInfo(
        id: 'c', summary: 's', accessRole: 'owner',
        accountEmail: 'a@b.com', backgroundColor: 'ZZZZZZ',
      );
      expect(cal.parsedBackgroundColor, isNull);
    });

    test('backgroundColor null → null', () {
      final cal = CalendarInfo(
        id: 'c', summary: 's', accessRole: 'owner',
        accountEmail: 'a@b.com',
      );
      expect(cal.parsedBackgroundColor, isNull);
    });

    test('color negro #000000 → Color(0xFF000000)', () {
      final cal = CalendarInfo(
        id: 'c', summary: 's', accessRole: 'owner',
        accountEmail: 'a@b.com', backgroundColor: '#000000',
      );
      expect(cal.parsedBackgroundColor, const Color(0xFF000000));
    });
  });

  // ── CalendarAccount ───────────────────────────────────────────────────────
  group('CalendarAccount.isTokenExpired', () {
    CalendarAccount makeAccount({DateTime? expiry}) => CalendarAccount(
          email: 'user@test.com',
          color: Colors.blue,
          accessToken: 'token_xyz',
          calendars: [],
          tokenExpiry: expiry,
        );

    test('tokenExpiry en el pasado → isTokenExpired true', () {
      final account = makeAccount(
        expiry: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(account.isTokenExpired, isTrue);
    });

    test('tokenExpiry en el futuro → isTokenExpired false', () {
      final account = makeAccount(
        expiry: DateTime.now().add(const Duration(minutes: 30)),
      );
      expect(account.isTokenExpired, isFalse);
    });

    test('tokenExpiry null → isTokenExpired false', () {
      expect(makeAccount().isTokenExpired, isFalse);
    });

    test('tokenRejected por defecto es false', () {
      expect(makeAccount().tokenRejected, isFalse);
    });

    test('tokenRejected se puede activar manualmente', () {
      final account = makeAccount();
      account.tokenRejected = true;
      expect(account.tokenRejected, isTrue);
    });

    test('accessToken se puede reemplazar', () {
      final account = makeAccount();
      account.accessToken = 'new_token';
      expect(account.accessToken, 'new_token');
    });
  });
}
